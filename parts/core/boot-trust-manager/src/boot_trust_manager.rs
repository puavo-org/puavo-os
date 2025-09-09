use std::{
    fs,
    path::{Path, PathBuf},
    process::Command,
    time::Duration,
};

use log::{debug, info};
use tempfile::Builder;

use crate::{
    configurators::{Configurator, configurators},
    devices::{
        block_device::{BlockDevice, GenericBlockDevice},
        boot_vault::{BootVault, VAULT_PATH},
        efi_boot_device::EFIBootDevice,
    },
    display::{
        UserDisplay, console::ConsoleDisplay, plymouth::PlymouthDisplay,
    },
    error::PuavoError,
    utils::{
        luks_tpm_token_manager::LuksTpmTokenManager, mount::MountGuard,
        power::reboot_or_halt, udev::filesystem_type,
    },
};

use crate::ApplicationConfiguration;

// How long to wait after showing a message with Plymouth?
const DISPLAY_STOP_DURATION: u64 = 1000;

pub struct BootTrustManager {
    configuration: ApplicationConfiguration,
}

impl BootTrustManager {
    pub fn new(configuration: ApplicationConfiguration) -> Self {
        Self { configuration }
    }

    pub fn manage(&self) -> Result<(), PuavoError> {
        // Run only the first successfully loaded configurator per boot.
        // Each configurator must remove its own trigger file
        // regardless of success to avoid reboot loops.
        // If no configurator is available, exit immediately without rebooting.
        let mut configurators = configurators()?;

        if configurators.is_empty() {
            info!("No configurator activated, exiting...");
            return Ok(());
        }

        let display = Self::build_display(self.configuration.console);
        let _ = display.show_message("Configuring...");

        let configurator = configurators.remove(0);

        let reboot = match Self::configure(&display, configurator) {
            Ok(configured) => configured,
            Err(error) => {
                let _ = display
                    .show_message(&format!("Configuration failed: {}", error));
                true
            }
        };

        if reboot && !self.configuration.no_reboot {
            let _ = display.show_message("Rebooting...");
            reboot_or_halt();
        }

        Ok(())
    }

    fn build_display(use_console: bool) -> Box<dyn UserDisplay> {
        let console_display =
            Box::new(ConsoleDisplay::new()) as Box<dyn UserDisplay>;

        if use_console {
            return console_display;
        }

        PlymouthDisplay::new(Duration::from_millis(DISPLAY_STOP_DURATION))
            .inspect_err(|error| {
                warn!("Failed to initialize Plymouth display: {}", error)
            })
            .map(|plymouth| Box::new(plymouth) as Box<dyn UserDisplay>)
            .unwrap_or(console_display) // Fallback
    }

    fn unlock_boot_vault_and_configure(
        display: &Box<dyn UserDisplay>,
        efi_partition_mount_path: &Path,
        primary_partition_device_path: String,
        mut configurator: Box<dyn Configurator>,
    ) -> Result<(), PuavoError> {
        let boot_vault_image_path = efi_partition_mount_path.join(VAULT_PATH);
        info!("Boot vault image path: {:?}", boot_vault_image_path);

        let mut boot_vault = BootVault::default();
        info!("Mounting boot vault");
        boot_vault.mount(&boot_vault_image_path)?;
        info!("Boot vault mounted");

        let mut primary_partition_manager =
            LuksTpmTokenManager::from_device_path(
                primary_partition_device_path,
            )?;

        info!("Starting primary partition configuration");
        if configurator
            .allowed(&mut boot_vault, &mut primary_partition_manager)?
        {
            info!("Configurator allowed configuration, proceeding");
            configurator.configure(
                &mut boot_vault,
                &mut primary_partition_manager,
                display,
            )?;
            info!("Configuration completed");
            let _ = display.show_message("Configuration completed");
        } else {
            info!("Configurator refused configuration");
            let _ = display.show_message("Configuration refused");
        }

        Ok(())

        // Boot vault is automatically unmounted once dropped
    }

    fn find_configurator_from_loader_extra_directory(
        loader_extra_directory: PathBuf,
        configurator: &Box<dyn Configurator>,
    ) -> Result<PathBuf, PuavoError> {
        let configurator_filename = configurator.filename()?;
        let configurator_path =
            loader_extra_directory.join(configurator_filename);

        configurator_path.try_exists()?;
        Ok(configurator_path)
    }

    fn find_configurator(
        efi_partition_mount_path: &Path,
        configurator: &Box<dyn Configurator>,
    ) -> Result<PathBuf, PuavoError> {
        let loader_path = EFIBootDevice::loader_path(
            &efi_partition_mount_path.to_path_buf(),
        )?;
        info!("EFI loader path: {:?}", loader_path);
        let loader_extra_directory =
            EFIBootDevice::loader_extra_directory_path(&loader_path)?;
        info!("EFI loader extra directory path: {:?}", loader_extra_directory);
        Self::find_configurator_from_loader_extra_directory(
            loader_extra_directory,
            &configurator,
        )
    }

    fn find_and_delete_configurator_file(
        efi_partition_mount_path: &Path,
        configurator: &Box<dyn Configurator>,
    ) -> Result<(), PuavoError> {
        let configurator_path =
            Self::find_configurator(efi_partition_mount_path, configurator)?;
        info!(
            "Disabling configurator by deleting its file: {:?}",
            configurator_path
        );
        fs::remove_file(&configurator_path).map_err(|error| error.into())
    }

    fn configure(
        display: &Box<dyn UserDisplay>,
        configurator: Box<dyn Configurator>,
    ) -> Result<bool, PuavoError> {
        // Ensure the loop kernel module is loaded
        let _ = Command::new("modprobe").arg("loop").status();

        let boot_device = EFIBootDevice::current()?;
        debug!("Located EFI boot device");

        let partitions = boot_device.child_block_devices()?;
        debug!("Found {} child block devices", partitions.len());

        let efi_partition = partitions
            .iter()
            .find(|device| filesystem_type(device) == Some("vfat"))
            .ok_or(PuavoError::NoEFIPartition)?;
        info!("EFI partition found at {:?}", efi_partition.devpath());

        let primary_partition_device = partitions
            .iter()
            .find(|device| filesystem_type(device) == Some("crypto_LUKS"))
            .ok_or(PuavoError::NoPrimaryLuksPartition)?;
        let primary_partition_device_path = primary_partition_device
            .devnode()
            .ok_or(PuavoError::NoPrimaryLuksPartition)?
            .to_string_lossy()
            .to_string();
        info!(
            "Primary LUKS partition detected at {:?}",
            primary_partition_device_path
        );

        // Generate a temporary mountpoint for the EFI partition
        let mut efi_partition_mount_directory =
            Builder::new().prefix("puavo-efi-").tempdir_in("/tmp")?;
        debug!(
            "Created temporary mount directory {:?}",
            efi_partition_mount_directory.path()
        );

        // Disable cleanup as recursive delete in the worst case it could destroy the EFI partition
        efi_partition_mount_directory.disable_cleanup(true);

        let efi_partition_device =
            GenericBlockDevice::new(efi_partition.clone());
        let efi_partition_mount_path = efi_partition_mount_directory.path();
        info!(
            "Mounting EFI partition {:?} to {:?}",
            efi_partition.devpath(),
            efi_partition_mount_path
        );
        efi_partition_device
            .mount(efi_partition_mount_path.to_str().unwrap(), "vfat")?;

        // Unmount the EFI partition automatically at the end of scope
        let _efi_mount_guard = MountGuard::new(efi_partition_mount_path);

        // Delete the configurator file to avoid a reboot loop
        let configurator_path_result = Self::find_and_delete_configurator_file(
            efi_partition_mount_path,
            &configurator,
        );

        if let Err(error) = configurator_path_result {
            let _ = display.show_message(
                format!("Configuration canceled: {}", error).as_str(),
            );
            // We should not reboot as that would lead to a reboot loop.
            // It should be safe to cancel now as we have only mounted EFI.
            return Ok(false);
        }

        Self::unlock_boot_vault_and_configure(
            display,
            efi_partition_mount_path,
            primary_partition_device_path,
            configurator,
        )
        // If any configurator runs, reboot afterward as
        // a safety precaution, because the boot vault was unlocked.
        .map(|_| true)

        // EFI partition is automatically unmounted once dropped
    }
}

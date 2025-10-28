use std::{
    fs,
    path::{Path, PathBuf},
    process::Command,
};

use log::{debug, error, info, warn};
use tempfile::Builder;

use crate::{
    configurators::{Configurator, configurators},
    devices::{
        block_device::{BlockDevice, GenericBlockDevice},
        boot_vault::{BootVault, VAULT_PATH},
        efi_boot_device::EFIBootDevice,
    },
    display::{UserDisplay, choose_display},
    error::PuavoError,
    utils::{
        luks_tpm_token_manager::LuksTpmTokenManager, mount::MountGuard,
        udev::filesystem_type,
    },
};

use crate::ApplicationConfiguration;

/// Coordinates detection of configurators and execution of configurators.
///
/// Responsibilities:
/// - Detect an active configurator.
/// - Safely mount and unmount the EFI partition and boot vault image.
/// - Invoke configurators to manage LUKS TPM tokens.
///
/// Behavior is controlled via `ApplicationConfiguration`.
pub struct BootTrustManager {
    configuration: ApplicationConfiguration,
}

impl BootTrustManager {
    /// Create a new `BootTrustManager` with the specified application configuration.
    pub fn new(configuration: ApplicationConfiguration) -> Self {
        Self { configuration }
    }

    /// Finds active configurators, shows progress on the
    /// selected display (console or Plymouth), executes any activated
    /// configurators sequentially.
    ///
    /// If no configurators are active, this returns immediately.
    pub fn manage(&self) {
        // Process all activated configurators sequentially.
        // If no configurator is available, exit immediately.
        let configurators = match configurators() {
            Ok(configurators) => configurators,
            Err(error) => {
                error!("Failed to load configurators: {}", error);
                return;
            }
        };

        if configurators.is_empty() {
            info!("No configurators found, exiting...");
            return;
        }

        let display = choose_display(self.configuration.force_console);

        let _ = Self::configure(&display, configurators).inspect_err(|error| {
            if matches!(error,
                        PuavoError::NoEFIBootDisk(_)
                          | PuavoError::NoEFIPartition
                          | PuavoError::NoPrimaryLuksPartition) {
                // these conditions are normal and we need not tell user
                warn!("Configuration failed: {} (this error condition is normal on some installation types)", error);
                return;
            }
            error!("Configuration failed: {}", error);
            let _ = display.show_message(&format!("Configuration failed: {}",
                                                  error));
        });
    }

    /// Mount the boot vault and delegate control to the given configurators.
    ///
    /// Parameters:
    /// - `display`: display instance to show progress and messages.
    /// - `efi_partition_mount_path`: mount point of the EFI system partition.
    /// - `primary_partition_device_path`: path to the primary LUKS device (e.g. `/dev/nvme0n1p3`).
    /// - `configurators`: configurator instances to run.
    ///
    /// Errors:
    /// Returns `PuavoError` if the boot vault cannot be mounted, the LUKS TPM
    /// managers cannot be created, or a configurator fails.
    fn unlock_boot_vault_and_configure(
        display: &Box<dyn UserDisplay>,
        efi_partition_mount_path: &Path,
        primary_partition_device_path: String,
        configurators: Vec<Box<dyn Configurator>>,
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

        info!("Starting configuration...");
        for mut configurator in configurators {
            debug!("Processing configurator '{}'", configurator.name());

            if let Some(trigger_filename) = configurator.trigger_filename() {
                if let Err(error) = Self::find_and_delete_configurator_file(
                    efi_partition_mount_path,
                    &trigger_filename,
                ) {
                    error!(
                        "Skipping configurator due to error deleting its trigger file '{}': {}",
                        trigger_filename, error
                    );
                    continue;
                }
            }

            if !configurator
                .activate(&mut boot_vault, &mut primary_partition_manager)?
            {
                debug!("Configurator did not activate");
                continue;
            }

            info!("Configurator activated");
            configurator.configure(
                &mut boot_vault,
                &mut primary_partition_manager,
                display,
            )?;
            info!("Configuration completed");
            let _ = display.show_message("Configuration completed");
        }

        Ok(())

        // Boot vault is automatically unmounted once dropped
    }

    /// Resolve the full path to the configurator file inside the loader's
    /// extra directory and verify its existence.
    ///
    /// Parameters:
    /// - `loader_extra_directory`: path to the loader's extra directory.
    /// - `filename`: configurator file to locate.
    ///
    /// Errors:
    /// Returns `PuavoError` if existence checks fail.
    fn find_configurator_file_from_loader_extra_directory(
        loader_extra_directory: PathBuf,
        filename: &String,
    ) -> Result<PathBuf, PuavoError> {
        let configurator_path = loader_extra_directory.join(filename);

        configurator_path.try_exists()?;
        Ok(configurator_path)
    }

    /// Locate the configurator file on the EFI system partition by resolving
    /// the loader path and its "extra" directory.
    ///
    /// Parameters:
    /// - `efi_partition_mount_path`: mount point of the EFI system partition.
    /// - `filename`: the configurator file to locate.
    ///
    /// Errors:
    /// Returns `PuavoError` if the loader or extra directory cannot be resolved
    /// or the configurator path cannot be found.
    fn find_configurator_file(
        efi_partition_mount_path: &Path,
        filename: &String,
    ) -> Result<PathBuf, PuavoError> {
        let loader_path = EFIBootDevice::loader_path(
            &efi_partition_mount_path.to_path_buf(),
        )?;
        info!("EFI loader path: {:?}", loader_path);
        let loader_extra_directory =
            EFIBootDevice::loader_extra_directory_path(&loader_path)?;
        info!("EFI loader extra directory path: {:?}", loader_extra_directory);
        Self::find_configurator_file_from_loader_extra_directory(
            loader_extra_directory,
            &filename,
        )
    }

    /// Delete the configurator file from the EFI partition.
    ///
    /// Parameters:
    /// - `efi_partition_mount_path`: mount point of the EFI system partition.
    /// - `filename`: the configurator file to delete.
    ///
    /// Errors:
    /// Returns `PuavoError` if the file cannot be located or removed.
    fn find_and_delete_configurator_file(
        efi_partition_mount_path: &Path,
        filename: &String,
    ) -> Result<(), PuavoError> {
        let configurator_file_path =
            Self::find_configurator_file(efi_partition_mount_path, filename)?;
        info!("Removing configurator file: {:?}", configurator_file_path);
        fs::remove_file(&configurator_file_path).map_err(|error| error.into())
    }

    /// Find the current EFI boot device, mount its EFI partition, unlock the
    /// boot vault, and run any activated configurators.
    ///
    /// Behavior:
    /// 1. Find the current EFI boot device and enumerate its partitions.
    /// 2. Identify the booted EFI and primary LUKS partitions.
    /// 3. Mount the EFI partition to a temporary directory.
    /// 4. Locate and remove configurator trigger files.
    /// 5. Unlock the boot vault and run all activated configurators sequentially (see `unlock_boot_vault_and_configure`).
    /// 6. Close the boot vault and unmount the EFI partition.
    ///
    /// Returns:
    /// - `Ok(())` on success.
    /// - `Err(error)` if a failure occurred during mounting, unlocking, or configuration.
    ///
    /// Safety:
    /// The temporary directory's recursive delete is disabled to avoid risking
    /// accidental deletion of the EFI partition. Unmounting is handled by
    /// `MountGuard` on drop.
    fn configure(
        display: &Box<dyn UserDisplay>,
        configurators: Vec<Box<dyn Configurator>>,
    ) -> Result<(), PuavoError> {
        // Ensure the loop kernel module is loaded
        let _ = Command::new("modprobe").arg("loop").status();
        // TODO(udev-settle): We currently wait for udev events to settle to
        // guarantee access to storage block devices. This adds latency to boot.
        // Ideally we should avoid global settles and instead wait only
        // for the boot disk devices. This is related to the helper script
        // puavo-current-efi-boot-disk which also waits for udev.
        let _ =
            Command::new("udevadm").arg("settle").arg("--timeout=30").status();

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

        Self::unlock_boot_vault_and_configure(
            display,
            efi_partition_mount_path,
            primary_partition_device_path,
            configurators,
        )

        // EFI partition is automatically unmounted once dropped
    }
}

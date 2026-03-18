use std::{fs, path::PathBuf, process::Command};

use log::{debug, error, info, warn};

use crate::{
    configurators::{Configurator, configurators},
    devices::{
        block_device::{BlockDevice, GenericBlockDevice},
        boot_vault::{
            BootVault, VAULT_LUKS_DEVICE_NAME, VAULT_MOUNTPOINT, VAULT_PATH,
        },
        efi_boot_device::EFIBootDevice,
    },
    display::{UserDisplay, choose_display},
    error::PuavoError,
    utils::{
        efi,
        luks_tpm_token_manager::LuksTpmTokenManager,
        mount::{MountGuard, unmount},
        tpm,
        udev::filesystem_type,
        unlock_info,
    },
};

/// LUKS device name for the root device
pub const ROOT_DEVICE_NAME: &str = "root";

/// Configuration options for the boot trust manager.
#[derive(Debug, Clone, Default)]
pub struct BootTrustManagerConfiguration {
    /// Use console UI instead of Plymouth
    pub force_console: bool,
}

/// Coordinates detection of configurators and execution of configurators.
///
/// Responsibilities:
/// - Detect an active configurator.
/// - Safely mount and unmount the EFI partition and boot vault image.
/// - Invoke configurators to manage LUKS TPM tokens.
///
/// Behavior is controlled via `BootTrustManagerConfiguration`.
pub struct BootTrustManager {
    configuration: BootTrustManagerConfiguration,
}

impl BootTrustManager {
    /// Create a new `BootTrustManager` with the specified configuration.
    pub fn new(configuration: BootTrustManagerConfiguration) -> Self {
        Self { configuration }
    }

    /// Finds active configurators, shows progress on the
    /// selected display (console or Plymouth), executes any activated
    /// configurators sequentially.
    ///
    /// If no configurators are active, this returns immediately.
    pub fn manage(&self) -> Result<(), PuavoError> {
        // Process all activated configurators sequentially.
        // If no configurator is available, exit immediately.
        let configurators = match configurators() {
            Ok(configurators) => configurators,
            Err(error) => {
                error!("Failed to load configurators: {}", error);
                return Err(error);
            }
        };

        if configurators.is_empty() {
            info!("No configurators found, exiting...");
            return Ok(());
        }

        let display = choose_display(self.configuration.force_console);

        Self::configure(&display, configurators).inspect_err(|error| {
            if matches!(error,
                        PuavoError::NoEFIBootDisk(_)
                          | PuavoError::NoBootVault
                          | PuavoError::NoEFIPartition
                          | PuavoError::NoPrimaryLuksPartition) {
                // these conditions are normal and we need not tell user
                warn!("Configuration failed: {} (this error condition is normal on some installation types)", error);
                return;
            }
            error!("Configuration failed: {}", error);
            let _ = display.show_message(&format!("Configuration failed: {}",
                                                  error));
        })
    }

    /// Run configurators with the specified resources, if Secure Boot is enabled.
    ///
    /// Parameters:
    /// - `display`: display instance to show progress and messages.
    /// - `efi_partition_mount_path`: mount point of the EFI system partition.
    /// - `boot_vault`: mounted boot vault instance.
    /// - `primary_partition_manager`: LUKS TPM token manager for the primary partition.
    /// - `configurators`: configurator instances to run.
    ///
    /// Errors:
    /// Returns `PuavoError` if configurator execution fails.
    fn check_secure_boot_and_run_configurators(
        display: &Box<dyn UserDisplay>,
        boot_vault: BootVault,
        primary_partition_manager: LuksTpmTokenManager,
        configurators: Vec<Box<dyn Configurator>>,
    ) -> Result<(), PuavoError> {
        if !efi::is_secure_boot_enabled() {
            info!("Secure Boot is disabled, skipping configuration...");
            return Ok(());
        }

        Self::run_configurators(
            display,
            boot_vault,
            primary_partition_manager,
            configurators,
        )
    }

    /// Run configurators with the specified resources.
    ///
    /// Parameters:
    /// - `display`: display instance to show progress and messages.
    /// - `efi_partition_mount_path`: mount point of the EFI system partition.
    /// - `boot_vault`: mounted boot vault instance.
    /// - `primary_partition_manager`: LUKS TPM token manager for the primary partition.
    /// - `configurators`: configurator instances to run.
    ///
    /// Errors:
    /// Returns `PuavoError` if configurator execution fails.
    pub fn run_configurators(
        display: &Box<dyn UserDisplay>,
        mut boot_vault: BootVault,
        mut primary_partition_manager: LuksTpmTokenManager,
        configurators: Vec<Box<dyn Configurator>>,
    ) -> Result<(), PuavoError> {
        info!("Starting configuration...");
        for mut configurator in configurators {
            debug!("Processing configurator '{}'", configurator.name());

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
            let _ = display.clear();
        }

        // Clear TPM dictionary attack lockout if we have the auth file.
        // This resets the lockout counter after configuration completes,
        // which is helpful if the device was unlocked with a recovery key
        // due to TPM lockout from failed PIN attempts.
        let lockout_auth_path = boot_vault.resources().tpm_lockout_auth_path();
        if let Err(error) = tpm::clear_dictionary_lockout(&lockout_auth_path) {
            warn!("Failed to clear TPM dictionary lockout: {}", error);
        }

        Ok(())

        // Boot vault is automatically unmounted once dropped
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
        let (efi_mount, primary_device_path) = Self::setup(None)?;

        Self::configure_with_paths(
            display,
            configurators,
            &efi_mount.mountpoint.join(VAULT_PATH),
            primary_device_path,
            Some(&efi_mount.mountpoint),
        )

        // EFI partition is automatically unmounted here
    }

    /// Configure the boot trust manager using explicitly specified paths.
    ///
    /// Parameters:
    /// - `display`: Display instance to show progress and messages.
    /// - `configurators`: Configurator instances to run.
    /// - `boot_vault_image_path`: Path to the boot vault LUKS image file.
    /// - `primary_device_path`: Path to the primary LUKS partition device.
    /// - `efi_mountpoint`: Optional EFI partition mount point for saving unlock info.
    ///
    /// Returns:
    /// - `Ok(())` on success.
    /// - `Err(error)` if configuration fails.
    pub fn configure_with_paths(
        display: &Box<dyn UserDisplay>,
        configurators: Vec<Box<dyn Configurator>>,
        boot_vault_image_path: &PathBuf,
        primary_device_path: String,
        efi_mountpoint: Option<&PathBuf>,
    ) -> Result<(), PuavoError> {
        info!("Boot vault image path: {:?}", boot_vault_image_path);

        let mut boot_vault = BootVault::default();
        info!("Mounting boot vault");
        boot_vault.mount(boot_vault_image_path, display)?;
        info!("Boot vault mounted");

        // Check unlock restrictions before unlocking the primary partition.
        boot_vault.resources().check_unlock_restrictions()?;

        let mut primary_partition_manager =
            LuksTpmTokenManager::from_device_path(primary_device_path)?;

        boot_vault.activate(
            primary_partition_manager.device_mut(),
            ROOT_DEVICE_NAME,
        )?;

        // Save unlock info after successful unlock. If a future unlock fails,
        // this info can be compared to identify what changed in the boot chain.
        if let Some(efi_path) = efi_mountpoint {
            unlock_info::save_to_efi(efi_path);
        }

        // Use the resources for configuration
        Self::check_secure_boot_and_run_configurators(
            display,
            boot_vault,
            primary_partition_manager,
            configurators,
        )
    }

    /// Shared setup logic for both manage and open operations.
    ///
    /// This method handles:
    /// 1. Loading kernel modules and settling udev
    /// 2. Finding the EFI boot device and partitions
    /// 3. Mounting the EFI partition
    ///
    /// Parameters:
    /// - `device`: Optional device node path containing the EFI partition with boot vault and primary encrypted partition
    ///
    /// Returns:
    /// A tuple containing:
    /// - `MountGuard`: Guard for the mounted EFI partition that will unmount on drop.
    /// - `String`: Path to the primary LUKS partition device.
    ///
    /// Errors:
    /// Returns `PuavoError` if any setup step fails.
    fn setup(
        device: Option<String>,
    ) -> Result<(MountGuard, String), PuavoError> {
        // Ensure the loop kernel module is loaded
        let _ = Command::new("modprobe").arg("loop").status();
        // TODO(udev-settle): We currently wait for udev events to settle to
        // guarantee access to storage block devices. This adds latency to boot.
        // Ideally we should avoid global settles and instead wait only
        // for the boot disk devices. This is related to the helper script
        // puavo-current-efi-boot-disk which also waits for udev.
        let _ =
            Command::new("udevadm").arg("settle").arg("--timeout=30").status();

        let boot_device = device
            .map(EFIBootDevice::from_device_node_path)
            .unwrap_or_else(EFIBootDevice::current)?;

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

        let efi_partition_mount_path = PathBuf::from("/boot/efi");
        fs::create_dir_all(efi_partition_mount_path.as_path())?;

        let efi_partition_device =
            GenericBlockDevice::new(efi_partition.clone());
        info!(
            "Mounting EFI partition {:?} to {:?}",
            efi_partition.devpath(),
            efi_partition_mount_path
        );
        efi_partition_device
            .mount(efi_partition_mount_path.to_str().unwrap(), "vfat")?;

        // Create mount guard that will unmount the EFI partition automatically at the end of scope
        let efi_mount_guard = MountGuard::new(efi_partition_mount_path.clone());
        Ok((efi_mount_guard, primary_partition_device_path))
    }

    /// Attempts to open the boot vault and leave it available for external access
    ///
    /// Parameters:
    /// - `device`: Optional device node path containing the EFI partition with boot vault and primary encrypted partition
    ///
    /// Returns:
    /// The mount path of the opened boot vault on success.
    pub fn try_open(
        &self,
        device: Option<String>,
    ) -> Result<String, PuavoError> {
        if BootVault::is_mounted(VAULT_MOUNTPOINT).unwrap_or(false) {
            return Err(PuavoError::BootVaultOpen);
        }

        let (efi_mount, _) = Self::setup(device)?;

        // Setup boot vault using the EFI partition mount
        let boot_vault_image_path = efi_mount.mountpoint.join(VAULT_PATH);
        info!("Boot vault image path: {:?}", boot_vault_image_path);

        let mut boot_vault = BootVault::default();
        info!("Mounting boot vault");

        let display = choose_display(self.configuration.force_console);
        boot_vault.mount(&boot_vault_image_path, &display)?;

        info!("Boot vault mounted at {}", VAULT_MOUNTPOINT);

        // Prevent automatic cleanup by forgetting the resources
        std::mem::forget(efi_mount);
        std::mem::forget(boot_vault);

        Ok(VAULT_MOUNTPOINT.into())
    }

    /// Open the boot vault and print its mount path
    pub fn open(&self, device: Option<String>) -> Result<(), PuavoError> {
        self.try_open(device)
            .map(|mount_path| {
                println!("{}", mount_path);
            })
            .inspect_err(|error| {
                error!("Failed to open boot vault: {}", error);
                println!("Failed to open boot vault: {}", error);
            })
    }

    /// Attempts to close and clean up the boot vault that was previously opened
    pub fn try_close(
        &self,
        vault_mount_path: String,
    ) -> Result<(), PuavoError> {
        info!("Closing boot vault at mount path: {}", vault_mount_path);

        if !BootVault::is_mounted(&vault_mount_path).unwrap_or(false) {
            return Err(PuavoError::BootVaultNotMounted(vault_mount_path));
        }

        // Unmount the boot vault
        unmount(&PathBuf::from(&vault_mount_path))?;

        // Unmount the LUKS device
        LuksTpmTokenManager::from_name(VAULT_LUKS_DEVICE_NAME)?
            .unmount(VAULT_LUKS_DEVICE_NAME)?;

        // Automatically detach all unused loop devices
        let _ = Command::new("losetup").arg("--detach-all").status();

        // Unmount the EFI partition
        let efi_mount_path = PathBuf::from("/boot/efi");
        unmount(&efi_mount_path)?;

        info!("Boot vault closed successfully");
        Ok(())
    }

    /// Close the boot vault and display errors if any occur
    pub fn close(&self, vault_mount_path: String) -> Result<(), PuavoError> {
        self.try_close(vault_mount_path).inspect_err(|error| {
            error!("Failed to close boot vault: {}", error);
            println!("Failed to close boot vault: {}", error);
        })
    }
}

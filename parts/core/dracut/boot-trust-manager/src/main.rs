use std::path::Path;

use log::{debug, info, warn};
use tempfile::Builder;
use udev::Device;

use crate::{
    configurators::{Configurator, configurators},
    devices::{
        block_device::{BlockDevice, GenericBlockDevice},
        boot_vault::{BootVault, VAULT_PATH},
        efi_boot_device::EFIBootDevice,
    },
    error::PuavoError,
    utils::{luks_tpm_token_manager::LuksTpmTokenManager, mount::MountGuard},
};

mod configurators;
mod devices;
mod error;
mod utils;

fn unlock_boot_vault_and_configure(
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

    if let Err(error) = boot_vault.write_recovery_key("1234".into()) {
        warn!("Failed to write recovery key: {}", error);
    } else {
        info!("Recovery key written");
    }

    let mut primary_partition_manager =
        LuksTpmTokenManager::from_device_path(primary_partition_device_path)?;

    info!("Starting primary partition configuration");
    if configurator.allowed(&mut boot_vault, &mut primary_partition_manager)? {
        info!("Configurator allowed configuration, proceeding");
        configurator
            .configure(&mut boot_vault, &mut primary_partition_manager)?;
        info!("Configuration completed");
    } else {
        info!("Configurator refused configuration");
    }

    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let _ = env_logger::Builder::from_env(
        env_logger::Env::default().default_filter_or("info"),
    )
    .format_timestamp_secs()
    .try_init();

    // Run only the first successfully loaded configurator per boot.
    // Each configurator must remove its own trigger file
    // regardless of success to avoid reboot loops.
    // If any configurator runs, reboot afterward as
    // a safety precaution, because the boot vault is unlocked.
    // If no configurator is available, exit immediately without rebooting.
    let mut configurators = configurators()?;

    if configurators.is_empty() {
        info!("No configurator activated, exiting...");
        return Ok(());
    }

    let configurator = configurators.remove(0);

    let boot_device = EFIBootDevice::current()?;
    debug!("Located EFI boot device");

    let partitions = boot_device.child_block_devices()?;
    debug!("Found {} child block devices", partitions.len());

    fn filesystem_type(device: &Device) -> Option<&str> {
        device
            .property_value("ID_FS_TYPE")
            .map(|property| property.to_str())
            .flatten()
    }

    let efi_partition = partitions
        .iter()
        .find(|device| filesystem_type(device) == Some("vfat"))
        .ok_or("Failed to find EFI partition on boot device")?;
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

    let efi_partition_device = GenericBlockDevice::new(efi_partition.clone());
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

    unlock_boot_vault_and_configure(
        efi_partition_mount_path,
        primary_partition_device_path,
        configurator,
    )?;

    Ok(())

    // Boot vault is automatically unmounted once dropped
}

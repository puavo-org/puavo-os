use std::{
    fs::{self, File, OpenOptions},
    io,
    os::unix::fs::{OpenOptionsExt, PermissionsExt},
    path::Path,
    process::Command,
};

use log::{error, info};

use crate::{
    configurators::Configurator,
    devices::boot_vault::{BootVault, BootVaultResources},
    display::UserDisplay,
    error::PuavoError,
    luks::tokens::LuksTpmTokenManager,
};

/// Userspace location for the device-specific Secure Boot certificate.
pub const DEVICE_SECURE_BOOT_KEYS_DIRECTORY: &str =
    "/run/puavo/secure-boot-keys";

const CERTIFICATE_FILENAME: &str = "secure-boot.pem";

/// Loads the device key into the TPM and defines the signing counter.
const LOAD_SCRIPT: &str = "/usr/lib/puavo-core/puavo-command-line-manager-load";

/// Copies the device Secure Boot certificate from the open boot vault
/// into the destination directory.
pub fn install_keys(
    resources: &BootVaultResources,
    destination_directory: &Path,
) -> io::Result<()> {
    fs::create_dir_all(destination_directory)?;
    fs::set_permissions(
        destination_directory,
        fs::Permissions::from_mode(0o700),
    )?;

    install_file(
        &resources.secure_boot_certificate_path(),
        &destination_directory.join(CERTIFICATE_FILENAME),
        0o644,
    )?;

    Ok(())
}

/// Copy a single file from `source` to `destination`, creating the
/// destination with the specified mode at open time. Any pre-existing
/// destination is removed first so the mode is always re-applied on
/// re-runs.
fn install_file(
    source: &Path,
    destination: &Path,
    mode: u32,
) -> io::Result<()> {
    match fs::remove_file(destination) {
        Ok(()) => {}
        Err(error) if error.kind() == io::ErrorKind::NotFound => {}
        Err(error) => return Err(error),
    }

    let mut source_file = File::open(source)?;
    let mut destination_file = OpenOptions::new()
        .write(true)
        .create_new(true)
        .mode(mode)
        .open(destination)?;

    io::copy(&mut source_file, &mut destination_file)?;
    Ok(())
}

/// Configurator that publishes the device-specific Secure Boot
/// certificate to userspace, and loads the private key into the TPM, so
/// userspace can sign only what the server authorizes.
pub struct DeviceSecureBootKeysConfigurator;

impl DeviceSecureBootKeysConfigurator {
    pub fn new() -> Result<Vec<Self>, PuavoError> {
        Ok(vec![Self])
    }
}

impl Configurator for DeviceSecureBootKeysConfigurator {
    fn activate(
        &self,
        _boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        Ok(true)
    }

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
        _display: &dyn UserDisplay,
    ) -> Result<(), PuavoError> {
        info!(
            "Installing the device-specific Secure Boot certificate for userspace"
        );
        let destination = Path::new(DEVICE_SECURE_BOOT_KEYS_DIRECTORY);
        install_keys(boot_vault.resources(), destination)
            .map_err(PuavoError::DeviceSecureBootKeyInstallation)?;

        // Loading the key is not critical, so the boot continues
        // regardless of the outcome.
        let key_directory = boot_vault.resources().mountpoint();
        match Command::new(LOAD_SCRIPT).arg(key_directory).output() {
            Ok(output) if output.status.success() => {}
            Ok(output) => error!(
                "Failed to load the device Secure Boot key ({}): {}",
                output.status,
                String::from_utf8_lossy(&output.stderr).trim()
            ),
            Err(error) => {
                error!("Failed to run {LOAD_SCRIPT}: {error}");
            }
        }
        Ok(())
    }

    fn name(&self) -> &'static str {
        "DeviceSecureBootKeys"
    }
}

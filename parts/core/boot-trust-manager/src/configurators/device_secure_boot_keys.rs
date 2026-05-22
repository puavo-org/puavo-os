use std::{
    fs::{self, File, OpenOptions},
    io,
    os::unix::fs::{OpenOptionsExt, PermissionsExt},
    path::Path,
};

use log::info;

use crate::{
    configurators::Configurator,
    devices::boot_vault::{BootVault, BootVaultResources},
    display::UserDisplay,
    error::PuavoError,
    utils::luks_tpm_token_manager::LuksTpmTokenManager,
};

/// Userspace location for the device-specific Secure Boot key and
/// certificate. `/run` is a tmpfs that systemd preserves across
/// `switch_root`, so a userspace signer can read the keys regardless
/// of disk encryption.
pub const DEVICE_SECURE_BOOT_KEYS_DIRECTORY: &str =
    "/run/puavo/secure-boot-keys";

const PRIVATE_KEY_FILENAME: &str = "secure-boot.priv";
const CERTIFICATE_FILENAME: &str = "secure-boot.pem";

/// Copy the device-specific Secure Boot private key and certificate
/// from the open boot vault into the specified destination directory,
/// enforcing `0700` on the directory, `0600` on the private key, and
/// `0644` on the certificate. Each destination file is created with
/// its target mode so the data is never visible under a more
/// permissive mode.
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
        &resources.secure_boot_private_key_path(),
        &destination_directory.join(PRIVATE_KEY_FILENAME),
        0o600,
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

/// Configurator that publishes the device-specific Secure Boot keys
/// from the boot vault into `/run/puavo/secure-boot-keys/` so
/// userspace signers can read them without unsealing the vault.
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
        _display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        info!("Installing device-specific Secure Boot keys for userspace");
        install_keys(
            boot_vault.resources(),
            Path::new(DEVICE_SECURE_BOOT_KEYS_DIRECTORY),
        )
        .map_err(PuavoError::DeviceSecureBootKeyInstallation)
    }

    fn name(&self) -> &'static str {
        "DeviceSecureBootKeys"
    }
}

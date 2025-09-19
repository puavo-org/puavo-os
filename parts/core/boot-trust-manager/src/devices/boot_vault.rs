use std::{
    fs, io,
    path::{Path, PathBuf},
};

use libcryptsetup_rs::{
    CryptDevice, CryptInit,
    consts::{
        flags::{CryptActivate, CryptDeactivate},
        vals::EncryptionFormat,
    },
};
use log::{debug, info, warn};
use loopdev::{LoopControl, LoopDevice};

use crate::{
    devices::block_device::{BlockDevice, GenericBlockDevice},
    error::PuavoError,
    utils::{
        luks_tpm_token_manager::LuksTpmTokenManager, mount::unmount,
        udev::device_from_device_node_path,
    },
};

/// Relative path (within the EFI partition) to the boot vault image.
pub const VAULT_PATH: &str = "EFI/puavo/vault.img";

/// Device-mapper name used when activating the vault's LUKS device.
/// This is the logical name visible under `/dev/mapper/` once the LUKS device
/// is opened, see `VAULT_LUKS_DEVICE_PATH`.
pub const VAULT_LUKS_DEVICE_NAME: &str = "puavo-boot-vault";

/// Absolute path to the activated LUKS device for the vault.
/// Created by cryptsetup when the vault is unlocked. This block device is then
/// mounted to `VAULT_MOUNTPOINT`.
pub const VAULT_LUKS_DEVICE_PATH: &str = "/dev/mapper/puavo-boot-vault";

/// Mount point for the decrypted vault filesystem at runtime.
pub const VAULT_MOUNTPOINT: &str = "/run/puavo/boot-vault";

/// Filesystem type expected inside the vault image.
pub const VAULT_FILESYSTEM_TYPE: &str = "ext4";

/// Path to the recovery key file within the mounted vault.
pub const VAULT_RECOVERY_KEY: &str = "recovery.key";

/// Optional path on the root filesystem to a fallback passphrase for the vault.
/// When present, this passphrase is tried before TPM token unlock to allow recovery.
pub const VAULT_FALLBACK_UNLOCK_KEY_PATH: &str =
    "/.extra/puavo/vault-unlock.key";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BootVaultUnlockMethod {
    TpmToken,
    RecoveryKey,
}

/// Manages the lifecycle of the boot vault.
///
/// Responsibilities:
/// - Attach the vault image as a loop device.
/// - Open the embedded LUKS2 container using TPM token or fallback key.
/// - Mount the decrypted filesystem and provide helpers to read/write data.
/// - Cleanly unmount, deactivate, and detach on demand or on drop.
#[derive(Default)]
pub struct BootVault {
    loop_device: Option<LoopDevice>,
    luks_device: Option<LuksTpmTokenManager>,
    mountpoint: Option<String>,
    resources: Option<BootVaultResources>,
    unlock_method: Option<BootVaultUnlockMethod>,
}

impl BootVault {
    /// Return the method used to unlock the vault after a successful mount, if any.
    pub fn unlock_method(&self) -> Option<BootVaultUnlockMethod> {
        self.unlock_method
    }

    /// Attempt to unlock the LUKS device using a fallback recovery key.
    ///
    /// Parameters:
    /// - `device`: The crypt device handle to activate.
    ///
    /// Returns:
    /// - `Ok(true)` if unlocked using the fallback key.
    /// - `Ok(false)` if no fallback key was available.
    /// - `Err(error)` if an error occurred during unlocking.
    fn try_unlock_with_fallback_key(
        &mut self,
        device: &mut CryptDevice,
    ) -> Result<bool, PuavoError> {
        // If the fallback key is not provided, we can not open this way
        if !fs::exists(VAULT_FALLBACK_UNLOCK_KEY_PATH)? {
            debug!(
                "No fallback key found at {}, cannot unlock using it",
                VAULT_FALLBACK_UNLOCK_KEY_PATH
            );
            return Ok(false);
        }

        // Load the fallback key and try to unlock using it
        debug!(
            "Attempting to unlock boot vault using recovery key at {}",
            VAULT_FALLBACK_UNLOCK_KEY_PATH
        );
        let fallback_key = fs::read_to_string(VAULT_FALLBACK_UNLOCK_KEY_PATH)?;
        device.activate_handle().activate_by_passphrase(
            Some(VAULT_LUKS_DEVICE_NAME),
            None,
            fallback_key.as_bytes(),
            CryptActivate::empty(),
        )?;

        info!(
            "Boot vault unlocked using recovery key at {}",
            VAULT_FALLBACK_UNLOCK_KEY_PATH
        );
        self.unlock_method = Some(BootVaultUnlockMethod::RecoveryKey);
        Ok(true)
    }

    /// Attempt to unlock the LUKS device using any available TPM token.
    ///
    /// Parameters:
    /// - `device`: The crypt device handle to activate.
    ///
    /// Errors:
    /// Propagates cryptsetup and IO errors.
    fn try_unlock_with_any_token(
        &mut self,
        device: &mut CryptDevice,
    ) -> Result<(), PuavoError> {
        debug!("Attempting to unlock boot vault using any available TPM token");

        device.token_handle().activate_by_token::<()>(
            Some(VAULT_LUKS_DEVICE_NAME),
            None,
            None,
            CryptActivate::empty(),
        )?;

        debug!("LUKS device activated as {}", VAULT_LUKS_DEVICE_NAME);
        self.unlock_method = Some(BootVaultUnlockMethod::TpmToken);
        Ok(())
    }

    /// Initialize the LUKS device handle for the loop device and unlock it.
    ///
    /// Parameters:
    /// - `loop_device_path`: Path to the loop device backing the vault image (e.g. `/dev/loop0`).
    ///
    /// Errors:
    /// Propagates loop device control errors.
    fn open_luks_device(
        &mut self,
        loop_device_path: &PathBuf,
    ) -> Result<CryptDevice, PuavoError> {
        debug!("Initializing LUKS device for loop path {:?}", loop_device_path);
        let mut device = CryptInit::init(&loop_device_path)?;

        debug!("Loading LUKS device from {}", loop_device_path.display());
        device
            .context_handle()
            .load::<()>(Some(EncryptionFormat::Luks2), None)?;

        // Attempt to unlock with fallback key first if available,
        // because fallback key grants full access (e.g. recovery).
        let unlock_result = self.try_unlock_with_fallback_key(&mut device);

        match unlock_result {
            Ok(true) => return Ok(device), // Unlocked with fallback key
            Ok(false) => {}
            Err(error) => {
                warn!("Failed to unlock using fallback key: {}", error)
            }
        };

        debug!("No fallback key available, trying TPM token unlock");
        self.try_unlock_with_any_token(&mut device)?;

        Ok(device)
    }

    /// Mount the decrypted LUKS device to the vault mountpoint.
    ///
    /// Errors:
    /// Propagates IO and mount errors.
    fn mount_luks_device(&mut self) -> io::Result<()> {
        let luks_device = device_from_device_node_path(VAULT_LUKS_DEVICE_PATH)?;

        // Create the mount directory for the LUKS device
        fs::create_dir_all(VAULT_MOUNTPOINT)?;

        debug!(
            "Mounting LUKS device {:?} at {} as {}",
            VAULT_LUKS_DEVICE_PATH, VAULT_MOUNTPOINT, VAULT_FILESYSTEM_TYPE
        );
        GenericBlockDevice::new(luks_device)
            .mount(VAULT_MOUNTPOINT, VAULT_FILESYSTEM_TYPE)?;

        self.mountpoint = Some(VAULT_MOUNTPOINT.into());
        self.resources = Some(BootVaultResources::new(VAULT_MOUNTPOINT));
        Ok(())
    }

    /// Mount the boot vault image by attaching it to a loop device, unlocking
    /// its LUKS container, and mounting the resulting device.
    ///
    /// Parameters:
    /// - `image_path`: Path to the boot vault image file on the EFI partition.
    ///
    /// Errors:
    /// - Loop device control errors.
    /// - Cryptsetup errors while unlocking the LUKS container.
    /// - IO or mount errors while mounting the filesystem.
    pub fn mount(&mut self, image_path: &PathBuf) -> Result<(), PuavoError> {
        info!(
            "Setting up loop device for boot vault image at {:?}",
            image_path
        );
        let loop_control = LoopControl::open()?;
        let loop_device = loop_control.next_free()?;

        // TODO: Use a guard object for detaching automatically to simplify error handling

        loop_device.attach_file(image_path)?;
        debug!("Attached image to loop device: {:?}", loop_device.path());

        let loop_device_path = loop_device
            .path()
            .ok_or_else(|| PuavoError::NotFound("Loop device".into()))?;

        let luks_device =
            self.open_luks_device(&loop_device_path).map_err(|error| {
                let _ = loop_device.detach();
                error
            })?;

        debug!("LUKS device activated as {}", VAULT_LUKS_DEVICE_NAME);

        self.mount_luks_device().map_err(|error| {
            let _ = loop_device.detach();
            error
        })?;

        let luks_device_manager = LuksTpmTokenManager::new(
            luks_device,
            loop_device_path.to_string_lossy().to_string(),
        );

        self.loop_device = Some(loop_device);
        self.luks_device = Some(luks_device_manager);
        info!("Boot vault mounted at {}", VAULT_MOUNTPOINT);

        Ok(())
    }

    /// Unmount and tear down the vault, closing the LUKS device and detaching
    /// the loop device.
    pub fn unmount(&mut self) -> Result<(), PuavoError> {
        // If any of the steps fails, the rest will likely also fail,
        // but we have to try and we will reboot anyway.

        // Unmount the LUKS device
        if let Some(mountpoint) = self.mountpoint.take() {
            if let Err(error) = unmount(&Path::new(&mountpoint).to_path_buf()) {
                warn!("Failed to unmount {}: {}", mountpoint, error);
            }

            if let Err(error) = fs::remove_dir(&mountpoint) {
                warn!("Failed to remove mountpoint {}: {}", mountpoint, error);
            }
        }

        // Close the LUKS device now that it is unmounted
        self.luks_device.take().map(|mut luks_device| {
            debug!("Closing LUKS device: {}", VAULT_LUKS_DEVICE_NAME);
            let _ = luks_device
                .device_mut()
                .activate_handle()
                .deactivate(VAULT_LUKS_DEVICE_NAME, CryptDeactivate::empty());
        });

        // Detach the loop device from which the LUKS device was opened
        if let Some(loop_device) = self.loop_device.take() {
            debug!("Detaching loop device: {:?}", loop_device.path());
            let _ = loop_device.detach();
        }

        Ok(())
    }

    /// Returns a reference to the resources for interacting with the mounted vault.
    pub fn resources(&self) -> &BootVaultResources {
        self.resources.as_ref().expect(
            "Attempted to use boot vault resources when it was not mounted",
        )
    }

    /// Returns an immutable reference to the LUKS token manager for the vault.
    pub fn device(&self) -> &LuksTpmTokenManager {
        self.luks_device.as_ref().expect(
            "Attempted to use boot vault device when it was not mounted",
        )
    }

    /// Returns a mutable reference to the LUKS token manager for the vault.
    pub fn device_mut(&mut self) -> &mut LuksTpmTokenManager {
        self.luks_device.as_mut().expect(
            "Attempted to use boot vault device when it was not mounted",
        )
    }
}

/// Provides access to readable and writable properties within the boot vault.
#[derive(Clone)]
pub struct BootVaultResources {
    mountpoint: PathBuf,
}

impl BootVaultResources {
    /// Construct resource helper for the vault mounted at the specified path.
    pub fn new<T: AsRef<Path>>(mountpoint: T) -> Self {
        Self {
            mountpoint: mountpoint.as_ref().to_path_buf()
        }
    }

    /// Write a property with the specified value into the mounted vault.
    ///
    /// Parameters:
    /// - `key`: The name of the property to write.
    /// - `value`: The value to write.
    ///
    /// Errors:
    /// - `PuavoError::VaultNotMounted` if the vault is not mounted.
    /// - `PuavoError::IoError` if writing fails.
    pub fn write_property(
        &self,
        key: &str,
        value: String,
    ) -> Result<(), PuavoError> {
        debug!("Writing property '{}' to boot vault", key);

        let property_path = self.mountpoint.join(key);

        fs::write(property_path, value)
            .map_err(|error| PuavoError::IoError(error))
    }

    /// Read the specified property from the mounted vault.
    ///
    /// Parameters:
    /// - `key`: The name of the property to read.
    ///
    /// Errors:
    /// - `PuavoError::VaultNotMounted` if the vault is not mounted.
    /// - `PuavoError::IoError` if reading fails.
    pub fn read_property(
        &self,
        key: &str,
    ) -> Result<Option<String>, PuavoError> {
        debug!("Reading property '{}' from boot vault", key);

        let property_path = self.mountpoint.join(key);

        match fs::read_to_string(property_path) {
            Ok(value) => Ok(Some(value)),
            Err(error) => {
                if error.kind() == io::ErrorKind::NotFound {
                    return Ok(None);
                } else {
                    Err(error.into())
                }
            }
        }
    }

    /// Set whether a PIN code is required unlock.
    ///
    /// Parameters:
    /// - `required`: Whether a PIN code is required.
    ///
    /// Errors:
    /// - `PuavoError::VaultNotMounted` if the vault is not mounted.
    /// - `PuavoError::IoError` if writing fails.
    pub fn set_pin_required(&self, required: bool) -> Result<(), PuavoError> {
        let value = if required { "1" } else { "0" }.to_string();
        self.write_property("pin-required", value)
    }

    /// Check whether a PIN code is required to unlock.
    ///
    /// Errors:
    /// - `PuavoError::VaultNotMounted` if the vault is not mounted.
    /// - `PuavoError::IoError` if reading fails.
    /// - `PuavoError::InvalidData` if the read value is not valid.
    pub fn is_pin_required(&self) -> Result<bool, PuavoError> {
        let value = self.read_property("pin-required")?.unwrap_or("0".into());
        match value.trim() {
            "1" => Ok(true),
            "0" => Ok(false),
            other => Err(PuavoError::InvalidData(format!(
                "Invalid PIN-required value: {}",
                other
            ))),
        }
    }

    /// Write a recovery key file into the mounted vault.
    ///
    /// Parameters:
    /// - `recovery_key`: The key material to write.
    ///
    /// Errors:
    /// - `PuavoError::VaultNotMounted` if the vault is not mounted.
    /// - `PuavoError::IoError` if writing fails.
    pub fn write_recovery_key(
        &self,
        recovery_key: String,
    ) -> Result<(), PuavoError> {
        self.write_property(VAULT_RECOVERY_KEY, recovery_key)
    }

    /// Read the recovery key from the mounted vault.
    ///
    /// Errors:
    /// - `PuavoError::VaultNotMounted` if the vault is not mounted.
    /// - `PuavoError::IoError` if reading fails.
    pub fn read_recovery_key(&self) -> Result<String, PuavoError> {
        self.read_property(VAULT_RECOVERY_KEY)?.ok_or(PuavoError::NoRecoveryKey)
    }

    /// Set the version of the boot vault image format.
    ///
    /// Parameters:
    /// - `version`: The version string to write.
    ///     
    /// Errors:
    /// - `PuavoError::VaultNotMounted` if the vault is not mounted.
    /// - `PuavoError::IoError` if writing fails.
    pub fn set_version(&self, version: usize) -> Result<(), PuavoError> {
        self.write_property("version", version.to_string())
    }

    /// Get the version of the boot vault image format.
    ///
    /// Errors:
    /// - `PuavoError::VaultNotMounted` if the vault is not mounted.
    /// - `PuavoError::IoError` if reading fails.
    /// - `PuavoError::ParseIntError` if the version string is not a valid integer.
    pub fn get_version(&self) -> Result<usize, PuavoError> {
        let version_string =
            self.read_property("version")?.unwrap_or("0".into());
        let version = version_string.trim().parse::<usize>()?;
        Ok(version)
    }

    /// Return the mountpoint of the boot vault.
    pub fn mountpoint(&self) -> &PathBuf {
        &self.mountpoint
    }
}

impl Drop for BootVault {
    fn drop(&mut self) {
        let _ = self.unmount();
    }
}

use std::{
    fs, io,
    path::{Path, PathBuf},
};

use libcryptsetup_rs::{
    CryptDevice, CryptInit, CryptTokenInfo,
    consts::{flags::CryptActivate, vals::EncryptionFormat},
};
use log::{debug, error, info, warn};
use loopdev::{LoopControl, LoopDevice};
use zeroize::Zeroizing;

use crate::{
    devices::{
        block_device::{BlockDevice, GenericBlockDevice},
        unlock_restrictions::UnlockRestrictions,
    },
    display::UserDisplay,
    error::PuavoError,
    utils::{
        keyboard, locale,
        luks_tpm_token_manager::{LuksTpmTokenManager, MAX_TOKENS},
        mount::unmount,
        recovery_qr, tpm,
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

/// Number of attempts before changing the prompt from "PIN" to "PIN or Recovery Key".
/// This is purely aesthetic. Both unlock methods are always tried regardless of the prompt.
pub const MAX_PIN_ONLY_ATTEMPTS: usize = 3;

/// How many more attempts to allow after the device reports it is locked,
/// before giving up so the user cannot keep guessing and prolong the lock.
pub const MAX_LOCKED_OUT_ATTEMPTS: usize = 3;

/// Mount point for the decrypted vault filesystem at runtime.
pub const VAULT_MOUNTPOINT: &str = "/run/puavo/boot-vault";

/// Filesystem type expected inside the vault image.
pub const VAULT_FILESYSTEM_TYPE: &str = "ext4";

/// Path to the recovery key file within the mounted vault.
pub const VAULT_RECOVERY_KEY: &str = "recovery.key";
const PCR_STATE_FILENAME: &str = "pcr.state";
const UNLOCK_RESTRICTIONS_FILENAME: &str = "unlock.restrictions.json";
const DB_VERSION_PROPERTY: &str = "db.version";
const DBX_VERSION_PROPERTY: &str = "dbx.version";

const PK_PRIVATE_KEY_FILENAME: &str = "pk.priv";
const PK_CERTIFICATE_FILENAME: &str = "pk.pem";
const KEK_PRIVATE_KEY_FILENAME: &str = "kek.priv";
const KEK_CERTIFICATE_FILENAME: &str = "kek.pem";
const SECURE_BOOT_PRIVATE_KEY_FILENAME: &str = "secure-boot.priv";
const SECURE_BOOT_CERTIFICATE_FILENAME: &str = "secure-boot.pem";

/// Path to the TPM lockout authorization file within the mounted vault.
/// This file is used to reset the TPM dictionary attack lockout counter.
pub const TPM_LOCKOUT_AUTH_FILENAME: &str = "tpm.lockout.auth";

/// Describes how the boot vault was unlocked.
#[derive(PartialEq, Eq)]
pub enum BootVaultUnlockMethod {
    TpmToken(Option<Zeroizing<String>>),
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
    enrollment_required: bool,
    loop_device: Option<LoopDevice>,
    luks_device: Option<LuksTpmTokenManager>,
    mountpoint: Option<String>,
    resources: Option<BootVaultResources>,
    unlock_method: Option<BootVaultUnlockMethod>,
}

impl BootVault {
    /// Check if a boot vault is mounted at the specified path.
    ///
    /// Parameters:
    /// - `mount_path`: Path where the boot vault should be mounted.
    pub fn is_mounted<P: AsRef<Path>>(mount_path: P) -> io::Result<bool> {
        mount_path.as_ref().join(VAULT_RECOVERY_KEY).try_exists()
    }

    /// Return the method used to unlock the vault after a successful mount, if any.
    pub fn unlock_method(&self) -> Option<&BootVaultUnlockMethod> {
        self.unlock_method.as_ref()
    }

    /// Get a list of token indices that match the specified requirements.
    ///
    /// Parameters:
    /// - `device`: The crypt device handle.
    /// - `requires_pin`: If true, return tokens that require a PIN.
    ///
    /// Returns:
    /// A vector of token indices that match the requirements.
    fn filter_tokens(device: &mut CryptDevice, requires_pin: bool) -> Vec<u32> {
        let mut tokens = Vec::new();

        for token_index in 0..MAX_TOKENS {
            match device.token_handle().status(token_index) {
                Ok(CryptTokenInfo::Inactive) => continue,
                Err(error) => {
                    debug!("Failed to check token {}: {}", token_index, error);
                    continue;
                }
                _ => {}
            }

            match LuksTpmTokenManager::is_pin_required(device, token_index) {
                Ok(is_pin_required) if is_pin_required == requires_pin => {
                    tokens.push(token_index);
                }
                Ok(_) => {}
                Err(error) => {
                    debug!(
                        "Failed to determine PIN requirement for token {}: {}",
                        token_index, error
                    );
                }
            }
        }

        tokens
    }

    /// Attempt to unlock the LUKS device using automatic TPM tokens (no PIN required).
    ///
    /// Parameters:
    /// - `device`: The crypt device handle to activate.
    ///
    /// Returns:
    /// - `Ok(true)` if unlocked using an automatic TPM token.
    /// - `Ok(false)` if no automatic unlock succeeded.
    fn try_automatic_tpm_unlock(
        &mut self,
        device: &mut CryptDevice,
    ) -> Result<bool, PuavoError> {
        debug!("Attempting automatic TPM unlock");

        let tokens = Self::filter_tokens(device, false);

        for token_index in tokens {
            match device.token_handle().activate_by_token::<()>(
                Some(VAULT_LUKS_DEVICE_NAME),
                Some(token_index),
                None,
                CryptActivate::empty(),
            ) {
                Ok(_) => {
                    info!("Unlocked with TPM token {} (no PIN)", token_index);
                    self.unlock_method =
                        Some(BootVaultUnlockMethod::TpmToken(None));
                    return Ok(true);
                }
                Err(error) => {
                    debug!(
                        "Failed to unlock with token {} without PIN: {}",
                        token_index, error
                    );
                }
            }
        }

        Ok(false)
    }

    /// Attempt to unlock the LUKS device using user input (PIN or Recovery Key).
    ///
    /// Each input is tried first as a PIN against the TPM tokens, then as a
    /// recovery key. The recovery key therefore always works. Once the device
    /// reports it is locked from too many wrong PINs, only
    /// fixed number of further attempts are allowed before giving
    /// up, so the user cannot keep guessing and prolong the lock.
    ///
    /// Parameters:
    /// - `device`: The crypt device handle to activate.
    /// - `display`: Display instance to show progress and messages.
    fn try_unlock_with_user_input(
        &mut self,
        device: &mut CryptDevice,
        display: &dyn UserDisplay,
    ) -> Result<(), PuavoError> {
        debug!("Attempting unlock with user input");

        // Find tokens that require a PIN
        let tokens = Self::filter_tokens(device, true);

        // Show the recovery QR code when the recovery key
        // prompt first becomes visible.
        let recovery_qr_attempt =
            if tokens.is_empty() { 0 } else { MAX_PIN_ONLY_ATTEMPTS };

        let strings = locale::strings();
        let keymap = keyboard::load_configured_keymap();

        // Attempts made after the device reported a lockout.
        let mut locked_out_attempts = 0usize;

        for attempt in 0.. {
            if attempt == recovery_qr_attempt {
                recovery_qr::show_recovery_qr();
            }

            let prompt = if tokens.is_empty() {
                strings.recovery_key_prompt
            } else if attempt < MAX_PIN_ONLY_ATTEMPTS {
                // Reveal the option for recovery key after a few failed attempts (aesthetic choice)
                strings.pin_prompt
            } else {
                strings.pin_or_recovery_key_prompt
            };

            if let Some(keymap) = &keymap {
                let _ = display.show_overlay(&format!(
                    "{}: {}",
                    strings.keymap_hint,
                    keymap.to_uppercase()
                ));
            }

            let user_input = match display.ask_password(prompt) {
                Ok(input) => input,
                Err(error) => {
                    error!("Failed to ask for password: {}", error);
                    return Err(error);
                }
            };

            let _ = display.hide_overlay();
            let _ = display.clear();

            // Try TPM tokens with PIN
            for token_index in &tokens {
                match device.token_handle().activate_by_token_pin::<()>(
                    Some(VAULT_LUKS_DEVICE_NAME),
                    None,
                    Some(*token_index),
                    user_input.as_bytes(),
                    None,
                    CryptActivate::empty(),
                ) {
                    Ok(_) => {
                        info!(
                            "Unlocked with TPM token {} using PIN",
                            token_index
                        );
                        self.unlock_method = Some(
                            BootVaultUnlockMethod::TpmToken(Some(user_input)),
                        );
                        return Ok(());
                    }
                    Err(error) => {
                        debug!(
                            "Failed to unlock with token {} using PIN: {}",
                            token_index, error
                        );
                    }
                }
            }

            // Try recovery key
            match device.activate_handle().activate_by_passphrase(
                Some(VAULT_LUKS_DEVICE_NAME),
                None,
                user_input.as_bytes(),
                CryptActivate::empty(),
            ) {
                Ok(_) => {
                    info!("Unlocked with recovery key");
                    self.unlock_method =
                        Some(BootVaultUnlockMethod::RecoveryKey);
                    return Ok(());
                }
                Err(error) => {
                    debug!("Failed to unlock using passphrase: {}", error);
                }
            }

            // Stop after a few attempts once the device is locked, so repeated
            // guesses cannot make the lock last even longer.
            if tpm::is_in_lockout().unwrap_or(false) {
                locked_out_attempts += 1;
                let _ = display.show_message("The device is temporarily locked from too many attempts. Enter the recovery key, or restart and try again later.");
                if locked_out_attempts >= MAX_LOCKED_OUT_ATTEMPTS {
                    warn!(
                        "Giving up after {} locked attempts",
                        locked_out_attempts
                    );
                    break;
                }
            } else {
                let _ = display.show_message(strings.unlock_failed);
            }
        }

        Err(PuavoError::UnlockError)
    }

    /// Initialize the LUKS device handle for the loop device and unlock it.
    ///
    /// Parameters:
    /// - `loop_device_path`: Path to the loop device backing the vault image (e.g. `/dev/loop0`).
    /// - `display`: Display instance to show progress and messages.
    ///
    /// Errors:
    /// Propagates loop device control errors.
    fn open_luks_device(
        &mut self,
        loop_device_path: &PathBuf,
        display: &dyn UserDisplay,
    ) -> Result<CryptDevice, PuavoError> {
        debug!("Initializing LUKS device for loop path {:?}", loop_device_path);
        let mut device = CryptInit::init(loop_device_path)?;

        debug!("Loading LUKS device from {}", loop_device_path.display());
        device
            .context_handle()
            .load::<()>(Some(EncryptionFormat::Luks2), None)?;

        // First try automatic TPM unlock (no PIN required)
        if self.try_automatic_tpm_unlock(&mut device)? {
            return Ok(device);
        }

        // If automatic unlock failed, prompt for PIN or recovery key
        self.try_unlock_with_user_input(&mut device, display)?;

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
    /// - `display`: Display instance to show progress and messages.
    ///
    /// Errors:
    /// - Loop device control errors.
    /// - Cryptsetup errors while unlocking the LUKS container.
    /// - IO or mount errors while mounting the filesystem.
    pub fn mount(
        &mut self,
        image_path: &PathBuf,
        display: &dyn UserDisplay,
    ) -> Result<(), PuavoError> {
        if !image_path.exists() {
            info!("Boot vault is not installed");
            return Err(PuavoError::NoBootVault);
        }

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

        let luks_device = self
            .open_luks_device(&loop_device_path, display)
            .inspect_err(|_error| {
                let _ = loop_device.detach();
            })?;

        debug!("LUKS device activated as {}", VAULT_LUKS_DEVICE_NAME);

        self.mount_luks_device().inspect_err(|_error| {
            let _ = loop_device.detach();
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

    /// Activates the specified LUKS device with the specified name using boot vault keys.
    pub fn activate(
        &self,
        device: &mut CryptDevice,
        name: &str,
    ) -> Result<(), PuavoError> {
        info!("Activating LUKS device '{}' using boot vault", name);
        let recovery_key = self.resources().read_recovery_key()?;
        device.activate_handle().activate_by_passphrase(
            Some(name),
            None,
            recovery_key.as_bytes(),
            CryptActivate::empty(),
        )?;
        Ok(())
    }

    /// Unmount and tear down the vault, closing the LUKS device and detaching
    /// the loop device.
    pub fn unmount(&mut self) -> Result<(), PuavoError> {
        // If any of the steps fails, the rest will likely also fail,
        // but we have to try and we will reboot anyway.

        // Unmount the LUKS device
        if let Some(mountpoint) = self.mountpoint.take() {
            if let Err(error) = unmount(Path::new(&mountpoint)) {
                warn!("Failed to unmount {}: {}", mountpoint, error);
            }

            if let Err(error) = fs::remove_dir(&mountpoint) {
                warn!("Failed to remove mountpoint {}: {}", mountpoint, error);
            }
        }

        // Close the LUKS device now that it is unmounted
        if let Some(mut luks_device) = self.luks_device.take() {
            let _ = luks_device.unmount(VAULT_LUKS_DEVICE_NAME);
        }

        // Detach the loop device from which the LUKS device was opened
        if let Some(loop_device) = self.loop_device.take() {
            debug!("Detaching loop device: {:?}", loop_device.path());
            let _ = loop_device.detach();
        }

        Ok(())
    }

    /// Returns the PIN used to unlock the boot vault, if any
    pub fn pin(&self) -> Option<&Zeroizing<String>> {
        match &self.unlock_method {
            Some(BootVaultUnlockMethod::TpmToken(pin)) => pin.as_ref(),
            _ => None,
        }
    }

    /// Sets the PIN for TPM enrollment
    pub fn set_pin(&mut self, pin: Option<Zeroizing<String>>) {
        self.unlock_method = Some(BootVaultUnlockMethod::TpmToken(pin));
    }

    /// Returns whether TPM enrollment is required
    pub fn is_enrollment_required(&self) -> bool {
        self.enrollment_required
    }

    /// Sets the flag indicating that TPM enrollment is required
    pub fn set_enrollment_required(&mut self, required: bool) {
        self.enrollment_required = required;
    }

    /// Returns a reference to the resources for interacting with the mounted vault.
    pub fn resources(&self) -> &BootVaultResources {
        self.resources.as_ref().expect(
            "Attempted to use boot vault resources when it was not mounted",
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

/// Even though the version information is not currently used, it will likely be used in the future.
#[allow(dead_code)]
impl BootVaultResources {
    /// Construct resource helper for the vault mounted at the specified path.
    pub fn new<T: AsRef<Path>>(mountpoint: T) -> Self {
        Self { mountpoint: mountpoint.as_ref().to_path_buf() }
    }

    /// Write a property with the specified value into the mounted vault.
    ///
    /// Parameters:
    /// - `key`: The name of the property to write.
    /// - `value`: The value to write.
    ///
    /// Errors:
    /// - `PuavoError::IoError` if writing fails.
    pub fn write_property<T: AsRef<str>>(
        &self,
        key: &str,
        value: T,
    ) -> Result<(), PuavoError> {
        debug!("Writing property '{}' to boot vault", key);

        let property_path = self.mountpoint.join(key);

        fs::write(property_path, value.as_ref()).map_err(PuavoError::IoError)
    }

    /// Read the specified property from the mounted vault.
    ///
    /// Parameters:
    /// - `key`: The name of the property to read.
    ///
    /// Errors:
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
                    Ok(None)
                } else {
                    Err(error.into())
                }
            }
        }
    }

    /// Write a recovery key file into the mounted vault.
    ///
    /// Parameters:
    /// - `recovery_key`: The key material to write.
    ///
    /// Errors:
    /// - `PuavoError::IoError` if writing fails.
    pub fn write_recovery_key(
        &self,
        recovery_key: &Zeroizing<String>,
    ) -> Result<(), PuavoError> {
        self.write_property(VAULT_RECOVERY_KEY, recovery_key)
    }

    /// Read the recovery key from the mounted vault.
    ///
    /// Errors:
    /// - `PuavoError::NoRecoveryKey` if the recovery key does not exist.
    /// - `PuavoError::IoError` if reading fails.
    pub fn read_recovery_key(&self) -> Result<Zeroizing<String>, PuavoError> {
        self.read_property(VAULT_RECOVERY_KEY)?
            .ok_or(PuavoError::NoRecoveryKey)
            .map(Zeroizing::new)
    }

    /// Set the version of the boot vault image format.
    ///
    /// Parameters:
    /// - `version`: The version number to write.
    ///
    /// Errors:
    /// - `PuavoError::IoError` if writing fails.
    pub fn set_version(&self, version: usize) -> Result<(), PuavoError> {
        self.write_property("version", version.to_string())
    }

    /// Get the version of the boot vault image format.
    ///
    /// Errors:
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

    /// Write the current PCR state to the boot vault.
    ///
    /// Parameters:
    /// - `pcr_state`: The PCR state to write.
    ///
    /// Errors:
    /// - `PuavoError::IoError` if writing fails.
    pub fn write_pcr_state(&self, pcr_state: String) -> Result<(), PuavoError> {
        self.write_property(PCR_STATE_FILENAME, pcr_state)
    }

    /// Read the cached PCR state from the boot vault.
    ///
    /// Returns:
    /// - `Ok(Some(state))` if a cached state exists.
    /// - `Ok(None)` if no cached state exists.
    ///
    /// Errors:
    /// - `PuavoError::IoError` if reading fails.
    pub fn read_pcr_state(&self) -> Result<Option<String>, PuavoError> {
        self.read_property(PCR_STATE_FILENAME)
    }

    /// Return the path to the recovery key file within the vault.
    pub fn recovery_key_path(&self) -> PathBuf {
        self.mountpoint.join(VAULT_RECOVERY_KEY)
    }

    /// Return the path to the TPM lockout authorization file
    pub fn tpm_lockout_auth_path(&self) -> PathBuf {
        self.mountpoint.join(TPM_LOCKOUT_AUTH_FILENAME)
    }

    /// Return the path to the device-specific PK private key within the vault.
    pub fn pk_private_key_path(&self) -> PathBuf {
        self.mountpoint.join(PK_PRIVATE_KEY_FILENAME)
    }

    /// Return the path to the device-specific PK certificate within the vault.
    pub fn pk_certificate_path(&self) -> PathBuf {
        self.mountpoint.join(PK_CERTIFICATE_FILENAME)
    }

    /// Return the path to the device-specific KEK private key within the vault.
    pub fn kek_private_key_path(&self) -> PathBuf {
        self.mountpoint.join(KEK_PRIVATE_KEY_FILENAME)
    }

    /// Return the path to the device-specific KEK certificate within the vault.
    pub fn kek_certificate_path(&self) -> PathBuf {
        self.mountpoint.join(KEK_CERTIFICATE_FILENAME)
    }

    /// Return the path to the device-specific Secure Boot private key within the vault.
    pub fn secure_boot_private_key_path(&self) -> PathBuf {
        self.mountpoint.join(SECURE_BOOT_PRIVATE_KEY_FILENAME)
    }

    /// Return the path to the device-specific Secure Boot certificate within the vault.
    pub fn secure_boot_certificate_path(&self) -> PathBuf {
        self.mountpoint.join(SECURE_BOOT_CERTIFICATE_FILENAME)
    }

    /// Read the installed Secure Boot db version from the boot vault.
    ///
    /// Returns `0` when no version has been recorded yet.
    pub fn db_version(&self) -> Result<u32, PuavoError> {
        self.read_version(DB_VERSION_PROPERTY)
    }

    /// Persist the installed Secure Boot db version in the boot vault.
    pub fn set_db_version(&self, version: u32) -> Result<(), PuavoError> {
        self.write_property(DB_VERSION_PROPERTY, version.to_string())
    }

    /// Read the installed Secure Boot dbx version from the boot vault.
    ///
    /// Returns `0` when no version has been recorded yet.
    pub fn dbx_version(&self) -> Result<u32, PuavoError> {
        self.read_version(DBX_VERSION_PROPERTY)
    }

    /// Persist the installed Secure Boot dbx version in the boot vault.
    pub fn set_dbx_version(&self, version: u32) -> Result<(), PuavoError> {
        self.write_property(DBX_VERSION_PROPERTY, version.to_string())
    }

    /// Read a version property, returning `0` when absent.
    fn read_version(&self, key: &str) -> Result<u32, PuavoError> {
        match self.read_property(key)? {
            Some(value) => value
                .trim()
                .parse::<u32>()
                .map_err(|_| PuavoError::PropertyParseError(key.to_string())),
            None => Ok(0),
        }
    }

    /// Save unlock restrictions to the boot vault.
    pub fn write_unlock_restrictions(
        &self,
        restrictions: &UnlockRestrictions,
    ) -> Result<(), PuavoError> {
        let json = serde_json::to_string(restrictions)
            .map_err(PuavoError::EnrollmentStateError)?;
        self.write_property(UNLOCK_RESTRICTIONS_FILENAME, json)
    }

    /// Load unlock restrictions from the boot vault.
    pub fn read_unlock_restrictions(
        &self,
    ) -> Result<Option<UnlockRestrictions>, PuavoError> {
        match self.read_property(UNLOCK_RESTRICTIONS_FILENAME)? {
            Some(json) => {
                let restrictions = serde_json::from_str(&json)
                    .map_err(PuavoError::EnrollmentStateError)?;
                Ok(Some(restrictions))
            }
            None => Ok(None),
        }
    }

    /// Check that all saved unlock restrictions are satisfied.
    pub fn check_unlock_restrictions(&self) -> Result<(), PuavoError> {
        match self.read_unlock_restrictions()? {
            Some(restrictions) => restrictions.check(),
            None => Ok(()),
        }
    }
}

impl Drop for BootVault {
    fn drop(&mut self) {
        let _ = self.unmount();
    }
}

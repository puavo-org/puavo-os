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

pub const VAULT_PATH: &str = "EFI/puavo/vault.img";
pub const VAULT_LUKS_DEVICE_NAME: &str = "puavo-boot-vault";
pub const VAULT_LUKS_DEVICE_PATH: &str = "/dev/mapper/puavo-boot-vault";
pub const VAULT_MOUNTPOINT: &str = "/run/puavo/boot-vault";
pub const VAULT_FILESYSTEM_TYPE: &str = "ext4";

pub const VAULT_RECOVERY_KEY: &str = "recovery.key";

pub const VAULT_FALLBACK_UNLOCK_KEY_PATH: &str =
    "/.extra/puavo/vault-unlock.key";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BootVaultUnlockMethod {
    TpmToken,
    RecoveryKey,
}

#[derive(Default)]
pub struct BootVault {
    loop_device: Option<LoopDevice>,
    luks_device: Option<LuksTpmTokenManager>,
    mountpoint: Option<String>,
    unlock_method: Option<BootVaultUnlockMethod>,
}

impl BootVault {
    pub fn unlock_method(&self) -> Option<BootVaultUnlockMethod> {
        self.unlock_method
    }

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
        Ok(())
    }

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

        let loop_device_path = loop_device.path().ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::NotFound,
                "Loop device path not found",
            )
        })?;

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

    pub fn write_recovery_key(
        &self,
        recovery_key: String,
    ) -> Result<(), PuavoError> {
        debug!("Writing recovery key to boot vault");

        let mountpoint =
            self.mountpoint.as_ref().ok_or(PuavoError::VaultNotMounted)?;

        let recovery_key_path =
            PathBuf::from(mountpoint).join(VAULT_RECOVERY_KEY);

        fs::write(recovery_key_path, recovery_key)
            .map_err(|error| PuavoError::IoError(error))
    }

    pub fn read_recovery_key(&self) -> Result<String, PuavoError> {
        let mountpoint =
            self.mountpoint.as_ref().ok_or(PuavoError::VaultNotMounted)?;

        let recovery_key_path =
            PathBuf::from(mountpoint).join(VAULT_RECOVERY_KEY);

        fs::read_to_string(recovery_key_path).map_err(PuavoError::IoError)
    }

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

    pub fn device(&self) -> &LuksTpmTokenManager {
        self.luks_device.as_ref().expect(
            "Attempted to use boot vault device when it was not mounted",
        )
    }
}

impl Drop for BootVault {
    fn drop(&mut self) {
        let _ = self.unmount();
    }
}

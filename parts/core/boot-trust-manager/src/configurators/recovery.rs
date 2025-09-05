use std::{fs, io, thread, time::Duration};

use log::info;
use serde::{Deserialize, Serialize};

use crate::{
    configurators::Configurator,
    devices::boot_vault::{BootVault, BootVaultUnlockMethod},
    display::UserDisplay,
    error::PuavoError,
    utils::luks_tpm_token_manager::LuksTpmTokenManager,
};

const CONFIGURATION_PATH: &str = "/etc/puavo/recovery.json";
const RECOVERY_KEY_DISPLAY_DURATION: u64 = 300;

#[derive(Serialize, Deserialize, Debug)]
struct RecoveryConfiguration {
    filename: String,
}

pub struct RecoveryConfigurator {
    configuration: RecoveryConfiguration,
}

impl RecoveryConfigurator {
    pub fn new() -> Result<Option<Self>, PuavoError> {
        let config_json = match fs::read_to_string(CONFIGURATION_PATH) {
            Ok(content) => content,
            Err(error) if error.kind() == io::ErrorKind::NotFound => {
                // Configuration file not found, skip enrollment
                return Ok(None);
            }
            Err(error) => {
                return Err(PuavoError::IoError(error));
            }
        };
        let configuration: RecoveryConfiguration =
            serde_json::from_str(&config_json).map_err(|_| {
                PuavoError::InvalidData(
                    "Failed to parse recovery configuration".into(),
                )
            })?;
        Ok(Some(Self { configuration }))
    }

    fn recover(
        &mut self,
        boot_vault: &BootVault,
        display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        info!("Accessing recovery key from boot vault");
        let recovery_key = boot_vault.read_recovery_key()?;
        info!("Successfully read recovery key");

        let _ = display
            .show_message(format!("Recovery key: {}", recovery_key).as_str());
        thread::sleep(Duration::from_secs(RECOVERY_KEY_DISPLAY_DURATION));

        Ok(())
    }
}

impl Configurator for RecoveryConfigurator {
    fn allowed(
        &self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        // Allow extracting the device recovery key only when the boot vault
        // was explicitly unlocked with the device-specific recovery key. An
        // automatically unlocked vault (in untampered recovery mode) is not
        // sufficient for extracting the recovery key.
        Ok(matches!(
            boot_vault.unlock_method(),
            Some(BootVaultUnlockMethod::RecoveryKey)
        ))
    }

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
        display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        self.recover(boot_vault, display)
    }

    fn filename(&self) -> Result<String, PuavoError> {
        Ok(self.configuration.filename.clone())
    }
}

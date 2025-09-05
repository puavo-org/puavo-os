use std::{fs, io};

use log::info;
use serde::{Deserialize, Serialize};

use crate::{
    configurators::Configurator,
    devices::boot_vault::{BootVault, BootVaultUnlockMethod},
    error::PuavoError,
    utils::luks_tpm_token_manager::LuksTpmTokenManager,
};

const CONFIGURATION_PATH: &str = "/etc/puavo/recovery.json";

#[derive(Serialize, Deserialize, Debug)]
struct RecoveryConfiguration {
    filename: String,
}

pub struct RecoveryConfigurator {
    _configuration: RecoveryConfiguration,
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
        Ok(Some(Self { _configuration: configuration }))
    }

    fn recover(&mut self, boot_vault: &BootVault) -> Result<(), PuavoError> {
        info!("Accessing recovery key from boot vault");
        let recovery_key = boot_vault.read_recovery_key()?;
        info!("Successfully read recovery key");

        // TODO: Replace with the proper way to show or save the recovery key
        println!("Recovery key: {}", recovery_key);

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
    ) -> Result<(), PuavoError> {
        self.recover(boot_vault)
    }
}
    }

    fn filename(&self) -> Result<String, PuavoError> {
        Ok(self.configuration.filename.clone())
    }
}

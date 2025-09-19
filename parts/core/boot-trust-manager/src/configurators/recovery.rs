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

/// Number of seconds the recovery key is displayed before continuing.
const RECOVERY_KEY_DISPLAY_DURATION: u64 = 300;

#[derive(Serialize, Deserialize, Debug)]
struct RecoveryConfiguration {
    filename: String,
}

/// Configurator that displays the device recovery key when the vault was
/// explicitly unlocked using that recovery key.
pub struct RecoveryConfigurator {
    configuration: RecoveryConfiguration,
}

impl RecoveryConfigurator {
    /// Attempt to construct the configurator by reading and parsing the
    /// recovery configuration file.
    ///
    /// Returns:
    /// - `Ok(Some(Self))` when the configuration file exists and is valid.
    /// - `Ok(None)` when the file is absent (configurator disabled).
    /// - `Err(error)` if the file exists but cannot be read or parsed.
    pub fn new() -> Result<Vec<Self>, PuavoError> {
        let config_json = match fs::read_to_string(CONFIGURATION_PATH) {
            Ok(content) => content,
            Err(error) if error.kind() == io::ErrorKind::NotFound => {
                // Configuration file not found, skip enrollment
                return Ok(vec![]);
            }
            Err(error) => {
                return Err(PuavoError::IoError(error));
            }
        };
        let configuration: RecoveryConfiguration =
            serde_json::from_str(&config_json)
                .map_err(PuavoError::ConfigurationError)?;
        Ok(vec![Self { configuration }])
    }

    /// Display the recovery key to the user for a fixed duration.
    ///
    /// Parameters:
    /// - `boot_vault`: Mounted boot vault from which to read the recovery key.
    /// - `display`: Display instance to show progress and messages.
    ///
    /// Errors:
    /// - `PuavoError::VaultNotMounted` if the vault is not mounted.
    /// - `PuavoError::IoError` if reading the recovery key fails.
    pub fn recover(
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
    /// Returns whether this configurator is permitted to execute.
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

    /// Retrieve and display the recovery key.
    ///
    /// Parameters:
    /// - `boot_vault`: Mounted boot vault.
    /// - `_primary_partition`: Unused for recovery.
    /// - `display`: Display instance to show progress and messages.
    ///
    /// Errors:
    /// Propagates internal errors.
    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
        display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        self.recover(boot_vault, display)
    }

    /// Return the trigger filename for this configurator.
    fn filename(&self) -> Result<String, PuavoError> {
        Ok(self.configuration.filename.clone())
    }
}

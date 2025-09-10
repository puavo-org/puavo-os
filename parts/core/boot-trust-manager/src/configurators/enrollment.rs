use std::{fs, io};

use log::info;
use serde::{Deserialize, Serialize};

use crate::{
    configurators::Configurator,
    devices::boot_vault::BootVault,
    display::UserDisplay,
    error::PuavoError,
    utils::luks_tpm_token_manager::{
        LuksTpmEnrollmentPolicy, LuksTpmTokenManager,
    },
};

const CONFIGURATION_PATH: &str = "/etc/puavo/enrollment.json";

#[derive(Serialize, Deserialize, Debug)]
struct EnrollmentConfiguration {
    filename: String,

    #[serde(rename = "enrollment-policy")]
    enrollment_policy: LuksTpmEnrollmentPolicy,
}

/// Configurator that (re)enrolls LUKS TPM policies for the boot vault and
/// primary partition using a shared LUKS key.
pub struct EnrollmentConfigurator {
    configuration: EnrollmentConfiguration,
}

impl EnrollmentConfigurator {
    /// Attempt to construct the configurator by reading and parsing the
    /// enrollment configuration file.
    ///
    /// Returns:
    /// - `Ok(Some(Self))` when the configuration file exists and is valid.
    /// - `Ok(None)` when the file is absent (configurator disabled).
    /// - `Err(error)` if the file exists but cannot be read or parsed.
    pub fn new() -> Result<Option<Self>, PuavoError> {
        let config_json = match fs::read_to_string(CONFIGURATION_PATH) {
            Ok(content) => content,
            Err(error) if error.kind() == io::ErrorKind::NotFound => {
                // Configuration file not found, skip enrollment
                return Ok(None);
            }
            Err(error) => return Err(PuavoError::IoError(error)),
        };
        let configuration: EnrollmentConfiguration =
            serde_json::from_str(&config_json).map_err(|error| {
                PuavoError::InvalidData(format!(
                    "Failed to parse enrollment configuration: {}",
                    error
                ))
            })?;
        Ok(Some(Self { configuration }))
    }

    /// Enroll (or re-enroll) TPM policies for both the boot vault and the
    /// primary encrypted partition.
    /// 
    /// Behavior:
    /// 1. Read recovery key from boot vault.
    /// 2. Validate recovery key works on both devices.
    /// 3. Enroll boot vault first (fail-fast before touching primary partition).
    /// 4. Enroll primary partition with the same policy.
    ///
    /// Parameters:
    /// - `boot_vault`: Mounted boot vault used to fetch the recovery key and to enroll its own device.
    /// - `primary_partition`: Token manager for the primary encrypted partition.
    ///
    /// Errors:
    /// - `PuavoError::VaultNotMounted` if the vault is not mounted when reading the key.
    /// - `PuavoError::InvalidRecoveryKey` if the recovery key does not unlock either device.
    /// - Propagates internal errors from token enrollment operations.
    pub fn enroll(
        &mut self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<(), PuavoError> {
        info!(
            "Enrolling disk with new TPM policy: {:#?}",
            self.configuration.enrollment_policy
        );
        let recovery_key = boot_vault.read_recovery_key()?.clone();

        // Verify we have control over both devices before proceeding
        boot_vault
            .device_mut()
            .test_passphrase(&recovery_key)
            .map_err(|_| PuavoError::InvalidRecoveryKey)?;
        primary_partition
            .test_passphrase(&recovery_key)
            .map_err(|_| PuavoError::InvalidRecoveryKey)?;

        // Enroll the boot vault first, because if it fails we have not touched
        // the primary partition.
        boot_vault
            .device()
            .enroll(&recovery_key, &self.configuration.enrollment_policy)?;
        primary_partition
            .enroll(&recovery_key, &self.configuration.enrollment_policy)
    }
}

impl Configurator for EnrollmentConfigurator {
    /// Returns whether this configurator is permitted to execute.
    fn allowed(
        &self,
        _boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        // Boot vault being unlocked is evidence that we are allowed to enroll.
        Ok(true)
    }

    /// Execute TPM enrollment for the boot vault and primary partition.
    ///
    /// Errors:
    /// Propagates internal errors.
    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
        _display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        self.enroll(boot_vault, primary_partition)
    }

    /// Return the trigger filename for this configurator.
    fn filename(&self) -> Result<String, PuavoError> {
        Ok(self.configuration.filename.clone())
    }
}

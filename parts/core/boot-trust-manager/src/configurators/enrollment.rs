use std::{fs, io};

use log::info;
use serde::{Deserialize, Serialize};

use crate::{
    configurators::Configurator,
    devices::boot_vault::BootVault,
    error::PuavoError,
    utils::luks_tpm_token_manager::{
        LuksTpmEnrollmentPolicy, LuksTpmTokenManager,
    },
};

const CONFIGURATION_PATH: &str = "/etc/puavo/enrollment.json";

#[derive(Serialize, Deserialize, Debug)]
struct EnrollmentConfiguration {
    #[serde(rename = "enrollment-policy")]
    enrollment_policy: LuksTpmEnrollmentPolicy,
}

pub struct EnrollmentConfigurator {
    configuration: EnrollmentConfiguration,
}

impl EnrollmentConfigurator {
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

    pub fn enroll(
        &mut self,
        boot_vault: &BootVault,
        primary_partition: &LuksTpmTokenManager,
    ) -> Result<(), PuavoError> {
        info!(
            "Enrolling disk with new TPM policy: {:#?}",
            self.configuration.enrollment_policy
        );
        let recovery_key = boot_vault.read_recovery_key()?.clone();

        // TODO: Test the recovery key on both devices (CryptVolumeKeyHandle::get?)

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
    fn allowed(
        &self,
        _boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        // Boot vault being unlocked is evidence that we are allowed to enroll.
        Ok(true)
    }

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<(), PuavoError> {
        self.enroll(boot_vault, primary_partition)
    }
}

impl Drop for EnrollmentConfigurator {
    fn drop(&mut self) {
        let _ = std::fs::remove_file(CONFIGURATION_PATH);
    }
}

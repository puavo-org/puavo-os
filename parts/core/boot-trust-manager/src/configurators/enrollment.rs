use std::{collections::HashMap, fs, hash::Hash, io::ErrorKind};

use log::{debug, info};
use serde::{Deserialize, Serialize};

use crate::{
    configurators::Configurator,
    devices::boot_vault::{BootVault, BootVaultResources},
    display::UserDisplay,
    error::PuavoError,
    utils::{
        hashed::Hashed,
        luks_tpm_token_manager::{
            LuksTpmEnrollmentPolicy, LuksTpmTokenManager,
        },
    },
};

const CONFIGURATION_BASE_DIRECTORY: &str = "/etc/puavo/enrollment";

// Trigger file name for the aggregated enrollment configurator
const CONFIGURATOR_FILENAME: &str = "enrollment.json";

const STATE_FILENAME: &str = "enrollment.state.json";

#[derive(Serialize, Deserialize, Debug, Clone, Hash)]
struct EnrollmentItemConfiguration {
    /// Name of the enrollment item
    name: String,
    /// Version of the enrollment item
    version: u32,
    /// Enrollment policy
    #[serde(rename = "policy")]
    policy: LuksTpmEnrollmentPolicy,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct EnrollmentSetConfiguration {
    /// Filename used to trigger the configurator
    filename: String,
    /// All enrollment items to apply (order matters; first will wipe existing tokens)
    enrollments: Vec<EnrollmentItemConfiguration>,
}

/// Stores the name of the enrollment and its configuration as a hash.
/// The hash is used for detecting changes between boots.
#[derive(Serialize, Deserialize, Debug, Clone, PartialEq, Eq, Hash)]
struct EnrollmentStateRecord {
    name: String,
    hash: u64,
}

/// Set of enrollment records.
#[derive(Serialize, Deserialize, Debug, Clone, Default)]
struct EnrollmentSetState {
    enrollments: Vec<EnrollmentStateRecord>,
}

impl EnrollmentSetState {
    /// Serialize the state to JSON and store it in the boot vault.
    /// Used for detecting configuration changes between boots.
    fn save(self, resources: &BootVaultResources) -> Result<(), PuavoError> {
        let state_string = serde_json::to_string(&self)
            .map_err(PuavoError::EnrollmentStateError)?;
        resources.write_property(STATE_FILENAME, state_string)
    }

    /// Load the persisted state from the boot vault if it exists.
    ///
    /// Returns `Ok(Some(state))` when a previous state was found, or
    /// `Ok(None)` when no state has been persisted yet.
    fn load(
        resources: &BootVaultResources,
    ) -> Result<Option<Self>, PuavoError> {
        let json = resources.read_property(STATE_FILENAME)?;
        match json {
            Some(content) => {
                let state = serde_json::from_str(&content)
                    .map_err(PuavoError::EnrollmentStateError)?;
                Ok(Some(state))
            }
            None => Ok(None),
        }
    }

    /// Convert the state into a map of enrollment name to its recorded hash.
    fn as_map(&self) -> HashMap<String, u64> {
        self.enrollments
            .iter()
            .map(|record| (record.name.clone(), record.hash))
            .collect()
    }
}

/// Configurator that (re)enrolls LUKS TPM policies for the boot vault and
/// primary partition using a shared LUKS key, for a whole set of enrollments.
pub struct EnrollmentConfigurator {
    configuration: EnrollmentSetConfiguration,
}

impl EnrollmentConfigurator {
    pub fn new() -> Result<Vec<Self>, PuavoError> {
        debug!("Loading enrollments from {}", CONFIGURATION_BASE_DIRECTORY);

        let directory_reader = match fs::read_dir(CONFIGURATION_BASE_DIRECTORY)
        {
            Ok(reader) => reader,
            Err(error) if error.kind() == ErrorKind::NotFound => {
                debug!(
                    "Enrollment directory '{}' does not exist, skipping",
                    CONFIGURATION_BASE_DIRECTORY
                );
                return Ok(Vec::new());
            }
            Err(error) => return Err(error.into()),
        };

        // List and sort enrollment JSON files
        let mut json_paths: Vec<_> = directory_reader
            .filter_map(|entry_result| entry_result.ok())
            .map(|entry| entry.path())
            .filter(|path| {
                path.extension().and_then(|extension| extension.to_str())
                    == Some("json")
            })
            .collect();
        json_paths.sort();

        let mut enrollments: Vec<EnrollmentItemConfiguration> = Vec::new();

        for path in json_paths {
            debug!("Reading enrollment configuration file: {:?}", path);
            let data = fs::read_to_string(&path)?;
            let enrollment =
                serde_json::from_str::<EnrollmentItemConfiguration>(&data)
                    .map_err(PuavoError::EnrollmentStateError)?;
            enrollments.push(enrollment);
        }

        if enrollments.is_empty() {
            return Ok(Vec::new());
        }

        let configuration = EnrollmentSetConfiguration {
            filename: CONFIGURATOR_FILENAME.to_string(),
            enrollments,
        };

        Ok(vec![Self { configuration }])
    }

    /// Return true if any token on the specified device is invalid.
    fn any_invalid_token(
        token_manager: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        let tokens = token_manager.list_tokens()?;

        if tokens.is_empty() {
            // No tokens present, treat as invalid state
            debug!("Device {} has no TPM tokens", token_manager.device_path());
            return Ok(true);
        }

        debug!("Validating tokens on device {}", token_manager.device_path());
        let mut any_invalid_token = false;

        for token_id in tokens.keys() {
            if token_manager.test_token(*token_id) {
                debug!("Token {} is valid", token_id);
                continue;
            }

            debug!("Token {} is invalid", token_id);
            any_invalid_token = true;
        }

        Ok(any_invalid_token)
    }

    /// Compare the desired set (from configuration) with the stored state.
    /// Returns true if they differ in names or versions.
    fn any_configuration_changed(
        &self,
        resources: &BootVaultResources,
    ) -> Result<bool, PuavoError> {
        let enrollment_hashes: HashMap<String, u64> = self
            .configuration
            .enrollments
            .iter()
            .map(|enrollment| (enrollment.name.clone(), enrollment.hashed()))
            .collect();

        let installed_enrollment_state = EnrollmentSetState::load(resources)?;
        let installed_enrollment_hashes = installed_enrollment_state
            .as_ref()
            .map(|state| state.as_map())
            .unwrap_or_default();

        Ok(enrollment_hashes != installed_enrollment_hashes)
    }

    /// Builds the current enrollment state from the configuration.
    fn build_state_from_configurations(&self) -> EnrollmentSetState {
        let enrollments = self
            .configuration
            .enrollments
            .iter()
            .map(|enrollment| EnrollmentStateRecord {
                name: enrollment.name.clone(),
                hash: enrollment.hashed(),
            })
            .collect();
        EnrollmentSetState { enrollments }
    }

    /// Enroll all items to the specified device.
    /// Wipes all the previous TPM tokens.
    fn wipe_and_enroll_to_device(
        token_manager: &mut LuksTpmTokenManager,
        recovery_key: &String,
        items: &[EnrollmentItemConfiguration],
    ) -> Result<(), PuavoError> {
        for (index, item) in items.iter().enumerate() {
            let policy = &item.policy;
            let wipe = index == 0;
            token_manager.enroll(recovery_key, policy, wipe)?;
        }
        Ok(())
    }

    /// Enroll (or re-enroll) all configured TPM policies for both the boot vault and the
    /// primary encrypted partition.
    pub fn enroll_all(
        &mut self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<(), PuavoError> {
        let resources = boot_vault.resources().clone();
        let recovery_key = resources.read_recovery_key()?.clone();

        // Verify we have control over both devices before proceeding
        debug!("Testing recovery key on both devices");
        boot_vault
            .device_mut()
            .test_passphrase(&recovery_key)
            .map_err(|_| PuavoError::InvalidRecoveryKey)?;
        primary_partition
            .test_passphrase(&recovery_key)
            .map_err(|_| PuavoError::InvalidRecoveryKey)?;

        info!(
            "Applying {} enrollment(s)",
            self.configuration.enrollments.len()
        );

        // Enroll to the boot vault first
        Self::wipe_and_enroll_to_device(
            boot_vault.device_mut(),
            &recovery_key,
            &self.configuration.enrollments,
        )?;

        // Then enroll to the primary partition
        Self::wipe_and_enroll_to_device(
            primary_partition,
            &recovery_key,
            &self.configuration.enrollments,
        )?;

        self.build_state_from_configurations().save(&resources)?;

        Ok(())
    }
}

impl Configurator for EnrollmentConfigurator {
    /// Returns whether this configurator is permitted to execute.
    fn allowed(
        &self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        let resources = boot_vault.resources();

        if self.any_configuration_changed(resources)? {
            debug!("Enrollment configurations have changed");
            return Ok(true);
        }

        let any_invalid_token =
            Self::any_invalid_token(boot_vault.device_mut())?
                || Self::any_invalid_token(primary_partition)?;

        Ok(any_invalid_token)
    }

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
        display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        let _ = display.show_message("Enrolling...");
        self.enroll_all(boot_vault, primary_partition)
    }

    /// Return the trigger filename for this configurator.
    fn filename(&self) -> Result<String, PuavoError> {
        Ok(self.configuration.filename.clone())
    }
}

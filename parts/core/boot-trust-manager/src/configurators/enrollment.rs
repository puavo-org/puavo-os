use std::{collections::HashMap, fs, hash::Hash, io::ErrorKind};

use log::{debug, error, info};
use serde::{Deserialize, Serialize};

use crate::{
    configurators::Configurator,
    devices::{
        boot_vault::{BootVault, BootVaultResources, BootVaultUnlockMethod},
        unlock_restrictions::UnlockRestrictions,
    },
    display::UserDisplay,
    error::PuavoError,
    utils::{
        hashed::Hashed,
        luks_tpm_token_manager::{
            LuksTpmEnrollmentPolicy, LuksTpmTokenManager,
        },
        tpm::read_pcrs_as_string,
    },
};

const CONFIGURATION_BASE_DIRECTORY: &str = "/etc/puavo/enrollment";
const STATE_FILENAME: &str = "enrollment.state.json";

#[derive(Serialize, Deserialize, Debug, Clone, Hash)]
pub struct EnrollmentItemConfiguration {
    /// Name of the enrollment item
    pub name: String,
    /// Version of the enrollment item
    pub version: u32,
    /// Enrollment policy
    #[serde(rename = "policy")]
    pub policy: LuksTpmEnrollmentPolicy,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct EnrollmentSetConfiguration {
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
    /// Returns the loaded enrollment configurations.
    pub fn enrollments(&self) -> &[EnrollmentItemConfiguration] {
        &self.configuration.enrollments
    }

    /// Load enrollment configurations from the default system directory.
    pub fn new() -> Result<Vec<Self>, PuavoError> {
        Self::from_directory(CONFIGURATION_BASE_DIRECTORY)
    }

    /// Load enrollment configurations from the specified directory.
    ///
    /// Parameters:
    /// - `directory`: Path to directory containing enrollment JSON files.
    ///
    /// Returns:
    /// A vector of configurators, one per enrollment set found.
    pub fn from_directory(directory: &str) -> Result<Vec<Self>, PuavoError> {
        debug!("Loading enrollments from {}", directory);

        let directory_reader = match fs::read_dir(directory) {
            Ok(reader) => reader,
            Err(error) if error.kind() == ErrorKind::NotFound => {
                debug!(
                    "Enrollment directory '{}' does not exist, skipping",
                    directory
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
            let mut enrollment =
                serde_json::from_str::<EnrollmentItemConfiguration>(&data)
                    .map_err(PuavoError::EnrollmentStateError)?;
            enrollment.policy.find_public_keys()?;
            enrollments.push(enrollment);
        }

        if enrollments.is_empty() {
            return Ok(Vec::new());
        }

        let configuration = EnrollmentSetConfiguration { enrollments };

        Ok(vec![Self { configuration }])
    }

    /// Return true if any token on the specified device is invalid.
    fn any_invalid_token(
        token_manager: &mut LuksTpmTokenManager,
        pin: Option<String>,
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
            if token_manager.test_token(*token_id, pin.as_ref()) {
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

    /// Collect all unique PCR indices used by the all enrollment configurations.
    fn collect_pcr_indices(&self) -> Vec<u32> {
        let mut indices: Vec<u32> = self
            .configuration
            .enrollments
            .iter()
            .flat_map(|enrollment| enrollment.policy.pcr_indices())
            .collect();

        indices.sort();
        indices.dedup();
        indices
    }

    /// Check if the cached PCR state matches the current PCR values.
    fn pcr_cache_matches(
        &self,
        resources: &BootVaultResources,
    ) -> Result<bool, PuavoError> {
        let pcr_indices = self.collect_pcr_indices();
        let pcr_state = read_pcrs_as_string(&pcr_indices)?;
        debug!("Current PCR state: {:?}", pcr_state);

        let cached_pcr_state = resources.read_pcr_state()?.unwrap_or_default();
        debug!("Cached PCR state: {:?}", cached_pcr_state);

        let matches = cached_pcr_state == pcr_state;
        debug!("PCR state unchanged: {}", matches);

        Ok(matches)
    }

    /// Save the current PCR state to the boot vault cache.
    fn save_pcr_cache(
        &self,
        resources: &BootVaultResources,
    ) -> Result<(), PuavoError> {
        let pcr_indices = self.collect_pcr_indices();
        let pcr_state = read_pcrs_as_string(&pcr_indices)?;
        debug!("Current PCR state: {:?}", pcr_state);

        resources.write_pcr_state(pcr_state)?;
        debug!("Saved PCR state");
        Ok(())
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
        pin: Option<String>,
        items: &[EnrollmentItemConfiguration],
    ) -> Result<(), PuavoError> {
        let mut wipe = true;

        for item in items {
            let policy = &item.policy;

            if policy.public_keys.is_empty() {
                token_manager.enroll(
                    recovery_key,
                    policy,
                    pin.clone(),
                    None,
                    wipe,
                )?;
                wipe = false;
            } else {
                for (public_key, _) in &policy.public_keys {
                    token_manager.enroll(
                        recovery_key,
                        policy,
                        pin.clone(),
                        Some(public_key),
                        wipe,
                    )?;
                    wipe = false;
                }
            }
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

        let pin = boot_vault.pin().cloned();

        // Enroll to the boot vault first
        Self::wipe_and_enroll_to_device(
            boot_vault.device_mut(),
            &recovery_key,
            pin.clone(),
            &self.configuration.enrollments,
        )?;

        // Then enroll to the primary partition
        Self::wipe_and_enroll_to_device(
            primary_partition,
            &recovery_key,
            pin,
            &self.configuration.enrollments,
        )?;

        self.build_state_from_configurations().save(&resources)?;

        let restrictions = UnlockRestrictions::from_current_state();
        if let Err(error) = resources.write_unlock_restrictions(&restrictions) {
            error!("Failed to save unlock restrictions: {}", error);
        }

        // Cache the PCR state after successful enrollment to skip token validation on future boots
        // when PCR values remain unchanged.
        if let Err(error) = self.save_pcr_cache(&resources) {
            error!("Failed to save PCR cache: {}", error);
        }

        Ok(())
    }
}

impl Configurator for EnrollmentConfigurator {
    fn activate(
        &self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        // Check if enrollment is explicitly required (e.g. PIN change)
        if boot_vault.is_enrollment_required() {
            info!("Enrollment is explicitly required");
            return Ok(true);
        }

        if !matches!(
            boot_vault.unlock_method(),
            Some(BootVaultUnlockMethod::TpmToken(..))
        ) {
            info!(
                "Skipping enrollments, because the device was not unlocked with TPM"
            );
            // NOTE: Enrollments might require the TPM PIN, which was not used for unlocking
            return Ok(false);
        }

        let resources = boot_vault.resources();

        if self.any_configuration_changed(resources)? {
            debug!("Enrollment configurations have changed");
            return Ok(true);
        }

        // Check if PCR state matches the cache from last successful enrollment.
        // If PCRs match, we can skip the slow token validation.
        match self.pcr_cache_matches(resources) {
            Ok(true) => {
                debug!("PCR state matches cache, skipping token validation");
                return Ok(false);
            }
            Ok(false) => {
                debug!("PCR state differs from cache, will validate tokens");
            }
            Err(error) => {
                error!(
                    "Failed to check PCR cache: {}, falling back to token validation",
                    error
                );
            }
        }

        let pin = boot_vault.pin().cloned();
        let any_invalid_token =
            Self::any_invalid_token(boot_vault.device_mut(), pin.clone())?
                || Self::any_invalid_token(primary_partition, pin)?;

        Ok(any_invalid_token)
    }

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
        display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        let _ = display.show_message("Configuring disk encryption...");
        self.enroll_all(boot_vault, primary_partition)
    }

    fn name(&self) -> &'static str {
        "Enrollment"
    }
}

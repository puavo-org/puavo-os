use cryptoki::object::ObjectClass;
use openssl::hash::{MessageDigest, hash};
use puavo_hsm::{
    HsmKeyManager, HsmSession, KeyLabel, key_management::KeyManagementError,
};
use puavo_ipc::{
    DaemonResponse, DaemonResponseData, OrganisationCommand,
    OrganisationKeyListing, OrganisationKeyVersion, OrganisationPublicKey,
};
use std::{collections::HashMap, fmt::Write as _, fs, path::PathBuf};

/// Errors that can occur during organisation commands
#[derive(Debug, thiserror::Error)]
pub enum OrganisationCommandError {
    #[error(transparent)]
    KeyManagement(#[from] KeyManagementError),

    #[error("Organisation is already initialized")]
    OrganisationAlreadyInitialized,

    #[error("Organisation '{organisation_id}' is not initialized")]
    OrganisationNotInitialized { organisation_id: String },

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("OpenSSL error: {0}")]
    OpenSsl(#[from] openssl::error::ErrorStack),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
}

impl From<OrganisationCommandError> for DaemonResponse {
    fn from(error: OrganisationCommandError) -> Self {
        DaemonResponse::Error(error.to_string())
    }
}

/// Execute organisation key initialization
fn initialize(
    hsm_session: &HsmSession,
    organisation_id: String,
) -> Result<(), OrganisationCommandError> {
    tracing::info!("Initializing organisation key: {}", organisation_id);

    let key_label = KeyLabel::organisation(&organisation_id, 1);
    let key_manager = HsmKeyManager::new(hsm_session);
    let organisation_keys =
        key_manager.filter_keys(ObjectClass::PRIVATE_KEY, &key_label.label)?;

    if !organisation_keys.is_empty() {
        tracing::error!("Organisation key already exists");
        return Err(OrganisationCommandError::OrganisationAlreadyInitialized);
    }

    tracing::info!("Generating new organisation key: {}", organisation_id);
    let _ = key_manager.generate_key(&key_label)?;

    Ok(())
}

/// Generate the next organisation key version
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `organisation_id` - Organisation identifier
///
/// Returns:
/// The newly created key version
///
/// Errors:
/// Returns `OrganisationNotInitialized` if no existing key is present,
/// or a `KeyManagement` error if HSM operations fail.
fn rotate(
    hsm_session: &HsmSession,
    organisation_id: &str,
) -> Result<u32, OrganisationCommandError> {
    tracing::info!("Rotating organisation key: {}", organisation_id);

    let key_manager = HsmKeyManager::new(hsm_session);
    let organisation_label = KeyLabel::organisation_label(organisation_id);

    let latest_version = key_manager
        .get_latest_key(ObjectClass::PUBLIC_KEY, &organisation_label)?
        .map(|(_, version)| version)
        .ok_or_else(|| {
            OrganisationCommandError::OrganisationNotInitialized {
                organisation_id: organisation_id.to_string(),
            }
        })?;

    let new_version = latest_version + 1;
    let key_label = KeyLabel::organisation(organisation_id, new_version);

    tracing::info!(
        "Generating organisation key {} version {}",
        organisation_id,
        new_version
    );
    let _ = key_manager.generate_key(&key_label)?;

    Ok(new_version)
}

/// Export organisation public key
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `organisation_id` - Organisation identifier
/// * `version` - Key version to export
/// * `output` - Optional output file path
///
/// Returns:
/// Organisation public key structure or error
///
/// Errors:
/// Returns error if key cannot be found or exported
fn export_public_key(
    hsm_session: &HsmSession,
    organisation_id: String,
    version: u32,
    output: Option<PathBuf>,
) -> Result<OrganisationPublicKey, OrganisationCommandError> {
    tracing::info!(
        "Exporting organisation public key: {} version {}",
        organisation_id,
        version
    );

    let key_label = KeyLabel::organisation(&organisation_id, version);
    let key_manager = HsmKeyManager::new(hsm_session);

    // Get the public key handle
    let public_key_handle = key_manager
        .get_key_with_version(ObjectClass::PUBLIC_KEY, &key_label)?;

    // Extract the RSA public key
    let public_key = key_manager.extract_public_key(&public_key_handle)?;

    // Convert to PKCS#1 PEM format
    let public_key_pem_bytes = public_key.rsa()?.public_key_to_pem_pkcs1()?;
    let public_key_pem = String::from_utf8(public_key_pem_bytes)
        .expect("PKCS#1 PEM is always valid UTF-8");

    let organisation_public_key = OrganisationPublicKey {
        organisation_id: organisation_id.clone(),
        version,
        public_key_pem,
    };

    // Write to file if output path is provided
    if let Some(output_path) = output {
        let json_content =
            serde_json::to_string_pretty(&organisation_public_key)?;
        fs::write(output_path, json_content)?;
        tracing::info!("Public key exported to file");
    }

    tracing::info!("Organisation public key export completed");
    Ok(organisation_public_key)
}

/// List organisation keys
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `organisation_id_filter` - Optional organisation identifier to filter results
///
/// Returns:
/// List of organisation key listings or error
///
/// Errors:
/// Returns error if keys cannot be listed
fn list_keys(
    hsm_session: &HsmSession,
    organisation_id_filter: Option<String>,
) -> Result<Vec<OrganisationKeyListing>, OrganisationCommandError> {
    tracing::info!("Listing organisation keys");

    let key_manager = HsmKeyManager::new(hsm_session);
    let all_organisation_keys = key_manager.list_all_organisation_keys()?;

    // Collect and group all keys by organisation
    let mut organisations: HashMap<String, Vec<OrganisationKeyVersion>> =
        HashMap::new();

    for (label, version, public_key_handle) in all_organisation_keys {
        let organisation_id =
            KeyLabel::organisation_id_from_label(&label).unwrap_or(&label);

        // Apply the organisation ID filter if provided
        if let Some(ref filter_id) = organisation_id_filter {
            if organisation_id != filter_id {
                continue;
            }
        }

        // Compute the fingerprint of the public key
        let public_key = key_manager.extract_public_key(&public_key_handle)?;
        let public_key_pem = public_key.rsa()?.public_key_to_pem_pkcs1()?;
        let fingerprint = hash(MessageDigest::sha256(), &public_key_pem)?
            .iter()
            .fold(String::new(), |mut acc, byte| {
                let _ = write!(acc, "{:02x}", byte);
                acc
            });

        // Insert into the organisations map
        organisations
            .entry(organisation_id.to_string())
            .or_default()
            .push(OrganisationKeyVersion { version, fingerprint });
    }

    // Sort and prepare the listings
    let mut listings: Vec<OrganisationKeyListing> = organisations
        .into_iter()
        .map(|(organisation_id, mut versions)| {
            versions.sort_by_key(|version| version.version);
            OrganisationKeyListing { organisation_id, versions }
        })
        .collect();

    listings.sort_by(|first, second| {
        first.organisation_id.cmp(&second.organisation_id)
    });

    Ok(listings)
}

/// Execute organisation key management command
///
/// Parameters:
/// * `command` - Organisation command to execute
///
/// Returns:
/// Daemon response with success or error
pub fn execute(
    hsm_session: &HsmSession,
    command: OrganisationCommand,
) -> DaemonResponse {
    match command {
        OrganisationCommand::Initialize { organisation_id } => {
            execute_initialize(hsm_session, organisation_id)
        }

        OrganisationCommand::Rotate { organisation_id } => {
            execute_rotate(hsm_session, organisation_id)
        }

        OrganisationCommand::Export { organisation_id, version, output } => {
            execute_export(hsm_session, organisation_id, version, output)
        }

        OrganisationCommand::List { organisation_id } => {
            execute_list(hsm_session, organisation_id)
        }
    }
}

/// Execute organisation key initialization
fn execute_initialize(
    hsm_session: &HsmSession,
    organisation_id: String,
) -> DaemonResponse {
    initialize(hsm_session, organisation_id)
        .map(|_| {
            tracing::info!("Organisation key initialization completed");
            DaemonResponse::success()
        })
        .into()
}

/// Execute organisation key rotation
fn execute_rotate(
    hsm_session: &HsmSession,
    organisation_id: String,
) -> DaemonResponse {
    rotate(hsm_session, &organisation_id)
        .map(|new_version| {
            tracing::info!(
                "Organisation key rotation completed: {} version {}",
                organisation_id,
                new_version
            );
            DaemonResponseData::OrganisationKeyVersion {
                organisation_id,
                version: new_version,
            }
        })
        .into()
}

/// Execute organisation public key export
fn execute_export(
    hsm_session: &HsmSession,
    organisation_id: String,
    version: u32,
    output: Option<PathBuf>,
) -> DaemonResponse {
    export_public_key(hsm_session, organisation_id, version, output)
        .map(|public_key_data| {
            tracing::info!("Organisation public key export completed");
            DaemonResponseData::OrganisationPublicKey(public_key_data)
        })
        .into()
}

/// Execute organisation key listing
fn execute_list(
    hsm_session: &HsmSession,
    organisation_id: Option<String>,
) -> DaemonResponse {
    list_keys(hsm_session, organisation_id)
        .map(|listings| {
            tracing::info!("Organisation key listing completed");
            DaemonResponseData::OrganisationKeyListings(listings)
        })
        .into()
}

#[cfg(test)]
mod tests {
    use puavo_hsm::TestHsmSession;
    use puavo_ipc::DaemonResponseData;

    use super::*;

    #[tokio::test]
    async fn test_initialize_organisation_key() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-init".to_string();

        let response = execute_initialize(session, organisation_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // Verify the key was created
        let key_manager = HsmKeyManager::new(session);
        let organisation_keys = key_manager
            .filter_keys(
                ObjectClass::PRIVATE_KEY,
                &KeyLabel::organisation_label(&organisation_id),
            )
            .unwrap();

        assert_eq!(organisation_keys.len(), 1);

        let version =
            key_manager.get_key_version(&organisation_keys[0]).unwrap();
        assert_eq!(version, 1);
    }

    #[tokio::test]
    async fn test_initialize_organisation_key_already_exists() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-exists".to_string();

        // Initialize once
        let response = execute_initialize(session, organisation_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // Try to initialize the same organisation again
        let response = execute_initialize(session, organisation_id.clone());

        match response {
            DaemonResponse::Error(message) => {
                assert!(message.contains("already initialized"));
            }
            _ => panic!("Expected error response"),
        }
    }

    #[tokio::test]
    async fn test_rotate_organisation_key() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-rotate".to_string();

        // Initialize the organisation first so rotation has a baseline
        let response = execute_initialize(session, organisation_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // Rotate and expect the new version 2 in the response
        let response = execute_rotate(session, organisation_id.clone());

        match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganisationKeyVersion {
                        organisation_id: returned_organisation_id,
                        version,
                    }),
            } => {
                assert_eq!(returned_organisation_id, organisation_id);
                assert_eq!(version, 2);
            }
            other => panic!(
                "Expected OrganisationKeyVersion response, got: {:?}",
                other
            ),
        }
    }

    #[tokio::test]
    async fn test_rotate_organisation_key_twice() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-rotate-twice".to_string();

        // Initialize and then rotate twice in a row
        let response = execute_initialize(session, organisation_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        let response = execute_rotate(session, organisation_id.clone());
        match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganisationKeyVersion {
                        version, ..
                    }),
            } => assert_eq!(version, 2),
            other => {
                panic!("Expected version 2 on first rotation, got: {:?}", other)
            }
        }

        let response = execute_rotate(session, organisation_id.clone());
        match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganisationKeyVersion {
                        version, ..
                    }),
            } => assert_eq!(version, 3),
            other => panic!(
                "Expected version 3 on second rotation, got: {:?}",
                other
            ),
        }

        // List should report all three versions in order
        let response = execute_list(session, Some(organisation_id.clone()));
        match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganisationKeyListings(listings)),
            } => {
                assert_eq!(listings.len(), 1);
                let versions: Vec<u32> = listings[0]
                    .versions
                    .iter()
                    .map(|version_info| version_info.version)
                    .collect();
                assert_eq!(versions, vec![1, 2, 3]);
            }
            other => {
                panic!("Expected listing with three versions, got: {:?}", other)
            }
        }
    }

    #[tokio::test]
    async fn test_rotate_uninitialised_organisation() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id =
            "test-organisation-rotate-uninitialised".to_string();

        // Rotate before any initialize
        let response = execute_rotate(session, organisation_id.clone());

        match response {
            DaemonResponse::Error(message) => {
                assert!(
                    message.contains("is not initialized"),
                    "Expected error to mention 'is not initialized', got: {message}"
                );
            }
            other => panic!("Expected error response, got: {:?}", other),
        }

        // No key should have been created in the HSM
        let key_manager = HsmKeyManager::new(session);
        let private_keys = key_manager
            .filter_keys(
                ObjectClass::PRIVATE_KEY,
                &KeyLabel::organisation_label(&organisation_id),
            )
            .unwrap();
        assert!(
            private_keys.is_empty(),
            "Failed rotation should not create any private key, but found {} key(s)",
            private_keys.len()
        );

        let public_keys = key_manager
            .filter_keys(
                ObjectClass::PUBLIC_KEY,
                &KeyLabel::organisation_label(&organisation_id),
            )
            .unwrap();
        assert!(
            public_keys.is_empty(),
            "Failed rotation should not create any public key, but found {} key(s)",
            public_keys.len()
        );
    }

    #[tokio::test]
    async fn test_export_rotated_public_key_differs_from_initial() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-rotate-export".to_string();

        let response = execute_initialize(session, organisation_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        let response = execute_rotate(session, organisation_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // Export version 1 and version 2 and confirm the PEMs differ
        let response =
            execute_export(session, organisation_id.clone(), 1, None);
        let pem_version_one = match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganisationPublicKey(public_key)),
            } => {
                assert_eq!(public_key.version, 1);
                public_key.public_key_pem
            }
            other => panic!(
                "Expected exported public key for version 1, got: {:?}",
                other
            ),
        };

        let response =
            execute_export(session, organisation_id.clone(), 2, None);
        let pem_version_two = match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganisationPublicKey(public_key)),
            } => {
                assert_eq!(public_key.version, 2);
                public_key.public_key_pem
            }
            other => panic!(
                "Expected exported public key for version 2, got: {:?}",
                other
            ),
        };

        assert_ne!(
            pem_version_one, pem_version_two,
            "Rotated key version 2 must differ from initial version 1"
        );
    }

    #[tokio::test]
    async fn test_recovery_bundle_from_earlier_version_still_unwraps() {
        use crate::commands::recovery::{execute_generate, execute_unwrap};
        use puavo_ipc::RECOVERY_KEY_DATA_VERSION;
        use std::io::Write;
        use tempfile::NamedTempFile;

        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-rotate-unwrap".to_string();
        let serial_number = "test-serial-rotate-unwrap".to_string();
        let recovery_key = b"test-recovery-key-rotate".to_vec();

        // Initialize then generate a bundle against version 1
        let response = execute_initialize(session, organisation_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        let mut recovery_key_file = NamedTempFile::new().unwrap();
        recovery_key_file.write_all(&recovery_key).unwrap();

        let response = execute_generate(
            session,
            None,
            organisation_id.clone(),
            vec![serial_number.clone()],
            vec![recovery_key_file.path().to_path_buf()],
        );
        let recovery_bundle = match response {
            DaemonResponse::Success {
                data: Some(DaemonResponseData::RecoveryBundles(bundles)),
            } => {
                assert_eq!(bundles.len(), 1);
                assert_eq!(bundles[0].organisation_key_version, 1);
                bundles[0].clone()
            }
            other => {
                panic!("Expected RecoveryBundles response, got: {:?}", other)
            }
        };

        // Rotate to version 2 and check the older bundle still unwraps
        let response = execute_rotate(session, organisation_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        let mut recovery_bundle_file = NamedTempFile::new().unwrap();
        let serialized_bundle =
            serde_json::to_string(&recovery_bundle).unwrap();
        recovery_bundle_file.write_all(serialized_bundle.as_bytes()).unwrap();

        let response = execute_unwrap(
            session,
            None,
            vec![recovery_bundle_file.path().to_path_buf()],
        );

        match response {
            DaemonResponse::Success {
                data: Some(DaemonResponseData::RecoveryKeyDatas(key_datas)),
            } => {
                assert_eq!(key_datas.len(), 1);
                let key_data = &key_datas[0];
                assert_eq!(key_data.serial_number, serial_number);
                assert_eq!(key_data.organisation_id, organisation_id);
                assert_eq!(*key_data.recovery_key.0, recovery_key);
                assert_eq!(key_data.version, RECOVERY_KEY_DATA_VERSION);
            }
            other => {
                panic!("Expected RecoveryKeyDatas response, got: {:?}", other)
            }
        }
    }

    #[tokio::test]
    async fn test_export_organisation_public_key() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-export".to_string();

        // First initialize the organisation key
        let response = execute_initialize(session, organisation_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // Now export the public key
        let response =
            execute_export(session, organisation_id.clone(), 1, None);

        match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganisationPublicKey(public_key_data)),
            } => {
                assert_eq!(public_key_data.organisation_id, organisation_id);
                assert_eq!(public_key_data.version, 1);
                assert!(
                    public_key_data
                        .public_key_pem
                        .starts_with("-----BEGIN RSA PUBLIC KEY-----")
                );
            }
            _ => panic!("Expected success response with data"),
        }
    }

    #[tokio::test]
    async fn test_list_organisation_keys() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id_target = "test-organisation-list".to_string();
        let organisation_id_other = "test-organisation-list-other".to_string();

        // Initialize two organisation keys
        let response =
            execute_initialize(session, organisation_id_target.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        let response =
            execute_initialize(session, organisation_id_other.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // List only the target organisation keys
        let response =
            execute_list(session, Some(organisation_id_target.clone()));

        match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganisationKeyListings(listings)),
            } => {
                assert_eq!(listings.len(), 1);
                assert_eq!(listings[0].organisation_id, organisation_id_target);
                assert_eq!(listings[0].versions.len(), 1);
                assert_eq!(listings[0].versions[0].version, 1);
                assert!(!listings[0].versions[0].fingerprint.is_empty());
            }
            _ => panic!("Expected success response with data"),
        }
    }

    #[tokio::test]
    async fn test_list_all_organisation_keys() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id_first = "test-organisation-list-all-1".to_string();
        let organisation_id_second = "test-organisation-list-all-2".to_string();

        // Initialize two organisation keys
        let response =
            execute_initialize(session, organisation_id_first.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        let response =
            execute_initialize(session, organisation_id_second.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // List all organisation keys
        let response = execute_list(session, None);

        match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganisationKeyListings(listings)),
            } => {
                assert!(listings.len() >= 2);

                // Find both organisations in the listings
                let first_listing = listings.iter().find(|listing| {
                    listing.organisation_id == organisation_id_first
                });
                let second_listing = listings.iter().find(|listing| {
                    listing.organisation_id == organisation_id_second
                });

                assert!(first_listing.is_some());
                assert!(second_listing.is_some());

                // Verify the structure of both listings
                let first_listing = first_listing.unwrap();
                assert_eq!(first_listing.versions.len(), 1);
                assert_eq!(first_listing.versions[0].version, 1);
                assert!(!first_listing.versions[0].fingerprint.is_empty());

                let second_listing = second_listing.unwrap();
                assert_eq!(second_listing.versions.len(), 1);
                assert_eq!(second_listing.versions[0].version, 1);
                assert!(!second_listing.versions[0].fingerprint.is_empty());
            }
            _ => panic!("Expected success response with data"),
        }
    }

    #[tokio::test]
    async fn test_list_non_existent_organisation_keys() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id_existing = "test-organisation-existing".to_string();

        // Initialize an organisation key
        let response =
            execute_initialize(session, organisation_id_existing.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        let organisation_id_non_existent =
            "test-organisation-non-existent".to_string();

        // Attempt to list keys of a non-existent organisation
        let response =
            execute_list(session, Some(organisation_id_non_existent));

        match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganisationKeyListings(listings)),
            } => {
                assert!(listings.is_empty());
            }
            _ => panic!("Expected success response with data"),
        }
    }
}

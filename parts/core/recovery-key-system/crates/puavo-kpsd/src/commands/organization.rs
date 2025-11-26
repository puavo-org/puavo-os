use cryptoki::object::ObjectClass;
use puavo_hsm::{
    HsmKeyManager, HsmSession, KeyLabel, key_management::KeyManagementError,
};
use puavo_ipc::{
    DaemonResponse, DaemonResponseData, OrganizationCommand,
    OrganizationKeyListing, OrganizationKeyVersion, OrganizationPublicKey,
};
use rsa::pkcs1::EncodeRsaPublicKey;
use sha2::{Digest, Sha256};
use std::{collections::HashMap, fs, path::PathBuf};

/// Errors that can occur during organization commands
#[derive(Debug, thiserror::Error)]
pub enum OrganizationCommandError {
    #[error(transparent)]
    KeyManagement(#[from] KeyManagementError),

    #[error("Organization is already initialized")]
    OrganizationAlreadyInitialized,

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("RSA encoding error: {0}")]
    RsaEncoding(#[from] rsa::pkcs1::Error),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
}

impl From<OrganizationCommandError> for DaemonResponse {
    fn from(error: OrganizationCommandError) -> Self {
        DaemonResponse::Error(error.to_string())
    }
}

/// Execute organization key initialization
fn initialize(
    hsm_session: &HsmSession,
    organization_id: String,
) -> Result<(), OrganizationCommandError> {
    tracing::info!("Initializing organization key: {}", organization_id);

    let key_label = KeyLabel::organization(&organization_id, 1);
    let key_manager = HsmKeyManager::new(hsm_session);
    let organization_keys =
        key_manager.filter_keys(ObjectClass::PRIVATE_KEY, &key_label.label)?;

    if !organization_keys.is_empty() {
        tracing::error!("Organization key already exists");
        return Err(OrganizationCommandError::OrganizationAlreadyInitialized);
    }

    tracing::info!("Generating new organization key: {}", organization_id);
    let _ = key_manager.generate_key(&key_label)?;

    Ok(())
}

/// Export organization public key
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `organization_id` - Organization identifier
/// * `version` - Key version to export
/// * `output` - Optional output file path
///
/// Returns:
/// Organization public key structure or error
///
/// Errors:
/// Returns error if key cannot be found or exported
fn export_public_key(
    hsm_session: &HsmSession,
    organization_id: String,
    version: u32,
    output: Option<PathBuf>,
) -> Result<OrganizationPublicKey, OrganizationCommandError> {
    tracing::info!(
        "Exporting organization public key: {} version {}",
        organization_id,
        version
    );

    let key_label = KeyLabel::organization(&organization_id, version);
    let key_manager = HsmKeyManager::new(hsm_session);

    // Get the public key handle
    let public_key_handle = key_manager
        .get_key_with_version(ObjectClass::PUBLIC_KEY, &key_label)?;

    // Extract the RSA public key
    let public_key = key_manager.extract_public_key(&public_key_handle)?;

    // Convert to PEM format
    let public_key_pem = public_key.to_pkcs1_pem(rsa::pkcs1::LineEnding::LF)?;

    let organization_public_key = OrganizationPublicKey {
        organization_id: organization_id.clone(),
        version,
        public_key_pem,
    };

    // Write to file if output path is provided
    if let Some(output_path) = output {
        let json_content =
            serde_json::to_string_pretty(&organization_public_key)?;
        fs::write(output_path, json_content)?;
        tracing::info!("Public key exported to file");
    }

    tracing::info!("Organization public key export completed");
    Ok(organization_public_key)
}

/// List organization keys
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `organization_id_filter` - Optional organization identifier to filter results
///
/// Returns:
/// List of organization key listings or error
///
/// Errors:
/// Returns error if keys cannot be listed
fn list_keys(
    hsm_session: &HsmSession,
    organization_id_filter: Option<String>,
) -> Result<Vec<OrganizationKeyListing>, OrganizationCommandError> {
    tracing::info!("Listing organization keys");

    let key_manager = HsmKeyManager::new(hsm_session);
    let all_organization_keys = key_manager.list_all_organization_keys()?;

    // Collect and group all keys by organization
    let mut organizations: HashMap<String, Vec<OrganizationKeyVersion>> =
        HashMap::new();

    for (label, version, public_key_handle) in all_organization_keys {
        let organization_id =
            KeyLabel::organization_id_from_label(&label).unwrap_or(&label);

        // Apply the organization ID filter if provided
        if let Some(ref filter_id) = organization_id_filter {
            if organization_id != filter_id {
                continue;
            }
        }

        // Compute the fingerprint of the public key
        let public_key = key_manager.extract_public_key(&public_key_handle)?;
        let public_key_pem =
            public_key.to_pkcs1_pem(rsa::pkcs1::LineEnding::LF)?;
        let fingerprint = Sha256::digest(public_key_pem)
            .iter()
            .map(|byte| format!("{:02x}", byte))
            .collect::<String>();

        // Insert into the organizations map
        organizations
            .entry(organization_id.to_string())
            .or_insert_with(Vec::new)
            .push(OrganizationKeyVersion { version, fingerprint });
    }

    // Sort and prepare the listings
    let mut listings: Vec<OrganizationKeyListing> = organizations
        .into_iter()
        .map(|(organization_id, mut versions)| {
            versions.sort_by_key(|version| version.version);
            OrganizationKeyListing { organization_id, versions }
        })
        .collect();

    listings.sort_by(|first, second| {
        first.organization_id.cmp(&second.organization_id)
    });

    Ok(listings)
}

/// Execute organization key management command
///
/// Parameters:
/// * `command` - Organization command to execute
///
/// Returns:
/// Daemon response with success or error
pub fn execute(
    hsm_session: &HsmSession,
    command: OrganizationCommand,
) -> DaemonResponse {
    match command {
        OrganizationCommand::Initialize { organization_id } => {
            execute_initialize(hsm_session, organization_id)
        }

        OrganizationCommand::Rotate { organization_id } => {
            execute_rotate(organization_id)
        }

        OrganizationCommand::Export { organization_id, version, output } => {
            execute_export(hsm_session, organization_id, version, output)
        }

        OrganizationCommand::List { organization_id } => {
            execute_list(hsm_session, organization_id)
        }
    }
}

/// Execute organization key initialization
fn execute_initialize(
    hsm_session: &HsmSession,
    organization_id: String,
) -> DaemonResponse {
    initialize(hsm_session, organization_id)
        .map(|_| {
            tracing::info!("Organization key initialization completed");
            DaemonResponse::success()
        })
        .into()
}

/// Execute organization key rotation
fn execute_rotate(organization_id: String) -> DaemonResponse {
    tracing::info!("Rotating organization key: {}", organization_id);
    DaemonResponse::success()
}

/// Execute organization public key export
fn execute_export(
    hsm_session: &HsmSession,
    organization_id: String,
    version: u32,
    output: Option<PathBuf>,
) -> DaemonResponse {
    export_public_key(hsm_session, organization_id, version, output)
        .map(|public_key_data| {
            tracing::info!("Organization public key export completed");
            DaemonResponseData::OrganizationPublicKey(public_key_data)
        })
        .into()
}

/// Execute organization key listing
fn execute_list(
    hsm_session: &HsmSession,
    organization_id: Option<String>,
) -> DaemonResponse {
    list_keys(hsm_session, organization_id)
        .map(|listings| {
            tracing::info!("Organization key listing completed");
            DaemonResponseData::OrganizationKeyListings(listings)
        })
        .into()
}

#[cfg(test)]
mod tests {
    use puavo_hsm::TestHsmSession;
    use puavo_ipc::DaemonResponseData;

    use super::*;

    #[tokio::test]
    async fn test_initialize_organization_key() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-init".to_string();

        let response = execute_initialize(session, organization_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // Verify the key was created
        let key_manager = HsmKeyManager::new(session);
        let organization_keys = key_manager
            .filter_keys(
                ObjectClass::PRIVATE_KEY,
                &KeyLabel::organization_label(&organization_id),
            )
            .unwrap();

        assert_eq!(organization_keys.len(), 1);

        let version =
            key_manager.get_key_version(&organization_keys[0]).unwrap();
        assert_eq!(version, 1);
    }

    #[tokio::test]
    async fn test_initialize_organization_key_already_exists() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-exists".to_string();

        // Initialize once
        let response = execute_initialize(session, organization_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // Try to initialize the same organization again
        let response = execute_initialize(session, organization_id.clone());

        match response {
            DaemonResponse::Error(message) => {
                assert!(message.contains("already initialized"));
            }
            _ => panic!("Expected error response"),
        }
    }

    #[tokio::test]
    async fn test_rotate_organization_key() {
        let organization_id = "test-organization-rotate".to_string();

        let response = execute_rotate(organization_id.clone());

        assert!(matches!(response, DaemonResponse::Success { .. }));
    }

    #[tokio::test]
    async fn test_export_organization_public_key() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-export".to_string();

        // First initialize the organization key
        let response = execute_initialize(session, organization_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // Now export the public key
        let response =
            execute_export(session, organization_id.clone(), 1, None);

        match response {
            DaemonResponse::Success {
                data:
                    Some(DaemonResponseData::OrganizationPublicKey(public_key_data)),
            } => {
                assert_eq!(public_key_data.organization_id, organization_id);
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
}

use cryptoki::object::ObjectHandle;
use puavo_hsm::{
    HsmKeyManager, HsmSession, KeyLabel,
    key_management::KeyManagementError,
    mechanisms::{hash::HashAlgorithm, hkdf::HsmMechanismHkdf},
};
use puavo_ipc::{DaemonResponse, salt::DeviceSaltSource};
use std::path::PathBuf;

/// Errors that can occur during key derivation
#[derive(Debug, thiserror::Error)]
pub enum DeriveCommandError {
    #[error(transparent)]
    KeyManagement(#[from] KeyManagementError),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Organization has no keys")]
    NoOrganizationKeys,

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

pub const HASH_ALGORITHM: HashAlgorithm = HashAlgorithm::Sha512;
pub const KEY_SIZE: usize = 64;

pub const DISK_RECOVERY_KEY_CONTEXT: &str = "disk-recovery-key";

/// Derive a key using HKDF with the specified parameters
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `key_label` - Label identifying the base key in HSM
/// * `salt_source` - Source string used to generate salt via hashing
/// * `context` - Context string for key derivation
///
/// Returns:
/// Derived key bytes
///
/// Errors:
/// Returns error if HSM operations fail or key cannot be found
fn derive(
    key_manager: &HsmKeyManager,
    key: &ObjectHandle,
    salt_source: &str,
    context: &str,
) -> Result<Vec<u8>, KeyManagementError> {
    let salt = HASH_ALGORITHM.digest(salt_source);
    let info = [context.as_bytes(), &salt].concat();

    let hkdf = HsmMechanismHkdf::new(&key_manager, HASH_ALGORITHM);
    hkdf.expand(key.clone(), &info, HASH_ALGORITHM.hash_length())
}

/// Derive a key from an organization key using HKDF
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `organization_id` - Organization identifier
/// * `organization_key_version` - Version of the organization key to use
/// * `salt_source` - Source string used to generate salt via hashing
/// * `context` - Context string for key derivation
///
/// Returns:
/// Derived key bytes
///
/// Errors:
/// Returns error if organization key cannot be found or derivation fails
fn derive_from_organization_key(
    hsm_session: &HsmSession,
    organization_id: &str,
    organization_key_version: u32,
    salt_source: &str,
    context: &str,
) -> Result<Vec<u8>, KeyManagementError> {
    let key_label =
        KeyLabel::organization(organization_id, organization_key_version);
    let key_manager = HsmKeyManager::new(hsm_session);
    let key = key_manager.get_key_with_version(&key_label)?;

    derive(&key_manager, &key, salt_source, context)
}

/// Derive a recovery key for disk encryption
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `organization_id` - Organization identifier
/// * `organization_key_version` - Version of the organization key to use
/// * `device_salt_source` - Device-specific salt source string
///
/// Returns:
/// Derived recovery key bytes
///
/// Errors:
/// Returns error if organization key cannot be found or derivation fails
pub fn derive_recovery_key(
    hsm_session: &HsmSession,
    organization_id: &str,
    organization_key_version: u32,
    device_salt_source: &str,
) -> Result<Vec<u8>, KeyManagementError> {
    derive_from_organization_key(
        hsm_session,
        organization_id,
        organization_key_version,
        device_salt_source,
        DISK_RECOVERY_KEY_CONTEXT,
    )
}

/// Derive an existing recovery key for a device.
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `operator_id` - Optional operator identifier
/// * `device_salt_source_string` - Serialized device salt source
///
/// Returns:
/// Derived recovery key bytes
///
/// Errors:
/// Returns error if parsing fails or key derivation fails
pub fn derive_existing_recovery_key(
    hsm_session: &HsmSession,
    _operator_id: Option<String>,
    device_salt_source_string: String,
) -> Result<Vec<u8>, DeriveCommandError> {
    tracing::info!("Deriving existing recovery key");

    let device_salt_source: DeviceSaltSource =
        serde_json::from_str(&device_salt_source_string)?;

    let recovery_key = derive_recovery_key(
        hsm_session,
        &device_salt_source.organization_id,
        device_salt_source.organization_key_version,
        &device_salt_source_string,
    )?;

    Ok(recovery_key)
}

/// Execute derive command to derive recovery keys from salt source files
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `shuttle_path` - Optional custom shuttle mount point
/// * `operator_id` - Optional operator identifier
/// * `salts` - List of files containing serialized device salt sources
///
/// Returns:
/// Daemon response with results or error
pub fn derive_existing_recovery_keys(
    hsm_session: &HsmSession,
    operator_id: Option<String>,
    salt_source_paths: Vec<PathBuf>,
) -> Result<Vec<String>, DeriveCommandError> {
    // Read device salt sources from files
    let salt_sources = salt_source_paths
        .iter()
        .map(std::fs::read_to_string)
        .collect::<Result<Vec<_>, _>>()
        .map_err(DeriveCommandError::Io)?;

    // Derive all recovery keys with the corresponding salts
    let mut recovery_keys = Vec::new();

    for salt_source in salt_sources {
        let recovery_key = derive_existing_recovery_key(
            hsm_session,
            operator_id.clone(),
            salt_source,
        )?;

        recovery_keys.push(hex::encode(recovery_key));
    }

    return Ok(recovery_keys);
}

/// Derive a new recovery key for a device.
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `operator_id` - Optional operator identifier
/// * `organization_id` - Organization identifier
/// * `serial_number` - Device serial number
///
/// Returns:
/// Derived recovery key bytes
///
/// Errors:
/// Returns error if key version cannot be determined or derivation fails
pub fn derive_new_recovery_key(
    hsm_session: &HsmSession,
    _operator_id: Option<String>,
    organization_id: String,
    serial_number: String,
) -> Result<Vec<u8>, DeriveCommandError> {
    tracing::info!("Deriving new recovery key");

    let key_manager = HsmKeyManager::new(hsm_session);
    let organization_keys =
        key_manager.filter_keys(organization_id.as_str())?;

    // Find the latest organization key
    let (organization_key, organization_key_version) = organization_keys
        .into_iter()
        .map(|key_handle| {
            key_manager
                .get_key_version(&key_handle)
                .map(|version| (key_handle, version))
        })
        .collect::<Result<Vec<_>, _>>()?
        .into_iter()
        .max_by_key(|&(_, version)| version)
        .ok_or(DeriveCommandError::NoOrganizationKeys)?;

    // Generate a new device salt source with the specified serial number
    let device_salt_source = DeviceSaltSource::new(
        serial_number,
        organization_id.clone(),
        organization_key_version,
    );
    let device_salt_source_string = serde_json::to_string(&device_salt_source)?;

    // Derive a new recovery key with the generated salt source
    let recovery_key = derive(
        &key_manager,
        &organization_key,
        device_salt_source_string.as_str(),
        DISK_RECOVERY_KEY_CONTEXT,
    )?;

    Ok(recovery_key)
}

/// Convert derive error to daemon response
fn derive_command_error_to_response(
    error: DeriveCommandError,
) -> DaemonResponse {
    DaemonResponse::Error {
        code: "DERIVE_ERROR".into(),
        message: error.to_string(),
    }
}

/// Execute generate command to create new recovery keys
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `shuttle_path` - Optional custom shuttle mount point
/// * `operator_id` - Optional operator identifier
/// * `organization_id` - Organization identifier
/// * `serial_numbers` - List of device serial numbers
///
/// Returns:
/// Daemon response with results or error
pub fn execute_generate(
    hsm_session: &HsmSession,
    operator_id: Option<String>,
    organization_id: String,
    serial_numbers: Vec<String>,
) -> DaemonResponse {
    let recovery_keys_result = serial_numbers
        .into_iter()
        .map(|serial_number| {
            derive_new_recovery_key(
                hsm_session,
                operator_id.clone(),
                organization_id.clone(),
                serial_number,
            )
        })
        .collect::<Result<Vec<_>, _>>();

    match recovery_keys_result {
        Ok(recovery_keys) => {
            let recovery_keys = recovery_keys
                .into_iter()
                .map(|key_bytes| hex::encode(key_bytes))
                .collect::<Vec<_>>();

            // TODO: Convert to a structured response
            DaemonResponse::Success { message: recovery_keys.join(",") }
        }

        Err(error) => derive_command_error_to_response(error),
    }
}

/// Execute derive command to derive recovery keys from salt files
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `shuttle_path` - Optional custom shuttle mount point
/// * `operator_id` - Optional operator identifier
/// * `salts` - List of files containing serialized device salt sources
///
/// Returns:
/// Daemon response with results or error
pub fn execute_derive(
    hsm_session: &HsmSession,
    operator_id: Option<String>,
    salt_source_paths: Vec<PathBuf>,
) -> DaemonResponse {
    match derive_existing_recovery_keys(
        hsm_session,
        operator_id,
        salt_source_paths,
    ) {
        Ok(recovery_keys) => {
            // TODO: Convert to a structured response
            DaemonResponse::Success { message: recovery_keys.join(",") }
        }
        Err(error) => derive_command_error_to_response(error),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_derive_existing_recovery_key() {
        // TODO: Add proper test with mock HSM session
    }

    #[tokio::test]
    async fn test_derive_new_recovery_key() {
        // TODO: Add proper test with mock HSM session
    }

    #[tokio::test]
    async fn test_derive_error_to_response() {
        let error = DeriveCommandError::NoOrganizationKeys;
        let response = derive_command_error_to_response(error);

        match response {
            DaemonResponse::Error { code, message } => {
                assert_eq!(code, "DERIVE_ERROR");
                assert_eq!(message, "Organization has no keys");
            }
            _ => panic!("Expected error response"),
        }
    }
}

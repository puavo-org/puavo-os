use cryptoki::{
    mechanism::Mechanism,
    object::{ObjectClass, ObjectHandle},
};
use puavo_hsm::{
    HsmKeyManager, HsmSession, KeyLabel, key_management::KeyManagementError,
};
use puavo_ipc::{
    DaemonResponse, RECOVERY_KEY_DATA_VERSION, RecoveryBundle, RecoveryKeyData,
};
use rsa::{Pkcs1v15Encrypt, RsaPublicKey};
use std::{fs, path::PathBuf};

/// Errors that can occur during recovery key operations
#[derive(Debug, thiserror::Error)]
pub enum RecoveryKeyError {
    #[error(transparent)]
    KeyManagement(#[from] KeyManagementError),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Organization has no keys")]
    NoOrganizationKeys,

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Hex decoding error: {0}")]
    HexDecode(#[from] hex::FromHexError),
}

/// Create recovery key data structure from components
///
/// Parameters:
/// * `serial_number` - Device serial number
/// * `organization_id` - Organization identifier
/// * `recovery_key` - Raw recovery key bytes
///
/// Returns:
/// Recovery key data structure ready for serialization
fn create_recovery_key_data(
    serial_number: String,
    organization_id: String,
    recovery_key: Vec<u8>,
) -> RecoveryKeyData {
    RecoveryKeyData {
        serial_number,
        organization_id,
        recovery_key,
        version: RECOVERY_KEY_DATA_VERSION,
    }
}

/// Encrypt recovery key data with organization public key
///
/// Parameters:
/// * `public_key` - Public key for encryption
/// * `serial_number` - Device serial number
/// * `organization_id` - Organization identifier
/// * `recovery_key` - Raw recovery key bytes
///
/// Returns:
/// Hex-encoded encrypted recovery key data
///
/// Errors:
/// Returns error if serialization or encryption fails
pub fn encrypt_recovery_key_data(
    public_key: &RsaPublicKey,
    serial_number: String,
    organization_id: String,
    recovery_key: Vec<u8>,
) -> Result<String, RecoveryKeyError> {
    let key_data =
        create_recovery_key_data(serial_number, organization_id, recovery_key);
    let serialized_key_data = serde_json::to_vec(&key_data)?;
    let encrypted_key_data_bytes = encrypt(public_key, &serialized_key_data)?;
    Ok(hex::encode(&encrypted_key_data_bytes))
}

/// Encrypt data using RSA with software-based encryption
///
/// Parameters:
/// * `public_key` - Public key for encryption
/// * `key_data` - Data to encrypt
///
/// Returns:
/// Encrypted data
///
/// Errors:
/// Returns error if encryption fails
fn encrypt(
    public_key: &RsaPublicKey,
    key_data: &[u8],
) -> Result<Vec<u8>, KeyManagementError> {
    // TODO: Investigate support for OAEP padding
    let padding = Pkcs1v15Encrypt;
    let mut random_number_generator = rand::thread_rng();
    let encrypted_key_data =
        public_key.encrypt(&mut random_number_generator, padding, key_data)?;

    Ok(encrypted_key_data)
}

/// Decrypt data using RSA with HSM private key
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `private_key_handle` - Handle to private key in HSM
/// * `encrypted_key_data` - Key data to decrypt
///
/// Returns:
/// Decrypted key data
///
/// Errors:
/// Returns error if decryption fails
fn decrypt(
    hsm_session: &HsmSession,
    private_key_handle: &ObjectHandle,
    encrypted_key_data: &[u8],
) -> Result<Vec<u8>, KeyManagementError> {
    let session = hsm_session.session();

    let key_data = session.decrypt(
        &Mechanism::RsaPkcs,
        *private_key_handle,
        encrypted_key_data,
    )?;

    Ok(key_data)
}

fn decrypt_with_organization_key(
    hsm_session: &HsmSession,
    organization_id: &str,
    organization_key_version: u32,
    encrypted_key_data: &[u8],
) -> Result<Vec<u8>, KeyManagementError> {
    tracing::info!("Decrypting recovery key data");

    let key_label =
        KeyLabel::organization(organization_id, organization_key_version);
    let key_manager = HsmKeyManager::new(hsm_session);
    let key = key_manager
        .get_key_with_version(ObjectClass::PRIVATE_KEY, &key_label)?;

    decrypt(hsm_session, &key, encrypted_key_data)
}

/// Encrypt the specified recovery key for a device
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `organization_id` - Organization identifier
/// * `serial_number` - Device serial number
/// * `recovery_key` - Raw recovery key bytes
///
/// Returns:
/// A recovery bundle with encrypted recovery key data
///
/// Errors:
/// Returns error if key version cannot be determined or encryption fails
fn create_recovery_bundle(
    hsm_session: &HsmSession,
    organization_id: String,
    serial_number: String,
    recovery_key: Vec<u8>,
) -> Result<RecoveryBundle, RecoveryKeyError> {
    tracing::info!(
        "Generating recovery key for device {} in organization {}",
        serial_number,
        organization_id
    );

    let key_manager = HsmKeyManager::new(hsm_session);

    // Find the latest organization public key and its version
    let organization_key_label =
        KeyLabel::organization_label(organization_id.as_str());
    let (organization_key, organization_key_version) = key_manager
        .get_latest_key(ObjectClass::PUBLIC_KEY, &organization_key_label)?
        .ok_or(RecoveryKeyError::NoOrganizationKeys)?;

    // Load the organization public key
    let key_manager = HsmKeyManager::new(hsm_session);
    let public_key = key_manager.extract_public_key(&organization_key)?;

    // Encrypt the recovery key and related information
    let encrypted_key_data = encrypt_recovery_key_data(
        &public_key,
        serial_number.clone(),
        organization_id.clone(),
        recovery_key,
    )?;

    Ok(RecoveryBundle {
        serial_number,
        organization_id,
        organization_key_version,
        encrypted_key_data,
    })
}

/// Unwrap encrypted recovery key data
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `recovery_bundle` - Recovery bundle
///
/// Returns:
/// Decrypted recovery key data
///
/// Errors:
/// Returns error if decryption fails or data is malformed
fn unwrap_recovery_key(
    hsm_session: &HsmSession,
    recovery_bundle: RecoveryBundle,
) -> Result<RecoveryKeyData, RecoveryKeyError> {
    tracing::info!("Unwrapping encrypted recovery key data");

    // Convert the hex-encoded encrypted key data to bytes
    let encrypted_key_data_bytes =
        hex::decode(&recovery_bundle.encrypted_key_data)?;
    // Decrypt the recovery key data
    let serialized_recovery_key_data = decrypt_with_organization_key(
        hsm_session,
        &recovery_bundle.organization_id,
        recovery_bundle.organization_key_version,
        &encrypted_key_data_bytes,
    )?;
    // Deserialize the recovery key data
    let recovery_key_data: RecoveryKeyData =
        serde_json::from_slice(&serialized_recovery_key_data)?;
    Ok(recovery_key_data)
}

/// Read and parse recovery bundle from file
///
/// Parameters:
/// * `path` - Path to recovery bundle file
///
/// Returns:
/// Parsed recovery bundle
///
/// Errors:
/// Returns error if file cannot be read or parsed
fn read_recovery_bundle(
    path: &PathBuf,
) -> Result<RecoveryBundle, RecoveryKeyError> {
    let serialized_recovery_bundle = std::fs::read_to_string(path)?;
    let recovery_bundle: RecoveryBundle =
        serde_json::from_str(&serialized_recovery_bundle)?;
    Ok(recovery_bundle)
}

/// Format recovery key data for display
///
/// Parameters:
/// * `recovery_key_data` - Recovery key data to format
///
/// Returns:
/// Formatted string with device, organization, and key information
fn format_recovery_key_output(recovery_key_data: &RecoveryKeyData) -> String {
    format!("{}", String::from_utf8_lossy(&recovery_key_data.recovery_key))
}

/// Convert recovery key error to daemon response
fn recovery_key_error_to_response(error: RecoveryKeyError) -> DaemonResponse {
    DaemonResponse::Error {
        code: "RECOVERY_KEY_ERROR".into(),
        message: error.to_string(),
    }
}

/// Execute generate command to create new recovery keys
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `operator_id` - Optional operator identifier
/// * `organization_id` - Organization identifier
/// * `serial_numbers` - List of device serial numbers
/// * `recovery_key_files` - List of recovery key files (one per device)
///
/// Returns:
/// Daemon response with encrypted recovery key data (hex-encoded)
pub fn execute_generate(
    hsm_session: &HsmSession,
    _operator_id: Option<String>,
    organization_id: String,
    serial_numbers: Vec<String>,
    recovery_key_files: Vec<PathBuf>,
) -> DaemonResponse {
    if serial_numbers.len() != recovery_key_files.len() {
        return DaemonResponse::Error {
            code: "PARAMETER_MISMATCH".into(),
            message: "Number of serial numbers does not match number of recovery key files".into(),
        };
    }

    let recovery_keys_result: Result<Vec<_>, RecoveryKeyError> = serial_numbers
        .into_iter()
        .zip(recovery_key_files.iter())
        .map(|(serial_number, recovery_key_file)| {
            let recovery_key = fs::read(&recovery_key_file)?;
            // TODO(recovery-key-format): Validate recovery key format?

            let recovery_bundle = create_recovery_bundle(
                hsm_session,
                organization_id.clone(),
                serial_number,
                recovery_key,
            )?;

            Ok(serde_json::to_string(&recovery_bundle)?)
        })
        .collect();

    match recovery_keys_result {
        Ok(encrypted_recovery_keys) => {
            tracing::info!("Successfully generated recovery bundles");
            DaemonResponse::success_with_data(
                encrypted_recovery_keys.join("\n"),
            )
        }
        Err(error) => recovery_key_error_to_response(error),
    }
}

/// Execute unwrap command to decrypt recovery keys from encrypted files
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `operator_id` - Optional operator identifier
/// * `recovery_bundle_paths` - List of recovery bundle paths
///
/// Returns:
/// Daemon response with decrypted recovery key information
pub fn execute_unwrap(
    hsm_session: &HsmSession,
    _operator_id: Option<String>,
    recovery_bundle_paths: Vec<PathBuf>,
) -> DaemonResponse {
    let unwrap_result: Result<Vec<_>, RecoveryKeyError> = recovery_bundle_paths
        .iter()
        .map(|path| {
            let recovery_bundle = read_recovery_bundle(path)?;
            let recovery_key_data =
                unwrap_recovery_key(hsm_session, recovery_bundle)?;
            Ok(format_recovery_key_output(&recovery_key_data))
        })
        .collect();

    match unwrap_result {
        Ok(results) => {
            tracing::info!("Successfully unwrapped recovery bundles");
            DaemonResponse::success_with_data(results.join("\n"))
        }
        Err(error) => recovery_key_error_to_response(error),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_generate_recovery_key() {
        // TODO: Add proper test with mock HSM session
    }

    #[tokio::test]
    async fn test_unwrap_recovery_key() {
        // TODO: Add proper test with mock HSM session
    }

    #[tokio::test]
    async fn test_recovery_key_error_to_response() {
        let error = RecoveryKeyError::NoOrganizationKeys;
        let response = recovery_key_error_to_response(error);

        match response {
            DaemonResponse::Error { code, message } => {
                assert_eq!(code, "RECOVERY_KEY_ERROR");
                assert_eq!(message, "Organization has no keys");
            }
            _ => panic!("Expected error response"),
        }
    }
}

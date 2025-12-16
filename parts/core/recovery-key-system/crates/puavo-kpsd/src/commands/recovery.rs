use cryptoki::{
    mechanism::Mechanism,
    object::{ObjectClass, ObjectHandle},
};
use puavo_hsm::{
    HsmKeyManager, HsmSession, KeyLabel, key_management::KeyManagementError,
};
use puavo_ipc::{
    DaemonResponse, DaemonResponseData, RECOVERY_KEY_DATA_VERSION,
    RecoveryBundle, RecoveryKeyData,
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

    #[error(
        "Number of serial numbers does not match number of recovery key files"
    )]
    ParameterMismatch,
}

impl From<RecoveryKeyError> for DaemonResponse {
    fn from(error: RecoveryKeyError) -> Self {
        DaemonResponse::Error(error.to_string())
    }
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
        return RecoveryKeyError::ParameterMismatch.into();
    }

    let recovery_bundles_result: Result<Vec<_>, RecoveryKeyError> =
        serial_numbers
            .into_iter()
            .zip(recovery_key_files.iter())
            .map(|(serial_number, recovery_key_file)| {
                let recovery_key = fs::read(&recovery_key_file)?;
                // TODO(recovery-key-format): Validate recovery key format?

                return create_recovery_bundle(
                    hsm_session,
                    organization_id.clone(),
                    serial_number,
                    recovery_key,
                );
            })
            .collect();

    recovery_bundles_result
        .map(|recovery_bundles| {
            tracing::info!("Successfully generated recovery bundles");
            DaemonResponseData::RecoveryBundles(recovery_bundles)
        })
        .into()
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
    let recovery_key_datas_result: Result<Vec<_>, RecoveryKeyError> =
        recovery_bundle_paths
            .iter()
            .map(|path| {
                let recovery_bundle = read_recovery_bundle(path)?;
                return unwrap_recovery_key(hsm_session, recovery_bundle);
            })
            .collect();

    recovery_key_datas_result
        .map(|recovery_key_datas| {
            tracing::info!("Successfully unwrapped recovery bundles");
            DaemonResponseData::RecoveryKeyDatas(recovery_key_datas)
        })
        .into()
}

#[cfg(test)]
mod tests {
    use super::*;
    use puavo_hsm::TestHsmSession;
    use std::io::Write;
    use tempfile::NamedTempFile;

    /// Initialize organization key for testing
    ///
    /// Parameters:
    /// * `hsm_session` - Active HSM session for key operations
    /// * `organization_id` - Organization identifier
    ///
    /// Errors:
    /// Returns error if key generation fails
    fn initialize_organization_key_for_testing(
        hsm_session: &HsmSession,
        organization_id: &str,
    ) -> Result<(), KeyManagementError> {
        let key_label = KeyLabel::organization(organization_id, 1);
        let key_manager = HsmKeyManager::new(hsm_session);
        let _ = key_manager.generate_key(&key_label)?;
        Ok(())
    }

    /// Create a temporary file with recovery key data
    ///
    /// Parameters:
    /// * `recovery_key` - Recovery key bytes to write
    ///
    /// Returns:
    /// Temporary file containing the recovery key
    fn create_temporary_recovery_key_file(
        recovery_key: &[u8],
    ) -> NamedTempFile {
        let mut temporary_file =
            NamedTempFile::new().expect("Failed to create temporary file");
        temporary_file
            .write_all(recovery_key)
            .expect("Failed to write recovery key");
        temporary_file
    }

    /// Create a temporary file with recovery bundle data
    ///
    /// Parameters:
    /// * `recovery_bundle` - Recovery bundle to write
    ///
    /// Returns:
    /// Temporary file containing the recovery bundle
    fn create_temporary_recovery_bundle_file(
        recovery_bundle: &RecoveryBundle,
    ) -> NamedTempFile {
        let mut temporary_file =
            NamedTempFile::new().expect("Failed to create temporary file");
        let serialized_recovery_bundle = serde_json::to_string(recovery_bundle)
            .expect("Failed to serialize recovery bundle");
        temporary_file
            .write_all(serialized_recovery_bundle.as_bytes())
            .expect("Failed to write recovery bundle");
        temporary_file
    }

    #[tokio::test]
    async fn test_generate_recovery_bundle() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-generate".to_string();
        let serial_number = "test-serial-123".to_string();
        let recovery_key = b"test-recovery-key-data".to_vec();

        // Initialize organization key first
        initialize_organization_key_for_testing(session, &organization_id)
            .expect("Failed to initialize organization key");

        // Create temporary recovery key file
        let recovery_key_file =
            create_temporary_recovery_key_file(&recovery_key);

        // Generate recovery bundle
        let response = execute_generate(
            session,
            None,
            organization_id.clone(),
            vec![serial_number.clone()],
            vec![recovery_key_file.path().to_path_buf()],
        );

        match response {
            DaemonResponse::Success {
                data: Some(DaemonResponseData::RecoveryBundles(bundles)),
            } => {
                assert_eq!(bundles.len(), 1);
                let bundle = &bundles[0];
                assert_eq!(bundle.serial_number, serial_number);
                assert_eq!(bundle.organization_id, organization_id);
                assert_eq!(bundle.organization_key_version, 1);
                assert!(!bundle.encrypted_key_data.is_empty());
            }
            _ => panic!("Expected success response with recovery bundles"),
        }
    }

    #[tokio::test]
    async fn test_generate_multiple_recovery_bundles() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-generate-multiple".to_string();
        let serial_number_first = "test-serial-456".to_string();
        let serial_number_second = "test-serial-789".to_string();
        let recovery_key_first = b"test-recovery-key-first".to_vec();
        let recovery_key_second = b"test-recovery-key-second".to_vec();

        // Initialize organization key first
        initialize_organization_key_for_testing(session, &organization_id)
            .expect("Failed to initialize organization key");

        // Create temporary recovery key files
        let recovery_key_file_first =
            create_temporary_recovery_key_file(&recovery_key_first);
        let recovery_key_file_second =
            create_temporary_recovery_key_file(&recovery_key_second);

        // Generate recovery bundles
        let response = execute_generate(
            session,
            None,
            organization_id.clone(),
            vec![serial_number_first.clone(), serial_number_second.clone()],
            vec![
                recovery_key_file_first.path().to_path_buf(),
                recovery_key_file_second.path().to_path_buf(),
            ],
        );

        match response {
            DaemonResponse::Success {
                data: Some(DaemonResponseData::RecoveryBundles(bundles)),
            } => {
                assert_eq!(bundles.len(), 2);

                let bundle_first = &bundles[0];
                assert_eq!(bundle_first.serial_number, serial_number_first);
                assert_eq!(bundle_first.organization_id, organization_id);
                assert!(!bundle_first.encrypted_key_data.is_empty());

                let bundle_second = &bundles[1];
                assert_eq!(bundle_second.serial_number, serial_number_second);
                assert_eq!(bundle_second.organization_id, organization_id);
                assert!(!bundle_second.encrypted_key_data.is_empty());
            }
            _ => panic!("Expected success response with recovery bundles"),
        }
    }

    #[tokio::test]
    async fn test_generate_recovery_bundle_parameter_mismatch() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-mismatch".to_string();
        let serial_number = "test-serial-mismatch".to_string();

        // Try to generate with mismatched parameters
        let response = execute_generate(
            session,
            None,
            organization_id,
            vec![serial_number],
            vec![],
        );

        match response {
            DaemonResponse::Error(message) => {
                assert!(message.contains("does not match"));
            }
            _ => panic!("Expected error response"),
        }
    }

    #[tokio::test]
    async fn test_generate_recovery_bundle_no_organization_key() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-no-key".to_string();
        let serial_number = "test-serial-no-key".to_string();
        let recovery_key = b"test-recovery-key".to_vec();

        // Create temporary recovery key file
        let recovery_key_file =
            create_temporary_recovery_key_file(&recovery_key);

        // Try to generate without initializing organization key first
        let response = execute_generate(
            session,
            None,
            organization_id,
            vec![serial_number],
            vec![recovery_key_file.path().to_path_buf()],
        );

        match response {
            DaemonResponse::Error(message) => {
                assert!(message.contains("no keys"));
            }
            _ => panic!("Expected error response"),
        }
    }

    #[tokio::test]
    async fn test_unwrap_recovery_bundle() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-unwrap".to_string();
        let serial_number = "test-serial-unwrap".to_string();
        let recovery_key = b"test-recovery-key-unwrap".to_vec();

        // Initialize organization key
        initialize_organization_key_for_testing(session, &organization_id)
            .expect("Failed to initialize organization key");

        // Create and generate recovery bundle
        let recovery_key_file =
            create_temporary_recovery_key_file(&recovery_key);
        let response = execute_generate(
            session,
            None,
            organization_id.clone(),
            vec![serial_number.clone()],
            vec![recovery_key_file.path().to_path_buf()],
        );

        let recovery_bundle = match response {
            DaemonResponse::Success {
                data: Some(DaemonResponseData::RecoveryBundles(bundles)),
            } => bundles[0].clone(),
            _ => panic!("Expected success response with recovery bundles"),
        };

        // Create temporary recovery bundle file
        let recovery_bundle_file =
            create_temporary_recovery_bundle_file(&recovery_bundle);

        // Unwrap the recovery bundle
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
                assert_eq!(key_data.organization_id, organization_id);
                assert_eq!(key_data.recovery_key, recovery_key);
                assert_eq!(key_data.version, RECOVERY_KEY_DATA_VERSION);
            }
            _ => panic!("Expected success response with recovery key data"),
        }
    }

    #[tokio::test]
    async fn test_unwrap_multiple_recovery_bundles() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-unwrap-multiple".to_string();
        let serial_number_first = "test-serial-unwrap-1".to_string();
        let serial_number_second = "test-serial-unwrap-2".to_string();
        let recovery_key_first = b"test-recovery-key-1".to_vec();
        let recovery_key_second = b"test-recovery-key-2".to_vec();

        // Initialize organization key
        initialize_organization_key_for_testing(session, &organization_id)
            .expect("Failed to initialize organization key");

        // Create and generate recovery bundles
        let recovery_key_file_first =
            create_temporary_recovery_key_file(&recovery_key_first);
        let recovery_key_file_second =
            create_temporary_recovery_key_file(&recovery_key_second);

        let response = execute_generate(
            session,
            None,
            organization_id.clone(),
            vec![serial_number_first.clone(), serial_number_second.clone()],
            vec![
                recovery_key_file_first.path().to_path_buf(),
                recovery_key_file_second.path().to_path_buf(),
            ],
        );

        let recovery_bundles = match response {
            DaemonResponse::Success {
                data: Some(DaemonResponseData::RecoveryBundles(bundles)),
            } => bundles,
            _ => panic!("Expected success response with recovery bundles"),
        };

        // Create temporary recovery bundle files
        let recovery_bundle_file_first =
            create_temporary_recovery_bundle_file(&recovery_bundles[0]);
        let recovery_bundle_file_second =
            create_temporary_recovery_bundle_file(&recovery_bundles[1]);

        // Unwrap the recovery bundles
        let response = execute_unwrap(
            session,
            None,
            vec![
                recovery_bundle_file_first.path().to_path_buf(),
                recovery_bundle_file_second.path().to_path_buf(),
            ],
        );

        match response {
            DaemonResponse::Success {
                data: Some(DaemonResponseData::RecoveryKeyDatas(key_datas)),
            } => {
                assert_eq!(key_datas.len(), 2);

                let key_data_first = &key_datas[0];
                assert_eq!(key_data_first.serial_number, serial_number_first);
                assert_eq!(key_data_first.organization_id, organization_id);
                assert_eq!(key_data_first.recovery_key, recovery_key_first);

                let key_data_second = &key_datas[1];
                assert_eq!(key_data_second.serial_number, serial_number_second);
                assert_eq!(key_data_second.organization_id, organization_id);
                assert_eq!(key_data_second.recovery_key, recovery_key_second);
            }
            _ => panic!("Expected success response with recovery key data"),
        }
    }

    #[tokio::test]
    async fn test_encrypt_and_decrypt_recovery_key_data() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-encrypt-decrypt".to_string();
        let serial_number = "test-serial-encrypt".to_string();
        let recovery_key = b"test-recovery-key-encrypt".to_vec();

        // Initialize organization key
        initialize_organization_key_for_testing(session, &organization_id)
            .expect("Failed to initialize organization key");

        // Get the organization public key
        let key_manager = HsmKeyManager::new(session);
        let organization_key_label =
            KeyLabel::organization_label(organization_id.as_str());
        let (organization_key, _) = key_manager
            .get_latest_key(ObjectClass::PUBLIC_KEY, &organization_key_label)
            .unwrap()
            .unwrap();
        let public_key =
            key_manager.extract_public_key(&organization_key).unwrap();

        // Encrypt the recovery key data
        let encrypted_data = encrypt_recovery_key_data(
            &public_key,
            serial_number.clone(),
            organization_id.clone(),
            recovery_key.clone(),
        )
        .unwrap();

        assert!(!encrypted_data.is_empty());

        // Create a recovery bundle and decrypt it
        let recovery_bundle = RecoveryBundle {
            serial_number: serial_number.clone(),
            organization_id: organization_id.clone(),
            organization_key_version: 1,
            encrypted_key_data: encrypted_data,
        };

        let decrypted_data =
            unwrap_recovery_key(session, recovery_bundle).unwrap();

        assert_eq!(decrypted_data.serial_number, serial_number);
        assert_eq!(decrypted_data.organization_id, organization_id);
        assert_eq!(decrypted_data.recovery_key, recovery_key);
        assert_eq!(decrypted_data.version, RECOVERY_KEY_DATA_VERSION);
    }
}

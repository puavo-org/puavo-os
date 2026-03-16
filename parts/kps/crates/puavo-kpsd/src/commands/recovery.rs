use cryptoki::{
    mechanism::{Mechanism, MechanismType},
    mechanism::rsa::{PkcsMgfType, PkcsOaepParams, PkcsOaepSource},
    object::{ObjectClass, ObjectHandle},
};
use puavo_hsm::{
    HsmKeyManager, HsmSession, KeyLabel, key_management::KeyManagementError,
};
use puavo_ipc::{
    DaemonResponse, DaemonResponseData, EncryptionAlgorithm,
    RECOVERY_KEY_DATA_VERSION, RecoveryBundle, RecoveryKeyData,
};
use rsa::{Oaep, RsaPublicKey};
use sha1::Sha1;
use sha2::Sha256;
use std::{fs, path::PathBuf};

/// Default encryption algorithm used when generating new recovery bundles.
/// NOTE(recovery-bundle-rsa-oaep):
/// SHA-1 OAEP is used in tests due to lack of SHA-256 OAEP support in SoftHSM (03/2026).
#[cfg(not(test))]
const DEFAULT_ENCRYPTION_ALGORITHM: EncryptionAlgorithm =
    EncryptionAlgorithm::RsaOaepSha256;

#[cfg(test)]
const DEFAULT_ENCRYPTION_ALGORITHM: EncryptionAlgorithm =
    EncryptionAlgorithm::RsaOaepSha1;

/// Errors that can occur during recovery key operations
#[derive(Debug, thiserror::Error)]
pub enum RecoveryKeyError {
    #[error(transparent)]
    KeyManagement(#[from] KeyManagementError),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Organisation has no keys")]
    NoOrganisationKeys,

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
/// * `organisation_id` - Organisation identifier
/// * `recovery_key` - Raw recovery key bytes
///
/// Returns:
/// Recovery key data structure ready for serialization
fn create_recovery_key_data(
    serial_number: String,
    organisation_id: String,
    recovery_key: Vec<u8>,
) -> RecoveryKeyData {
    RecoveryKeyData {
        serial_number,
        organisation_id,
        recovery_key,
        version: RECOVERY_KEY_DATA_VERSION,
    }
}

/// Encrypt recovery key data with organisation public key
///
/// Parameters:
/// * `public_key` - Public key for encryption
/// * `serial_number` - Device serial number
/// * `organisation_id` - Organisation identifier
/// * `recovery_key` - Raw recovery key bytes
///
/// Returns:
/// Tuple of hex-encoded encrypted recovery key data and the algorithm used
///
/// Errors:
/// Returns error if serialization or encryption fails
pub fn encrypt_recovery_key_data(
    public_key: &RsaPublicKey,
    serial_number: String,
    organisation_id: String,
    recovery_key: Vec<u8>,
) -> Result<(String, EncryptionAlgorithm), RecoveryKeyError> {
    let key_data =
        create_recovery_key_data(serial_number, organisation_id, recovery_key);
    let serialized_key_data = serde_json::to_vec(&key_data)?;
    let algorithm = DEFAULT_ENCRYPTION_ALGORITHM.clone();
    let (encrypted_key_data_bytes, algorithm) =
        encrypt(public_key, &serialized_key_data, algorithm)?;
    Ok((hex::encode(&encrypted_key_data_bytes), algorithm))
}

/// Encrypt data using RSA with the specified OAEP algorithm
///
/// Parameters:
/// * `public_key` - Public key for encryption
/// * `key_data` - Data to encrypt
/// * `algorithm` - OAEP algorithm to use
///
/// Returns:
/// Tuple of encrypted data and the algorithm used
///
/// Errors:
/// Returns error if encryption fails or an unsupported algorithm is requested
fn encrypt(
    public_key: &RsaPublicKey,
    key_data: &[u8],
    algorithm: EncryptionAlgorithm,
) -> Result<(Vec<u8>, EncryptionAlgorithm), KeyManagementError> {
    let mut random_number_generator = rand::thread_rng();
    let encrypted_key_data = match &algorithm {
        EncryptionAlgorithm::RsaOaepSha256 => public_key.encrypt(
            &mut random_number_generator,
            Oaep::new::<Sha256>(),
            key_data,
        )?,
        EncryptionAlgorithm::RsaOaepSha1 => public_key.encrypt(
            &mut random_number_generator,
            Oaep::new::<Sha1>(),
            key_data,
        )?,
    };
    Ok((encrypted_key_data, algorithm))
}

/// Decrypt data using RSA with HSM private key
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `private_key_handle` - Handle to private key in HSM
/// * `encrypted_key_data` - Key data to decrypt
/// * `algorithm` - Encryption algorithm used when the data was encrypted
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
    algorithm: &EncryptionAlgorithm,
) -> Result<Vec<u8>, KeyManagementError> {
    let session = hsm_session.session();

    let key_data = match algorithm {
        EncryptionAlgorithm::RsaOaepSha1 => {
            let params = PkcsOaepParams::new(
                MechanismType::SHA1,
                PkcsMgfType::MGF1_SHA1,
                PkcsOaepSource::empty(),
            );
            session.decrypt(
                &Mechanism::RsaPkcsOaep(params),
                *private_key_handle,
                encrypted_key_data,
            )?
        }
        EncryptionAlgorithm::RsaOaepSha256 => {
            let params = PkcsOaepParams::new(
                MechanismType::SHA256,
                PkcsMgfType::MGF1_SHA256,
                PkcsOaepSource::empty(),
            );
            session.decrypt(
                &Mechanism::RsaPkcsOaep(params),
                *private_key_handle,
                encrypted_key_data,
            )?
        }
    };

    Ok(key_data)
}

fn decrypt_with_organisation_key(
    hsm_session: &HsmSession,
    organisation_id: &str,
    organisation_key_version: u32,
    encrypted_key_data: &[u8],
    algorithm: &EncryptionAlgorithm,
) -> Result<Vec<u8>, KeyManagementError> {
    tracing::info!("Decrypting recovery key data");

    let key_label =
        KeyLabel::organisation(organisation_id, organisation_key_version);
    let key_manager = HsmKeyManager::new(hsm_session);
    let key = key_manager
        .get_key_with_version(ObjectClass::PRIVATE_KEY, &key_label)?;

    decrypt(hsm_session, &key, encrypted_key_data, algorithm)
}

/// Encrypt the specified recovery key for a device
///
/// Parameters:
/// * `hsm_session` - Active HSM session for key operations
/// * `organisation_id` - Organisation identifier
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
    organisation_id: String,
    serial_number: String,
    recovery_key: Vec<u8>,
) -> Result<RecoveryBundle, RecoveryKeyError> {
    tracing::info!(
        "Generating recovery key for device {} in organisation {}",
        serial_number,
        organisation_id
    );

    let key_manager = HsmKeyManager::new(hsm_session);

    // Find the latest organisation public key and its version
    let organisation_key_label =
        KeyLabel::organisation_label(organisation_id.as_str());
    let (organisation_key, organisation_key_version) = key_manager
        .get_latest_key(ObjectClass::PUBLIC_KEY, &organisation_key_label)?
        .ok_or(RecoveryKeyError::NoOrganisationKeys)?;

    // Load the organisation public key
    let key_manager = HsmKeyManager::new(hsm_session);
    let public_key = key_manager.extract_public_key(&organisation_key)?;

    // Encrypt the recovery key and related information
    let (encrypted_key_data, encryption_algorithm) = encrypt_recovery_key_data(
        &public_key,
        serial_number.clone(),
        organisation_id.clone(),
        recovery_key,
    )?;

    Ok(RecoveryBundle {
        serial_number,
        organisation_id,
        organisation_key_version,
        encrypted_key_data,
        encryption_algorithm,
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
    // Decrypt the recovery key data using the algorithm stored in the bundle
    let serialized_recovery_key_data = decrypt_with_organisation_key(
        hsm_session,
        &recovery_bundle.organisation_id,
        recovery_bundle.organisation_key_version,
        &encrypted_key_data_bytes,
        &recovery_bundle.encryption_algorithm,
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
/// * `organisation_id` - Organisation identifier
/// * `serial_numbers` - List of device serial numbers
/// * `recovery_key_files` - List of recovery key files (one per device)
///
/// Returns:
/// Daemon response with encrypted recovery key data (hex-encoded)
pub fn execute_generate(
    hsm_session: &HsmSession,
    _operator_id: Option<String>,
    organisation_id: String,
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
                    organisation_id.clone(),
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

    /// Initialize organisation key for testing
    ///
    /// Parameters:
    /// * `hsm_session` - Active HSM session for key operations
    /// * `organisation_id` - Organisation identifier
    ///
    /// Errors:
    /// Returns error if key generation fails
    fn initialize_organisation_key_for_testing(
        hsm_session: &HsmSession,
        organisation_id: &str,
    ) -> Result<(), KeyManagementError> {
        let key_label = KeyLabel::organisation(organisation_id, 1);
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

        let organisation_id = "test-organisation-generate".to_string();
        let serial_number = "test-serial-123".to_string();
        let recovery_key = b"test-recovery-key-data".to_vec();

        // Initialize organisation key first
        initialize_organisation_key_for_testing(session, &organisation_id)
            .expect("Failed to initialize organisation key");

        // Create temporary recovery key file
        let recovery_key_file =
            create_temporary_recovery_key_file(&recovery_key);

        // Generate recovery bundle
        let response = execute_generate(
            session,
            None,
            organisation_id.clone(),
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
                assert_eq!(bundle.organisation_id, organisation_id);
                assert_eq!(bundle.organisation_key_version, 1);
                assert!(!bundle.encrypted_key_data.is_empty());
            }
            _ => panic!("Expected success response with recovery bundles"),
        }
    }

    #[tokio::test]
    async fn test_generate_multiple_recovery_bundles() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-generate-multiple".to_string();
        let serial_number_first = "test-serial-456".to_string();
        let serial_number_second = "test-serial-789".to_string();
        let recovery_key_first = b"test-recovery-key-first".to_vec();
        let recovery_key_second = b"test-recovery-key-second".to_vec();

        // Initialize organisation key first
        initialize_organisation_key_for_testing(session, &organisation_id)
            .expect("Failed to initialize organisation key");

        // Create temporary recovery key files
        let recovery_key_file_first =
            create_temporary_recovery_key_file(&recovery_key_first);
        let recovery_key_file_second =
            create_temporary_recovery_key_file(&recovery_key_second);

        // Generate recovery bundles
        let response = execute_generate(
            session,
            None,
            organisation_id.clone(),
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
                assert_eq!(bundle_first.organisation_id, organisation_id);
                assert!(!bundle_first.encrypted_key_data.is_empty());

                let bundle_second = &bundles[1];
                assert_eq!(bundle_second.serial_number, serial_number_second);
                assert_eq!(bundle_second.organisation_id, organisation_id);
                assert!(!bundle_second.encrypted_key_data.is_empty());
            }
            _ => panic!("Expected success response with recovery bundles"),
        }
    }

    #[tokio::test]
    async fn test_generate_recovery_bundle_parameter_mismatch() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-mismatch".to_string();
        let serial_number = "test-serial-mismatch".to_string();

        // Try to generate with mismatched parameters
        let response = execute_generate(
            session,
            None,
            organisation_id,
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
    async fn test_generate_recovery_bundle_no_organisation_key() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-no-key".to_string();
        let serial_number = "test-serial-no-key".to_string();
        let recovery_key = b"test-recovery-key".to_vec();

        // Create temporary recovery key file
        let recovery_key_file =
            create_temporary_recovery_key_file(&recovery_key);

        // Try to generate without initializing organisation key first
        let response = execute_generate(
            session,
            None,
            organisation_id,
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

        let organisation_id = "test-organisation-unwrap".to_string();
        let serial_number = "test-serial-unwrap".to_string();
        let recovery_key = b"test-recovery-key-unwrap".to_vec();

        // Initialize organisation key
        initialize_organisation_key_for_testing(session, &organisation_id)
            .expect("Failed to initialize organisation key");

        // Create and generate recovery bundle
        let recovery_key_file =
            create_temporary_recovery_key_file(&recovery_key);
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
                assert_eq!(key_data.organisation_id, organisation_id);
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

        let organisation_id = "test-organisation-unwrap-multiple".to_string();
        let serial_number_first = "test-serial-unwrap-1".to_string();
        let serial_number_second = "test-serial-unwrap-2".to_string();
        let recovery_key_first = b"test-recovery-key-1".to_vec();
        let recovery_key_second = b"test-recovery-key-2".to_vec();

        // Initialize organisation key
        initialize_organisation_key_for_testing(session, &organisation_id)
            .expect("Failed to initialize organisation key");

        // Create and generate recovery bundles
        let recovery_key_file_first =
            create_temporary_recovery_key_file(&recovery_key_first);
        let recovery_key_file_second =
            create_temporary_recovery_key_file(&recovery_key_second);

        let response = execute_generate(
            session,
            None,
            organisation_id.clone(),
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
                assert_eq!(key_data_first.organisation_id, organisation_id);
                assert_eq!(key_data_first.recovery_key, recovery_key_first);

                let key_data_second = &key_datas[1];
                assert_eq!(key_data_second.serial_number, serial_number_second);
                assert_eq!(key_data_second.organisation_id, organisation_id);
                assert_eq!(key_data_second.recovery_key, recovery_key_second);
            }
            _ => panic!("Expected success response with recovery key data"),
        }
    }

    #[tokio::test]
    async fn test_encrypt_and_decrypt_recovery_key_data() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organisation_id = "test-organisation-encrypt-decrypt".to_string();
        let serial_number = "test-serial-encrypt".to_string();
        let recovery_key = b"test-recovery-key-encrypt".to_vec();

        // Initialize organisation key
        initialize_organisation_key_for_testing(session, &organisation_id)
            .expect("Failed to initialize organisation key");

        // Get the organisation public key
        let key_manager = HsmKeyManager::new(session);
        let organisation_key_label =
            KeyLabel::organisation_label(organisation_id.as_str());
        let (organisation_key, _) = key_manager
            .get_latest_key(ObjectClass::PUBLIC_KEY, &organisation_key_label)
            .unwrap()
            .unwrap();
        let public_key =
            key_manager.extract_public_key(&organisation_key).unwrap();

        // Encrypt the recovery key data
        let (encrypted_data, encryption_algorithm) = encrypt_recovery_key_data(
            &public_key,
            serial_number.clone(),
            organisation_id.clone(),
            recovery_key.clone(),
        )
        .unwrap();

        assert!(!encrypted_data.is_empty());
        // For details, see NOTE(recovery-bundle-rsa-oaep).
        assert_eq!(encryption_algorithm, EncryptionAlgorithm::RsaOaepSha1);

        // Create a recovery bundle and decrypt it
        let recovery_bundle = RecoveryBundle {
            serial_number: serial_number.clone(),
            organisation_id: organisation_id.clone(),
            organisation_key_version: 1,
            encrypted_key_data: encrypted_data,
            encryption_algorithm,
        };

        let decrypted_data =
            unwrap_recovery_key(session, recovery_bundle).unwrap();

        assert_eq!(decrypted_data.serial_number, serial_number);
        assert_eq!(decrypted_data.organisation_id, organisation_id);
        assert_eq!(decrypted_data.recovery_key, recovery_key);
        assert_eq!(decrypted_data.version, RECOVERY_KEY_DATA_VERSION);
    }
}

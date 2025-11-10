use anyhow::Result;
use puavo_ipc::{OrganizationPublicKey, RecoveryBundle};
use puavo_kpsd::commands::recovery::encrypt_recovery_key_data;
use rsa::{RsaPublicKey, pkcs1::DecodeRsaPublicKey, pkcs8::DecodePublicKey};
use std::{fs, path::PathBuf};

/// Errors that can occur during device-local operations
#[derive(Debug, thiserror::Error)]
pub enum DeviceRecoveryError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Public key file not found or invalid: {0}")]
    PublicKeyNotFound(String),

    #[error("System serial number not available from DMI")]
    SystemSerialNotAvailable,

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Recovery key generation error: {0}")]
    RecoveryKeyGeneration(String),
}

/// Generate recovery bundle locally on device.
///
/// Parameters:
/// * `organization_id` - Organization identifier
/// * `serial_number` - Optional device serial number (uses system serial if None)
/// * `output` - Output file path
/// * `recovery_key_file` - Path to recovery key file
///
/// Returns:
/// Generated recovery bundle
///
/// Errors:
/// Returns error if public key cannot be loaded or recovery bundle generation fails
pub async fn generate_recovery_bundle_local(
    organization_id: String,
    serial_number: Option<String>,
    output: PathBuf,
    recovery_key_file: PathBuf,
) -> Result<RecoveryBundle, DeviceRecoveryError> {
    tracing::info!(
        "Starting recovery bundle generation for organization: {}",
        organization_id
    );

    // Get device serial number
    let serial_number =
        serial_number.map(Ok).unwrap_or_else(|| get_system_serial_number())?;

    tracing::info!("Using device serial number: {}", serial_number);

    // Determine public key path
    let public_key_path = PathBuf::from(format!(
        "/etc/puavo/kps/organizations/{}.public-key.json",
        organization_id
    ));

    // Load and parse organization public key from JSON file
    tracing::info!("Loading public key from: {}", public_key_path.display());
    let public_key_data =
        load_organization_public_key_json(&public_key_path).await?;
    let public_key =
        parse_rsa_public_key_from_pem(&public_key_data.public_key_pem)?;

    // Read recovery key from file
    let recovery_key = tokio::fs::read(&recovery_key_file).await?;
    // TODO(recovery-key-format): Validate recovery key format?

    // Generate recovery bundle using shared logic from recovery.rs
    let encrypted_key_data = encrypt_recovery_key_data(
        &public_key,
        serial_number.clone(),
        organization_id.clone(),
        recovery_key,
    )
    .map_err(|error| {
        DeviceRecoveryError::RecoveryKeyGeneration(error.to_string())
    })?;

    let recovery_bundle = RecoveryBundle {
        serial_number,
        organization_id,
        organization_key_version: public_key_data.version,
        encrypted_key_data,
    };

    tracing::info!("Writing recovery bundle to: {}", output.display());
    let json_content = serde_json::to_string_pretty(&recovery_bundle)?;
    tokio::fs::write(&output, json_content).await?;

    println!("Recovery bundle generated successfully");
    Ok(recovery_bundle)
}

/// Get system serial number from hardware
///
/// Returns:
/// System serial number
///
/// Errors:
/// Returns error if serial number cannot be determined
fn get_system_serial_number() -> Result<String, DeviceRecoveryError> {
    // Only try product serial, no fallback to board serial
    let paths = ["/sys/class/dmi/id/product_serial"];

    for path in paths.iter() {
        if let Ok(serial) = fs::read_to_string(path) {
            let serial = serial.trim();
            if !serial.is_empty() && serial != "Not Specified" {
                return Ok(serial.to_string());
            }
        }
    }

    tracing::warn!("Could not determine system serial number from DMI");
    Err(DeviceRecoveryError::SystemSerialNotAvailable)
}

/// Load organization public key data from JSON file
///
/// Parameters:
/// * `path` - Path to JSON public key file
///
/// Returns:
/// Organization public key data structure
///
/// Errors:
/// Returns error if file cannot be read or parsed
async fn load_organization_public_key_json(
    path: &PathBuf,
) -> Result<OrganizationPublicKey, DeviceRecoveryError> {
    let serialized_public_key = tokio::fs::read_to_string(path).await?;

    if serialized_public_key.trim().is_empty() {
        return Err(DeviceRecoveryError::PublicKeyNotFound(
            path.display().to_string(),
        ));
    }

    let public_key: OrganizationPublicKey =
        serde_json::from_str(&serialized_public_key)?;
    tracing::debug!("Loaded public key data from JSON file");

    Ok(public_key)
}

/// Parse RSA public key from PEM string
///
/// Parameters:
/// * `pem_content` - PEM formatted public key string
///
/// Returns:
/// Parsed RSA public key
///
/// Errors:
/// Returns error if PEM cannot be parsed
fn parse_rsa_public_key_from_pem(
    pem_content: &str,
) -> Result<RsaPublicKey, DeviceRecoveryError> {
    RsaPublicKey::from_pkcs1_pem(pem_content)
        .or_else(|_| RsaPublicKey::from_public_key_pem(pem_content))
        .map_err(|_| {
            DeviceRecoveryError::PublicKeyNotFound(
                "Invalid PEM format".to_string(),
            )
        })
}

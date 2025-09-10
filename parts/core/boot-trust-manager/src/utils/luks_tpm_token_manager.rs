use libcryptsetup_rs::consts::vals::EncryptionFormat;
use libcryptsetup_rs::{CryptDevice, CryptInit};
use log::debug;
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::process::{Command, Stdio};

use crate::error::PuavoError;

const MAX_TOKENS: u32 = 32;
const TPM_TOKEN_TYPE: &str = "systemd-tpm2";

const DEFAULT_TPM2_PUBLIC_KEY_PATH: &str = "/.extra/tpm2-pcr-public-key.pem";

/// Representation of a systemd TPM2 LUKS token stored in the LUKS header.
///
/// This mirrors the JSON structure returned by cryptsetup for tokens of type `systemd-tpm2`.
#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
pub struct LuksTpmToken {
    /// PCR list for direct TPM binding (e.g. [7]).
    #[serde(rename = "tpm2-pcrs", default)]
    specific_pcrs: Vec<u8>,

    /// PCR list to be verified using a TPM public key policy.
    #[serde(rename = "tpm2-pubkey_pcrs", default)]
    public_key_pcrs: Option<Vec<u8>>,

    /// Whether a user PIN must be provided during unlock.
    #[serde(rename = "tpm2-pin", default)]
    use_pin: bool,
}

/// Enrollment policy used when creating a TPM2 token via `systemd-cryptenroll`.
#[derive(Serialize, Deserialize, Debug)]
pub struct LuksTpmEnrollmentPolicy {
    /// PCR expressions for direct TPM binding (e.g. ["7:sha256", "15:sha256=<value>"]).
    #[serde(rename = "tpm2-pcrs")]
    specific_pcrs_expressions: Option<Vec<String>>,

    /// PCR expressions to be validated using a TPM public key policy (e.g. ["11:sha256"]).
    #[serde(rename = "tpm2-public-key-pcrs")]
    public_key_pcrs_expressions: Option<Vec<String>>,

    /// Require a PIN for unlock.
    #[serde(rename = "tpm2-pin", default)]
    use_pin: bool,

    /// Wipe any existing TPM2 token slot before enrolling a new one.
    #[serde(rename = "wipe-tpm2-slot", default)]
    wipe_tpm2_slot: bool,

    /// Optional path to a new TPM2 public key used for policy verification.
    #[serde(rename = "tpm2-public-key-path", default)]
    public_key_path: Option<String>,
}

/// Helper for interacting with a LUKS2 device to manage TPM2 tokens.
pub struct LuksTpmTokenManager {
    device: CryptDevice,
    device_path: String,
}

impl LuksTpmTokenManager {
    /// Construct a manager from an existing crypt device handle and its path.
    pub fn new(device: CryptDevice, device_path: String) -> Self {
        Self { device, device_path: device_path.into() }
    }

    /// Construct a manager by initializing and loading a LUKS2 device from device path (e.g. `/dev/nvme0n1p3`).
    /// 
    /// Arguments:
    /// * `device_path` - Path to the LUKS2 device (e.g. `/dev/nvme0n1p3`).
    /// 
    /// Errors:
    /// Returns `PuavoError` if initialization or loading fails.
    pub fn from_device_path(device_path: String) -> Result<Self, PuavoError> {
        debug!("Initializing LUKS device from {}", device_path);
        let mut device = CryptInit::init(Path::new(&device_path))?;
        debug!("Loading LUKS device from {}", device_path);
        device
            .context_handle()
            .load::<()>(Some(EncryptionFormat::Luks2), None)?;
        let manager = Self::new(device, device_path);
        Ok(manager)
    }

    /// List all TPM tokens present in the LUKS2 header.
    /// 
    /// Errors:
    /// Returns `PuavoError` if token retrieval or parsing fails.
    pub fn list_tokens(&mut self) -> Result<Vec<LuksTpmToken>, PuavoError> {
        let luks_device = &mut self.device;

        let token_jsons = (0..MAX_TOKENS).filter_map(|token_index| {
            luks_device.token_handle().json_get(token_index).ok()
        });

        let mut tokens = Vec::new();

        for token_json in token_jsons {
            // Only consider systemd TPM2 tokens
            let token_type = token_json
                .get("type")
                .and_then(|value| value.as_str())
                .unwrap_or("");
            if token_type != TPM_TOKEN_TYPE {
                continue;
            }

            let token: LuksTpmToken = serde_json::from_value(token_json)
                .map_err(|_| {
                    PuavoError::LuksError(
                        "Failed to parse TPM token JSON".into(),
                    )
                })?;

            tokens.push(token);
        }

        Ok(tokens)
    }

    /// Enroll a TPM2 token using `systemd-cryptenroll` according to `policy`.
    ///
    /// Arguments:
    /// * `key` - The passphrase used to control the LUKS device.
    /// * `policy` - The enrollment policy specifying PCRs, PIN usage, and other options.
    /// 
    /// Errors:
    /// Returns `PuavoError` if enrollment fails.
    pub fn enroll(
        &self,
        key: &String,
        policy: &LuksTpmEnrollmentPolicy,
    ) -> Result<(), PuavoError> {
        let mut arguments: Vec<String> = Vec::new();
        arguments.push(self.device_path.clone());
        arguments.push("--tpm2-device=auto".to_string());

        if policy.wipe_tpm2_slot {
            arguments.push("--wipe-slot=tpm2".to_string());
        }

        if let Some(expressions) = &policy.specific_pcrs_expressions {
            if !expressions.is_empty() {
                arguments
                    .push(format!("--tpm2-pcrs={}", expressions.join("+")));
            }
        }

        if let Some(expressions) = &policy.public_key_pcrs_expressions {
            if !expressions.is_empty() {
                arguments.push(format!(
                    "--tpm2-public-key-pcrs={}",
                    expressions.join("+")
                ));
                arguments.push(format!(
                    "--tpm2-public-key={}",
                    // Keep the current public key unless overridden
                    policy
                        .public_key_path
                        .clone()
                        .unwrap_or(DEFAULT_TPM2_PUBLIC_KEY_PATH.to_string())
                ));
            }
        }

        if policy.use_pin {
            arguments.push("--tpm2-with-pin=yes".to_string());
        }

        debug!("Executing systemd-cryptenroll with: {:#?}", arguments);

        let output = Command::new("systemd-cryptenroll")
            .args(&arguments)
            .env("PASSWORD", key)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .map_err(PuavoError::IoError)?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr).to_string();
            return Err(PuavoError::ShellError(stderr));
        }

        Ok(())
    }

    /// Access the underlying crypt device handle.
    pub fn device(&self) -> &CryptDevice {
        &self.device
    }

    /// Mutable access to the underlying crypt device handle.
    pub fn device_mut(&mut self) -> &mut CryptDevice {
        &mut self.device
    }

    /// Validate that a passphrase can unlock the device by attempting to derive
    /// the volume key using the specified `passphrase`.
    /// 
    /// Arguments:
    /// * `passphrase` - The passphrase to test.
    /// 
    /// Errors:
    /// Returns `PuavoError` if the passphrase is invalid or internal errors occur.
    pub fn test_passphrase(
        &mut self,
        passphrase: &String,
    ) -> Result<(), PuavoError> {
        let volume_key_size = self.device.status_handle().get_volume_key_size();
        let mut volume_key_buffer = vec![0u8; volume_key_size as usize];

        let passphrase_bytes = passphrase.as_bytes();

        self.device.volume_key_handle().get(
            None,
            &mut volume_key_buffer,
            Some(&passphrase_bytes),
        )?;

        Ok(())
    }
}

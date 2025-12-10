use libcryptsetup_rs::consts::flags::{CryptActivate, CryptDeactivate};
use libcryptsetup_rs::consts::vals::EncryptionFormat;
use libcryptsetup_rs::{CryptDevice, CryptInit, TokenInput};
use log::debug;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use crate::error::PuavoError;

pub const MAX_TOKENS: u32 = 32;
pub const TPM_TOKEN_TYPE: &str = "systemd-tpm2";

// Name of the TPM token field defining whether PIN is required.
pub const TPM_TOKEN_PIN_FIELD: &str = "tpm2-pin";

pub const PCR_PUBLIC_KEY_PREFIX: &str = "tpm2-pcr-public-key";

/// Representation of a systemd TPM2 LUKS token stored in the LUKS header.
///
/// This mirrors the JSON structure returned by cryptsetup for tokens of type `systemd-tpm2`.
#[derive(Serialize, Deserialize, Debug)]
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
#[derive(Serialize, Deserialize, Debug, Clone, Hash)]
pub struct LuksTpmEnrollmentPolicy {
    /// PCR expressions for direct TPM binding (e.g. ["7:sha256", "15:sha256=<value>"]).
    #[serde(rename = "tpm2-pcrs")]
    specific_pcrs_expressions: Option<Vec<String>>,

    /// PCR expressions to be validated using a TPM public key policy (e.g. ["11:sha256"]).
    #[serde(rename = "tpm2-public-key-pcrs", default)]
    public_key_pcrs_expressions: Vec<String>,

    /// Directory containing TPM2 public keys to enroll.
    #[serde(rename = "tpm2-public-key-directory", default)]
    public_key_directory: Option<String>,

    // List of public keys inside the directory and their digests.
    // The digest is stored, because it affects the hash of this policy,
    // which is used to detect changes.
    #[serde(skip)]
    pub public_keys: Vec<(PathBuf, String)>,
}

impl LuksTpmEnrollmentPolicy {
    /// Finds the public keys in the configured directory and computes their digests.
    pub fn find_public_keys(&mut self) -> Result<(), PuavoError> {
        self.public_keys.clear();

        let directory = match &self.public_key_directory {
            Some(directory) => directory,
            None => return Ok(()), // No directory configured
        };

        debug!("Looking for PCR public keys in directory: {}", directory);

        // Collect the paths of each public key and compute its digest
        for entry in fs::read_dir(&directory)? {
            let entry = entry?;
            let path = entry.path();
            let is_pcr_public_key = path
                .file_name()
                .and_then(|file_name| file_name.to_str())
                .map(|file_name| file_name.starts_with(PCR_PUBLIC_KEY_PREFIX))
                .unwrap_or_default();

            if is_pcr_public_key {
                debug!("Found PCR public key: {}", path.display());
                let key_data = fs::read(&path)?;
                let key_digest = format!("{:X}", Sha256::digest(key_data));
                self.public_keys.push((path, key_digest));
            }
        }

        self.public_keys.sort_by(|key1, key2| key1.0.cmp(&key2.0));

        debug!("Found {} public key(s) for enrollment", self.public_keys.len());
        Ok(())
    }
}

/// Helper for interacting with a LUKS2 device to manage TPM2 tokens.
pub struct LuksTpmTokenManager {
    device: CryptDevice,
    device_path: String,
}

impl LuksTpmTokenManager {
    /// Returns whether the specified token requires PIN
    ///
    /// Parameters:
    /// - `device`: The crypt device handle used to inspect the token
    /// - `token_index`: The index of token
    ///
    /// Errors:
    /// Propagates cryptsetup errors.
    pub fn is_pin_required(
        device: &mut CryptDevice,
        token_index: u32,
    ) -> Result<bool, PuavoError> {
        let token = match device.token_handle().json_get(token_index)? {
            Value::Object(token) => token,
            value => {
                return Err(PuavoError::LuksError(format!(
                    "Unexpected token format: {0}",
                    value
                )));
            }
        };

        match token.get_key_value(TPM_TOKEN_PIN_FIELD) {
            Some((_, Value::Bool(pin))) => Ok(*pin),
            Some((_, value)) => {
                return Err(PuavoError::LuksError(format!(
                    "Unexpected token PIN value: {0}",
                    value
                )));
            }
            None => Ok(false),
        }
    }

    /// Construct a manager from an existing crypt device handle and its path.
    pub fn new(device: CryptDevice, device_path: String) -> Self {
        Self { device, device_path: device_path.into() }
    }

    /// Construct a manager by initializing and loading a LUKS2 device from a device path (e.g. `/dev/nvme0n1p3`).
    ///
    /// Parameters:
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

    /// Construct a manager by attaching to an already opened LUKS2 device by its name.
    ///
    /// Parameters:
    /// * `name` - Name of the LUKS device mapping (`/dev/mapper/<name>`).
    ///
    /// Errors:
    /// Returns `PuavoError` if initialization or loading fails.
    pub fn from_name(name: &str) -> Result<Self, PuavoError> {
        debug!("Initializing LUKS device from name {}", name);
        let mut device = CryptInit::init_by_name_and_header(name, None)?;
        debug!("Loading LUKS device from name {}", name);
        device
            .context_handle()
            .load::<()>(Some(EncryptionFormat::Luks2), None)?;
        let device_path = device
            .status_handle()
            .get_device_path()?
            .to_string_lossy()
            .to_string();
        let manager = Self::new(device, device_path);
        Ok(manager)
    }

    /// List all TPM tokens present in the LUKS2 header.
    ///
    /// Errors:
    /// Returns `PuavoError` if token retrieval or parsing fails.
    pub fn list_tokens(
        &mut self,
    ) -> Result<HashMap<u32, LuksTpmToken>, PuavoError> {
        let luks_device = &mut self.device;

        let token_jsons = (0..MAX_TOKENS).filter_map(|token_index| {
            luks_device
                .token_handle()
                .json_get(token_index)
                .ok()
                .map(|json| (token_index, json))
        });

        let mut tokens = HashMap::new();

        for (token_index, token_json) in token_jsons {
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

            tokens.insert(token_index, token);
        }

        Ok(tokens)
    }

    /// Enroll a TPM2 token using `systemd-cryptenroll` according to `policy`.
    ///
    /// Parameters:
    /// * `key` - The passphrase used to control the LUKS device.
    /// * `policy` - The enrollment policy specifying PCRs, PIN usage, and other options.
    /// * `pin` - Optional PIN used for unlocking the device.
    /// * `public_key_path` - Path to a TPM PCR public key.
    /// * `wipe` - If true, any existing TPM token will be removed before enrolling the new one.
    ///
    /// Errors:
    /// Returns `PuavoError` if enrollment fails.
    pub fn enroll(
        &self,
        key: &String,
        policy: &LuksTpmEnrollmentPolicy,
        pin: Option<String>,
        public_key_path: Option<&PathBuf>,
        wipe: bool,
    ) -> Result<(), PuavoError> {
        let mut arguments: Vec<String> = Vec::new();
        arguments.push(self.device_path.clone());
        arguments.push("--tpm2-device=auto".to_string());

        if wipe {
            arguments.push("--wipe-slot=tpm2".to_string());
        }

        if let Some(expressions) = &policy.specific_pcrs_expressions {
            arguments
                .push(format!("--tpm2-pcrs={}", expressions.join("+")));
        }

        if let Some(public_key_path) = public_key_path {
            if !policy.public_key_pcrs_expressions.is_empty() {
                arguments.push(format!(
                    "--tpm2-public-key-pcrs={}",
                    policy.public_key_pcrs_expressions.join("+")
                ));
                arguments.push(format!(
                    "--tpm2-public-key={}",
                    public_key_path.display()
                ));
            }
        }

        if pin.is_some() {
            arguments.push("--tpm2-with-pin=yes".to_string());
        }

        debug!("Executing systemd-cryptenroll with: {:#?}", arguments);

        let output = Command::new("systemd-cryptenroll")
            .args(&arguments)
            .env("PASSWORD", key)
            .env("NEWPIN", pin.clone().unwrap_or_default())
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

    /// Tests the validity of the specified token.
    ///
    /// Parameters:
    /// * `token_id` - The identifier of the token to test.
    /// * `pin` - Optional PIN used for unlocking the token
    ///
    /// Errors:
    /// Returns `PuavoError` if the token is invalid or internal errors occur.
    pub fn test_token(&mut self, token_id: u32, pin: Option<&String>) -> bool {
        if let Some(pin) = pin {
            self.device
                .token_handle()
                .activate_by_token_with_pin::<()>(
                    None,
                    Some(token_id),
                    pin.as_str(),
                    None,
                    CryptActivate::empty(),
                )
                .is_ok()
        } else {
            self.device
                .token_handle()
                .activate_by_token::<()>(
                    None,
                    Some(token_id),
                    None,
                    CryptActivate::empty(),
                )
                .is_ok()
        }
    }

    /// Remove a TPM token by its ID.
    ///
    /// Parameters:
    /// * `token_id` - The identifier of the token to remove.
    ///
    /// Errors:
    /// Returns `PuavoError::LibcryptError` if the removal fails.
    pub fn remove_token(&mut self, token_id: u32) -> Result<(), PuavoError> {
        debug!("Removing TPM token with ID {}", token_id);
        self.device
            .token_handle()
            .json_set(TokenInput::RemoveToken(token_id))?;
        Ok(())
    }

    /// Removes the specified TPM tokens by their IDs.
    ///
    /// Parameters:
    /// * `token_ids` - A list of token IDs to remove.
    ///
    /// Errors:
    /// Returns `PuavoError::LibcryptError` if any removal fails.
    pub fn remove_tokens(
        &mut self,
        token_ids: Vec<u32>,
    ) -> Result<(), PuavoError> {
        for token_id in token_ids {
            self.remove_token(token_id)?;
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

    /// Get the device path managed by this token manager.
    pub fn device_path(&self) -> &String {
        &self.device_path
    }

    /// Validate that a passphrase can unlock the device by attempting to derive
    /// the volume key using the specified `passphrase`.
    ///
    /// Parameters:
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

    /// Unmounts the device managed by this token manager.
    ///
    /// Parameters:
    /// - `name` - The name of the LUKS device mapping to unmount.
    ///
    /// Errors:
    /// Returns `PuavoError` if unmounting fails.
    pub fn unmount(&mut self, name: &str) -> Result<(), PuavoError> {
        debug!("Closing LUKS device: {}", name);
        self.device
            .activate_handle()
            .deactivate(name, CryptDeactivate::empty())?;
        Ok(())
    }
}

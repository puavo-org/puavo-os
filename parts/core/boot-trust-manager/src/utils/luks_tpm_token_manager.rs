#![allow(dead_code)]
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

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
pub struct LuksTpmToken {
    #[serde(rename = "tpm2-pcrs", default)]
    specific_pcrs: Vec<u8>,

    #[serde(rename = "tpm2-pubkey_pcrs", default)]
    public_key_pcrs: Option<Vec<u8>>,

    #[serde(rename = "tpm2-pin", default)]
    use_pin: bool,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct LuksTpmEnrollmentPolicy {
    #[serde(rename = "tpm2-pcrs")]
    specific_pcrs_expressions: Option<Vec<String>>,

    #[serde(rename = "tpm2-public-key-pcrs")]
    public_key_pcrs_expressions: Option<Vec<String>>,

    #[serde(rename = "tpm2-pin", default)]
    use_pin: bool,

    #[serde(rename = "wipe-tpm2-slot", default)]
    wipe_tpm2_slot: bool,
}

pub struct LuksTpmTokenManager {
    device: CryptDevice,
    device_path: String,
}

impl LuksTpmTokenManager {
    pub fn new(device: CryptDevice, device_path: String) -> Self {
        Self { device, device_path: device_path.into() }
    }

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
                // Always point to default public key path in initrd if public key PCRs are requested
                arguments.push(format!(
                    "--tpm2-public-key={}",
                    DEFAULT_TPM2_PUBLIC_KEY_PATH
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

    pub fn device(&self) -> &CryptDevice {
        &self.device
    }

    pub fn device_mut(&mut self) -> &mut CryptDevice {
        &mut self.device
    }
}

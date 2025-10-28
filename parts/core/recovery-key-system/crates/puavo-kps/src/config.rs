use puavo_hsm::DEFAULT_SOFTWARE_MODULE;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KpsConfig {
    /// HSM configuration
    pub hsm: HsmConfig,

    /// Audit logging configuration
    pub audit: AuditConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HsmConfig {
    /// PKCS#11 module library path
    pub module_path: PathBuf,

    /// HSM slot number
    pub slot: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditConfig {
    /// Audit log file path
    pub log_path: PathBuf,
}

impl Default for KpsConfig {
    fn default() -> Self {
        Self {
            hsm: HsmConfig {
                module_path: PathBuf::from(DEFAULT_SOFTWARE_MODULE),
                slot: 0,
            },
            audit: AuditConfig {
                log_path: PathBuf::from("/var/log/puavo-kps/audit.log"),
            },
        }
    }
}

impl KpsConfig {
    /// Load configuration from TOML file
    ///
    /// Parameters:
    /// * `path` - Path to the configuration file
    ///
    /// Returns:
    /// Loaded configuration
    ///
    /// Errors:
    /// Returns `ConfigError` if file cannot be read or parsed
    pub fn load(path: &Path) -> Result<Self, ConfigError> {
        let contents = std::fs::read_to_string(path).map_err(|error| {
            ConfigError::ReadError(path.to_path_buf(), error)
        })?;

        let config: Self = toml::from_str(&contents)
            .map_err(|error| ConfigError::ParseError(error.to_string()))?;

        Ok(config)
    }

    /// Save configuration to TOML file
    ///
    /// Parameters:
    /// * `path` - Path to save the configuration file
    ///
    /// Errors:
    /// Returns `ConfigError` if file cannot be written or serialized
    pub fn save(&self, path: &Path) -> Result<(), ConfigError> {
        let contents = toml::to_string_pretty(self).map_err(|error| {
            ConfigError::SerializationError(error.to_string())
        })?;

        // Create parent directory if it does not exist
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent).map_err(|error| {
                ConfigError::WriteError(path.to_path_buf(), error)
            })?;
        }

        std::fs::write(path, contents).map_err(|error| {
            ConfigError::WriteError(path.to_path_buf(), error)
        })?;

        Ok(())
    }
}

#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("Failed to read configuration file {0}: {1}")]
    ReadError(PathBuf, std::io::Error),

    #[error("Failed to write configuration file {0}: {1}")]
    WriteError(PathBuf, std::io::Error),

    #[error("Failed to parse configuration: {0}")]
    ParseError(String),

    #[error("Failed to serialize configuration: {0}")]
    SerializationError(String),
}

use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KpsConfig {
    /// HSM configuration
    pub hsm: HsmConfig,

    /// Socket configuration
    pub socket: SocketConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HsmConfig {
    /// PKCS#11 module library path
    pub module_path: PathBuf,

    /// HSM token label
    pub token_label: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SocketConfig {
    /// Path to the UNIX domain socket
    pub path: PathBuf,

    /// UNIX group name for socket access control
    pub group: String,
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
        let contents = std::fs::read_to_string(path)
            .map_err(|error| ConfigError::Read(path.to_path_buf(), error))?;

        let config: Self = toml::from_str(&contents)
            .map_err(|error| ConfigError::Parse(error.to_string()))?;

        Ok(config)
    }
}

#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("Failed to read configuration file {0}: {1}")]
    Read(PathBuf, std::io::Error),

    #[error("Failed to parse configuration: {0}")]
    Parse(String),
}

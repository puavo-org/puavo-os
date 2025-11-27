use clap::{Subcommand, ValueEnum};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::time::SystemTime;

pub mod salt;

/// Output format for CLI responses
#[derive(Default, Clone, Copy, Debug, ValueEnum, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum OutputFormat {
    /// Human-readable text output
    #[default]
    Text,

    /// JSON output
    Json,
}

/// Unique identifier for correlating requests and responses
pub type MessageId = u64;

/// Default socket path for daemon communication
pub const DEFAULT_SOCKET_PATH: &str = "/tmp/puavo-kps-daemon.sock";

/// Maximum message buffer size for IPC communication
pub const MAX_MESSAGE_SIZE: usize = 8192;

/// Version of the recovery key data structure
pub const RECOVERY_KEY_DATA_VERSION: u32 = 1;

/// Recovery key data structure containing device information and recovery key
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecoveryKeyData {
    /// Device serial number
    pub serial_number: String,
    /// Organization ID
    pub organization_id: String,
    /// Actual recovery key bytes
    pub recovery_key: Vec<u8>,
    // Version field for this structure
    pub version: u32,
}

/// Structure containing encrypted key data and the information for decrypting it
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecoveryBundle {
    /// Device serial number
    pub serial_number: String,
    /// Organization ID
    pub organization_id: String,
    /// Version of the organization key used
    pub organization_key_version: u32,
    /// Encrypted recovery key bytes
    pub encrypted_key_data: String,
}

/// Structure containing exported organization public key data
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrganizationPublicKey {
    /// Organization ID
    pub organization_id: String,
    /// Version of the organization key
    pub version: u32,
    /// Public key in PEM format
    pub public_key_pem: String,
}

/// Structure containing information about a single key version
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrganizationKeyVersion {
    /// Key version number
    pub version: u32,
    /// SHA-256 fingerprint of the public key (pem)
    pub fingerprint: String,
}

/// Structure containing organization key listing information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrganizationKeyListing {
    /// Organization ID
    pub organization_id: String,
    /// List of key versions
    pub versions: Vec<OrganizationKeyVersion>,
}

/// Top-level IPC message envelope
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IpcMessage {
    pub id: MessageId,
    pub timestamp: SystemTime,
    pub payload: IpcPayload,
}

/// Message payload
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum IpcPayload {
    Command(DaemonCommand),
    Response(DaemonResponse),
}

/// Commands that can be sent to daemon
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DaemonCommand {
    /// Get daemon status information
    GetStatus,

    /// Shutdown daemon gracefully
    Shutdown { force: bool },

    /// Execute a command (KPS operations)
    Execute(Commands),
}

/// Commands for KPS operations
#[derive(Subcommand, Debug, Clone, Serialize, Deserialize)]
pub enum Commands {
    /// Initialize Key Provisioning Station
    Initialize {
        /// HSM slot number
        #[arg(long, default_value = "0")]
        hsm_slot: u64,

        /// HSM user PIN (will prompt if not provided)
        #[arg(long)]
        hsm_pin: Option<String>,

        /// Overwrite existing configuration
        #[arg(long)]
        force: bool,
    },

    /// Organization key management
    Organization {
        #[command(subcommand)]
        command: OrganizationCommand,
    },

    /// Generate new recovery bundles for devices
    Generate {
        /// Operator identifier
        #[arg(long)]
        operator_id: Option<String>,

        /// Organization identifier
        #[arg(long)]
        organization_id: String,

        /// Device serial number (can be specified multiple times)
        #[arg(long)]
        serial_number: Vec<String>,

        /// Paths to recovery key files corresponding to the specified serial numbers (can be specified multiple times)
        #[arg(long)]
        recovery_key_file: Vec<PathBuf>,
    },

    /// Unwrap encrypted recovery key data
    Unwrap {
        /// Operator identifier
        #[arg(long)]
        operator_id: Option<String>,

        /// Files containing encrypted recovery key data (can be specified multiple times)
        #[arg(long)]
        recovery_bundle: Vec<PathBuf>,
    },
}

/// Organization key management commands
#[derive(Subcommand, Debug, Clone, Serialize, Deserialize)]
pub enum OrganizationCommand {
    /// Initialize organization key in HSM
    Initialize {
        /// Organization identifier
        #[arg(long)]
        organization_id: String,
    },

    /// Rotate organization key
    Rotate {
        /// Organization identifier
        #[arg(long)]
        organization_id: String,
    },

    /// Export organization public key
    Export {
        /// Organization identifier
        #[arg(long)]
        organization_id: String,

        /// Key version to export
        #[arg(long)]
        version: u32,

        /// Output file path
        #[arg(long)]
        output: Option<PathBuf>,
    },

    /// List organization keys
    List {
        /// Organization identifier
        #[arg(long)]
        organization_id: Option<String>,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DaemonResponseData {
    /// List of organization keys
    OrganizationKeyListings(Vec<OrganizationKeyListing>),

    /// Exported organization public key
    OrganizationPublicKey(OrganizationPublicKey),

    /// List of recovery bundles
    RecoveryBundles(Vec<RecoveryBundle>),

    /// List of recovery key data
    RecoveryKeyDatas(Vec<RecoveryKeyData>),

    /// Daemon status information
    Status { uptime_seconds: u64, version: String },
}

/// Responses from daemon
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DaemonResponse {
    /// Successful operation with optional data
    Success {
        #[serde(skip_serializing_if = "Option::is_none")]
        data: Option<DaemonResponseData>,
    },

    /// Error occurred during operation
    Error(String),
}

/// IPC-specific errors
#[derive(Debug, thiserror::Error)]
pub enum IpcError {
    #[error("Connection failed: {0}")]
    ConnectionFailed(String),

    #[error("Serialization failed: {0}")]
    SerializationFailed(String),

    #[error("Deserialization failed: {0}")]
    DeserializationFailed(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Protocol error: {0}")]
    ProtocolError(String),
}

impl IpcMessage {
    /// Create new command message
    pub fn new_command(id: MessageId, command: DaemonCommand) -> Self {
        Self {
            id,
            timestamp: SystemTime::now(),
            payload: IpcPayload::Command(command),
        }
    }

    /// Create new response message
    pub fn new_response(id: MessageId, response: DaemonResponse) -> Self {
        Self {
            id,
            timestamp: SystemTime::now(),
            payload: IpcPayload::Response(response),
        }
    }
}

impl DaemonResponse {
    /// Create a success response without data
    pub fn success() -> Self {
        Self::Success { data: None }
    }

    /// Create a success response with data
    pub fn success_with_data(data: DaemonResponseData) -> Self {
        Self::Success { data: Some(data) }
    }
}

/// Support conversion from DaemonResponseData to DaemonResponse
impl From<DaemonResponseData> for DaemonResponse {
    fn from(value: DaemonResponseData) -> Self {
        DaemonResponse::success_with_data(value)
    }
}

/// Support conversion from Result<T, E> to DaemonResponse
impl<T, E> From<Result<T, E>> for DaemonResponse
where
    T: Into<DaemonResponse>,
    E: Into<DaemonResponse>,
{
    fn from(value: Result<T, E>) -> Self {
        match value {
            Ok(success) => success.into(),
            Err(error) => error.into(),
        }
    }
}

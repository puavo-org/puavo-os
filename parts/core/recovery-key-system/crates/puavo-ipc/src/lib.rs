use clap::Subcommand;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::time::SystemTime;

pub mod salt;

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
    pub version: u32
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
    pub encrypted_key_data: String
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

    /// Echo command for testing IPC
    Echo { message: String },

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

    /// Audit log management
    Audit {
        #[command(subcommand)]
        command: AuditCommand,
    },

    /// Operator management
    Operator {
        #[command(subcommand)]
        command: OperatorCommand,
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
}

/// Audit log management commands
#[derive(Subcommand, Debug, Clone, Serialize, Deserialize)]
pub enum AuditCommand {
    /// Display audit logs
    Log {
        /// Show logs since date (ISO 8601)
        #[arg(long)]
        since: Option<String>,

        /// Show logs until date (ISO 8601)
        #[arg(long)]
        until: Option<String>,

        /// Filter by operator ID
        #[arg(long)]
        operator: Option<String>,

        /// Output format
        #[arg(long, default_value = "text")]
        format: String,

        /// Show last N entries
        #[arg(long)]
        tail: Option<usize>,
    },

    /// Export audit logs
    Export {
        /// Output file path
        #[arg(long)]
        output: PathBuf,

        /// Export format
        #[arg(long, default_value = "jsonl")]
        format: String,
    },
}

/// Operator management commands
#[derive(Subcommand, Debug, Clone, Serialize, Deserialize)]
pub enum OperatorCommand {
    /// Add a new operator
    Add {
        /// Operator identifier (email or username)
        #[arg(long)]
        id: String,

        /// Full name
        #[arg(long)]
        name: String,
    },

    /// List authorized operators
    List,

    /// Revoke operator access
    Revoke {
        /// Operator identifier
        #[arg(long)]
        id: String,
    },
}

/// Responses from daemon
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DaemonResponse {
    /// Successful operation with optional data
    Success { 
        #[serde(skip_serializing_if = "Option::is_none")]
        data: Option<String> 
    },

    /// Error occurred during operation
    Error { code: String, message: String },

    /// Status information
    Status { uptime_seconds: u64, version: String },
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
    pub fn success_with_data(data: String) -> Self {
        Self::Success { data: Some(data) }
    }
}

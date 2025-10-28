use serde::{Deserialize, Serialize};
use std::time::SystemTime;
use std::path::PathBuf;
use clap::Subcommand;

pub mod salt;

/// Unique identifier for correlating requests and responses
pub type MessageId = u64;

/// Default socket path for daemon communication
pub const DEFAULT_SOCKET_PATH: &str = "/tmp/puavo-kps-daemon.sock";

/// Maximum message buffer size for IPC communication
pub const MAX_MESSAGE_SIZE: usize = 8192;

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

    /// Derive recovery bundles from device salts
    Derive {
        /// Custom shuttle mount point
        #[arg(long)]
        shuttle_path: Option<PathBuf>,

        /// Operator identifier
        #[arg(long)]
        operator_id: Option<String>,

        /// Process N devices at a time
        #[arg(long, default_value = "0")]
        batch_size: usize,

        /// Show what would be done without doing it
        #[arg(long)]
        dry_run: bool,
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

        /// Generate new key (default: true)
        #[arg(long, default_value = "true")]
        generate: bool,
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
    Success { message: String },

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

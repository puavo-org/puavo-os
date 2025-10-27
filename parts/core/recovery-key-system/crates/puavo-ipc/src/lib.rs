use serde::{Deserialize, Serialize};
use std::time::SystemTime;

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

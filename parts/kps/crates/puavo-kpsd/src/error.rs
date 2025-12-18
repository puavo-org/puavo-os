use std::path::PathBuf;

use puavo_hsm::HsmSessionError;
use puavo_ipc::DaemonResponse;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("Please initialize KPS")]
    SessionPoolNotInitialized,

    #[error("Failed to acquire HSM session lock")]
    SessionLockFailure,

    #[error("Failed to initialize HSM session pool: {0}")]
    SessionPoolInitializationFailed(String),

    #[error("Failed to acquire HSM session")]
    SessionAcquisitionTimeout,

    #[error("Failed to remove socket file {0}: {1}")]
    SocketRemovalError(PathBuf, std::io::Error),

    #[error("Failed to bind to socket {0}: {1}")]
    SocketBindError(PathBuf, std::io::Error),

    #[error("Failed to set socket permissions for {0}: {1}")]
    SocketPermissionsError(PathBuf, std::io::Error),

    #[error("Group '{0}' not found")]
    GroupNotFound(String),

    #[error("Failed to look up group '{0}': {1}")]
    GroupLookupError(String, nix::Error),

    #[error("Failed to set socket group ownership for {0}: {1}")]
    SocketOwnershipError(PathBuf, nix::Error),

    #[error("Failed to read from client: {0}")]
    ClientReadError(std::io::Error),

    #[error("Failed to write to client: {0}")]
    ClientWriteError(std::io::Error),

    #[error("Failed to deserialize message: {0}")]
    DeserializationError(String),

    #[error("Failed to serialize response: {0}")]
    SerializationError(String),

    #[error("Context initialization failed: {0}")]
    ContextError(#[from] HsmSessionError),
}

pub type Result<T> = std::result::Result<T, Error>;

impl From<Error> for DaemonResponse {
    fn from(error: Error) -> Self {
        DaemonResponse::Error(error.to_string())
    }
}

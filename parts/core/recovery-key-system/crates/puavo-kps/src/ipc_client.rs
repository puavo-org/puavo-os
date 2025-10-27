use anyhow::Result;
use puavo_ipc::{
    DEFAULT_SOCKET_PATH, DaemonCommand, DaemonResponse, IpcError, IpcMessage,
    IpcPayload, MAX_MESSAGE_SIZE,
};
use std::sync::atomic::{AtomicU64, Ordering};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::UnixStream;

/// IPC client for communicating with daemon
pub struct IpcClient {
    message_counter: AtomicU64,
}

impl IpcClient {
    /// Create new IPC client
    pub fn new() -> Self {
        Self { message_counter: AtomicU64::new(1) }
    }

    /// Send command to daemon and wait for response
    ///
    /// Parameters:
    /// * `command` - Command to execute on daemon
    ///
    /// Returns:
    /// Daemon response or error
    ///
    /// Errors:
    /// Returns error if communication fails or daemon returns error
    pub async fn send_command(
        &self,
        command: DaemonCommand,
    ) -> Result<DaemonResponse, IpcError> {
        let message_id = self.message_counter.fetch_add(1, Ordering::Relaxed);
        let message = IpcMessage::new_command(message_id, command);

        // Connect to daemon
        let mut stream = UnixStream::connect(DEFAULT_SOCKET_PATH)
            .await
            .map_err(|error| IpcError::ConnectionFailed(error.to_string()))?;

        // Serialize and send message
        let serialized = bincode::serialize(&message).map_err(|error| {
            IpcError::SerializationFailed(error.to_string())
        })?;

        stream.write_all(&serialized).await?;

        // Read response
        let mut buffer = vec![0; MAX_MESSAGE_SIZE];
        let bytes_read = stream.read(&mut buffer).await?;
        buffer.truncate(bytes_read);

        let response_message: IpcMessage = bincode::deserialize(&buffer)
            .map_err(|error| {
                IpcError::DeserializationFailed(error.to_string())
            })?;

        // Verify response correlation
        if response_message.id != message_id {
            return Err(IpcError::ProtocolError(
                "Message ID mismatch".to_string(),
            ));
        }

        match response_message.payload {
            IpcPayload::Response(response) => Ok(response),
            _ => Err(IpcError::ProtocolError("Expected response".to_string())),
        }
    }

    /// Get daemon status
    pub async fn get_status(&self) -> Result<DaemonResponse, IpcError> {
        self.send_command(DaemonCommand::GetStatus).await
    }

    /// Send echo command for testing
    pub async fn echo(
        &self,
        message: String,
    ) -> Result<DaemonResponse, IpcError> {
        self.send_command(DaemonCommand::Echo { message }).await
    }

    /// Shutdown daemon
    pub async fn shutdown(
        &self,
        force: bool,
    ) -> Result<DaemonResponse, IpcError> {
        self.send_command(DaemonCommand::Shutdown { force }).await
    }
}

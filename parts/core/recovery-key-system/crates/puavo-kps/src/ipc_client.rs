use anyhow::Result;
use async_trait::async_trait;
use puavo_ipc::{
    DEFAULT_SOCKET_PATH, DaemonCommand, DaemonResponse, IpcError, IpcMessage,
    IpcPayload, MAX_MESSAGE_SIZE,
};
use std::sync::atomic::{AtomicU64, Ordering};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::UnixStream;

/// Trait for IPC client communication with daemon
#[async_trait]
pub trait IpcClientTrait: Send + Sync {
    /// Send command to daemon and wait for response
    async fn send_command(
        &self,
        command: DaemonCommand,
    ) -> Result<DaemonResponse, IpcError>;

    /// Get daemon status
    async fn get_status(&self) -> Result<DaemonResponse, IpcError> {
        self.send_command(DaemonCommand::GetStatus).await
    }

    /// Send echo command for testing
    async fn echo(&self, message: String) -> Result<DaemonResponse, IpcError> {
        self.send_command(DaemonCommand::Echo { message }).await
    }

    /// Shutdown daemon
    async fn shutdown(&self, force: bool) -> Result<DaemonResponse, IpcError> {
        self.send_command(DaemonCommand::Shutdown { force }).await
    }
}

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

#[async_trait]
impl IpcClientTrait for IpcClient {
    async fn send_command(
        &self,
        command: DaemonCommand,
    ) -> Result<DaemonResponse, IpcError> {
        self.send_command(command).await
    }
}

#[cfg(test)]
pub mod test_utils {
    use super::*;
    use std::sync::{Arc, Mutex};

    /// Mock IPC client for testing
    pub struct MockIpcClient {
        pub responses: Arc<Mutex<Vec<Result<DaemonResponse, IpcError>>>>,
        pub received_commands: Arc<Mutex<Vec<DaemonCommand>>>,
    }

    impl MockIpcClient {
        /// Create new mock client with predefined responses
        pub fn new(responses: Vec<Result<DaemonResponse, IpcError>>) -> Self {
            Self {
                responses: Arc::new(Mutex::new(responses)),
                received_commands: Arc::new(Mutex::new(Vec::new())),
            }
        }

        /// Get commands received by this mock client
        pub fn received_commands(&self) -> Vec<DaemonCommand> {
            self.received_commands.lock().unwrap().clone()
        }
    }

    #[async_trait]
    impl IpcClientTrait for MockIpcClient {
        async fn send_command(
            &self,
            command: DaemonCommand,
        ) -> Result<DaemonResponse, IpcError> {
            // Record the command
            self.received_commands.lock().unwrap().push(command);

            // Return the next response
            let mut responses = self.responses.lock().unwrap();
            if let Some(response) = responses.pop() {
                response
            } else {
                Err(IpcError::ProtocolError("No more responses".to_string()))
            }
        }
    }
}

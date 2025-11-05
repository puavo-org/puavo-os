use crate::commands::{CommandExecutor, DefaultCommandExecutor};
use crate::config::KpsConfig;
use crate::context::DaemonContext;
use anyhow::Result;
use puavo_ipc::{
    Commands, DEFAULT_SOCKET_PATH, DaemonCommand, DaemonResponse, IpcMessage,
    IpcPayload, MAX_MESSAGE_SIZE,
};
use std::path::Path;
use std::sync::Arc;
use std::time::Instant;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::unix::SocketAddr;
use tokio::net::{UnixListener, UnixStream};
use tokio::signal;
use tokio::sync::mpsc::{self, UnboundedSender};

/// Main daemon structure
pub struct Daemon {
    start_time: Instant,
    context: Arc<DaemonContext>,
}

impl Daemon {
    /// Create new daemon instance
    pub async fn new(config: KpsConfig) -> Result<Self> {
        let context = Arc::new(DaemonContext::new(config)?);
        Ok(Self { start_time: Instant::now(), context })
    }

    /// Run the daemon main loop
    pub async fn run(&self) -> Result<()> {
        // Remove existing socket file if it exists
        if Path::new(DEFAULT_SOCKET_PATH).exists() {
            tokio::fs::remove_file(DEFAULT_SOCKET_PATH).await?;
        }

        let listener = UnixListener::bind(DEFAULT_SOCKET_PATH)?;
        tracing::info!("Daemon listening on {}", DEFAULT_SOCKET_PATH);

        let (shutdown_send, mut shutdown_receive) =
            mpsc::unbounded_channel::<()>();

        loop {
            tokio::select! {
                result = listener.accept() => {
                    self.handle_client_connection(result, shutdown_send.clone()).await;
                }

                _ = signal::ctrl_c() => {
                    tracing::info!("Received terminal shutdown signal");
                    break;
                }

                _ = shutdown_receive.recv() => {
                    tracing::info!("Received shutdown signal");
                    break;
                },
            }
        }

        // Cleanup
        let _ = tokio::fs::remove_file(DEFAULT_SOCKET_PATH).await;
        Ok(())
    }

    /// Handle incoming client connection
    async fn handle_client_connection(
        &self,
        result: std::io::Result<(UnixStream, SocketAddr)>,
        shutdown: UnboundedSender<()>,
    ) {
        match result {
            Ok((stream, _address)) => {
                let handler = ClientHandler::new(
                    stream,
                    shutdown,
                    self.start_time,
                    self.context.clone(),
                );

                // Spawn client handler
                tokio::spawn(async move {
                    if let Err(error) = handler.handle().await {
                        tracing::error!("Client handler error: {}", error);
                    }
                });
            }
            Err(error) => {
                tracing::error!("Accept error: {}", error);
            }
        }
    }
}

/// Handles individual client connections
struct ClientHandler<E: CommandExecutor> {
    stream: UnixStream,
    shutdown: UnboundedSender<()>,
    start_time: Instant,
    context: Arc<DaemonContext>,
    executor: Arc<E>,
}

impl ClientHandler<DefaultCommandExecutor> {
    fn new(
        stream: UnixStream,
        shutdown: UnboundedSender<()>,
        start_time: Instant,
        context: Arc<DaemonContext>,
    ) -> Self {
        Self {
            stream,
            shutdown,
            start_time,
            context,
            executor: Arc::new(DefaultCommandExecutor::new()),
        }
    }
}

impl<E: CommandExecutor> ClientHandler<E> {
    /// Handle client communication
    async fn handle(mut self) -> Result<()> {
        let mut buffer = vec![0; MAX_MESSAGE_SIZE];

        loop {
            let bytes_read = self.stream.read(&mut buffer).await?;

            if bytes_read == 0 {
                break; // Client disconnected
            }

            // Try to deserialize message
            let message: IpcMessage = bincode::deserialize(
                &buffer[..bytes_read],
            )
            .map_err(|error| {
                anyhow::anyhow!("Failed to deserialize message: {}", error)
            })?;

            tracing::debug!(
                "Received message ID {}: {:?}",
                message.id,
                message.payload
            );

            // Process the message
            let response = self.process_message(message).await;

            // Serialize and send response
            let response_bytes =
                bincode::serialize(&response).map_err(|error| {
                    anyhow::anyhow!("Failed to serialize response: {}", error)
                })?;

            self.stream.write_all(&response_bytes).await?;
        }

        tracing::debug!("Client disconnected");
        Ok(())
    }

    /// Process incoming message and generate response
    async fn process_message(&self, message: IpcMessage) -> IpcMessage {
        let response = match message.payload {
            IpcPayload::Command(command) => self.execute_command(command).await,
            _ => DaemonResponse::Error {
                code: "invalid_message".to_string(),
                message: "Expected command".to_string(),
            },
        };

        IpcMessage::new_response(message.id, response)
    }

    /// Execute specific daemon command
    async fn execute_command(&self, command: DaemonCommand) -> DaemonResponse {
        match command {
            DaemonCommand::GetStatus => self.handle_status_command().await,
            DaemonCommand::Echo { message } => {
                self.handle_echo_command(message).await
            }
            DaemonCommand::Shutdown { force } => {
                self.handle_shutdown_command(force).await
            }
            DaemonCommand::Execute(kps_command) => {
                self.handle_kps_command(kps_command).await
            }
        }
    }

    /// Handle status command
    async fn handle_status_command(&self) -> DaemonResponse {
        let uptime = self.start_time.elapsed();
        DaemonResponse::Status {
            uptime_seconds: uptime.as_secs(),
            version: env!("CARGO_PKG_VERSION").to_string(),
        }
    }

    /// Handle echo command
    async fn handle_echo_command(&self, message: String) -> DaemonResponse {
        DaemonResponse::success_with_data(format!("Echo: {}", message))
    }

    /// Handle shutdown command
    async fn handle_shutdown_command(&self, _force: bool) -> DaemonResponse {
        tracing::info!("Shutdown command received");
        let _ = self.shutdown.send(());
        DaemonResponse::success()
    }

    /// Handle KPS commands by delegating to command executor
    async fn handle_kps_command(&self, command: Commands) -> DaemonResponse {
        match command {
            Commands::Initialize { hsm_slot, hsm_pin, force } => {
                self.executor
                    .execute_initialize(
                        self.context.clone(),
                        hsm_slot,
                        hsm_pin,
                        force,
                    )
                    .await
            }

            Commands::Organization { command } => {
                self.executor
                    .execute_organization(self.context.clone(), command)
                    .await
            }

            Commands::Generate {
                operator_id,
                organization_id,
                serial_number,
            } => {
                self.executor
                    .execute_generate(
                        self.context.clone(),
                        operator_id,
                        organization_id,
                        serial_number,
                    )
                    .await
            }

            Commands::Unwrap { operator_id, recovery_bundle } => {
                self.executor
                    .execute_unwrap(
                        self.context.clone(),
                        operator_id,
                        recovery_bundle,
                    )
                    .await
            }

            Commands::Audit { command } => {
                self.executor.execute_audit(self.context.clone(), command).await
            }

            Commands::Operator { command } => {
                self.executor
                    .execute_operator(self.context.clone(), command)
                    .await
            }
        }
    }
}

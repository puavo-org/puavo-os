use crate::cli::{Cli, CliCommands, DaemonCommands, DeviceCommands};
use crate::device::generate_recovery_bundle_local;
use crate::ipc_client::{IpcClient, IpcClientTrait};
use anyhow::Result;
use puavo_ipc::{DaemonCommand, DaemonResponse, IpcError};

/// Execute the specified CLI command
///
/// Parameters:
/// * `cli` - Parsed CLI configuration and command
///
/// Returns:
/// Result indicating success or failure
///
/// Errors:
/// Returns error if command execution fails
pub async fn execute(cli: Cli) -> Result<()> {
    tracing::debug!("Configuration file: {}", cli.socket_path.display());

    match cli.command {
        // Handle daemon commands locally for daemon management
        CliCommands::Daemon { command } => {
            let client = IpcClient::new(cli.socket_path);
            execute_daemon_command_with_client(command, &client).await
        }

        // KPS commands are sent to daemon for execution via IPC
        CliCommands::Kps(command) => {
            let client = IpcClient::new(cli.socket_path);
            let daemon_command = DaemonCommand::Execute(command);
            execute_command_via_daemon(&client, daemon_command).await
        }

        // Device commands are executed locally without daemon
        CliCommands::Device { command } => {
            execute_device_command(command).await
        }
    }
}

/// Execute command by sending it to daemon via IPC
async fn execute_command_via_daemon<T: IpcClientTrait>(
    client: &T,
    command: DaemonCommand,
) -> Result<()> {
    let result = client.send_command(command).await;
    handle_daemon_response(result)
}

/// Execute daemon command with provided client
pub async fn execute_daemon_command_with_client<T: IpcClientTrait>(
    command: DaemonCommands,
    client: &T,
) -> Result<()> {
    let result = match command {
        DaemonCommands::Status => client.get_status().await,
        DaemonCommands::Echo { message } => client.echo(message).await,
        DaemonCommands::Shutdown { force } => client.shutdown(force).await,
    };

    handle_daemon_response(result)
}

/// Handle daemon response with common error handling
///
/// Returns:
/// Result containing success or IPC communication error
fn handle_daemon_response(
    result: Result<DaemonResponse, IpcError>,
) -> Result<()> {
    match result {
        Ok(response) => {
            match response {
                DaemonResponse::Success { data } => {
                    if let Some(message) = data {
                        println!("{}", message);
                    } else {
                        println!("Success");
                    }
                }
                _ => println!("Daemon response: {:?}", response)
            };
            Ok(())
        }
        Err(error) => {
            let error_message =
                format!("Failed to communicate with daemon: {}", error);
            Err(anyhow::anyhow!(error_message))
        }
    }
}

/// Execute device command locally without daemon
///
/// Parameters:
/// * `command` - Device command to execute
///
/// Returns:
/// Result indicating success or failure
///
/// Errors:
/// Returns error if device command execution fails
async fn execute_device_command(command: DeviceCommands) -> Result<()> {
    match command {
        DeviceCommands::Generate {
            organization_id,
            serial_number,
            output,
            recovery_key_file,
        } => {
            generate_recovery_bundle_local(
                organization_id,
                serial_number,
                output,
                recovery_key_file,
            )
            .await?;
            Ok(())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ipc_client::test_utils::MockIpcClient;
    use puavo_ipc::DaemonCommand;

    #[tokio::test]
    async fn test_daemon_status_command() {
        let expected_response = DaemonResponse::Status {
            uptime_seconds: 120,
            version: "0.1.0".to_string(),
        };
        let mock_client = MockIpcClient::new(vec![Ok(expected_response)]);

        let result = execute_daemon_command_with_client(
            DaemonCommands::Status,
            &mock_client,
        )
        .await;

        assert!(result.is_ok());
        let received_commands = mock_client.received_commands();
        assert_eq!(received_commands.len(), 1);
        assert!(matches!(received_commands[0], DaemonCommand::GetStatus));
    }

    #[tokio::test]
    async fn test_daemon_echo_command() {
        let test_message = "Hello, daemon!".to_string();
        let expected_response = DaemonResponse::Success {
            data: Some(format!("Echo: {}", test_message)),
        };
        let mock_client = MockIpcClient::new(vec![Ok(expected_response)]);

        let result = execute_daemon_command_with_client(
            DaemonCommands::Echo { message: test_message.clone() },
            &mock_client,
        )
        .await;

        assert!(result.is_ok());
        let received_commands = mock_client.received_commands();
        assert_eq!(received_commands.len(), 1);
        assert!(matches!(
            received_commands[0],
            DaemonCommand::Echo { ref message } if message == &test_message
        ));
    }

    #[tokio::test]
    async fn test_daemon_shutdown_command() {
        let expected_response = DaemonResponse::Success {
            data: Some("Shutdown initiated".to_string()),
        };
        let mock_client = MockIpcClient::new(vec![Ok(expected_response)]);

        let result = execute_daemon_command_with_client(
            DaemonCommands::Shutdown { force: true },
            &mock_client,
        )
        .await;

        assert!(result.is_ok());
        let received_commands = mock_client.received_commands();
        assert_eq!(received_commands.len(), 1);
        assert!(matches!(
            received_commands[0],
            DaemonCommand::Shutdown { force: true }
        ));
    }

    #[tokio::test]
    async fn test_daemon_communication_error() {
        let mock_client = MockIpcClient::new(vec![Err(
            IpcError::ConnectionFailed("Daemon not running".to_string()),
        )]);

        let result = execute_daemon_command_with_client(
            DaemonCommands::Status,
            &mock_client,
        )
        .await;

        assert!(result.is_err());
        let error_message = result.unwrap_err().to_string();
        assert!(error_message.contains("Failed to communicate with daemon"));
        assert!(error_message.contains("Daemon not running"));

        let received_commands = mock_client.received_commands();
        assert_eq!(received_commands.len(), 1);
        assert!(matches!(received_commands[0], DaemonCommand::GetStatus));
    }
}

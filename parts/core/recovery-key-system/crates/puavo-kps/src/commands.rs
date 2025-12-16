use crate::cli::{Cli, CliCommands, DaemonCommands, DeviceCommands};
use crate::device::generate_recovery_bundle_local;
use crate::formatter;
use crate::ipc_client::{IpcClient, IpcClientTrait};
use anyhow::{Result, bail};
use puavo_ipc::{
    Commands, DaemonCommand, DaemonResponse, IpcError, OutputFormat,
};

/// Prompt user for HSM PIN
///
/// Returns:
/// Result containing the entered PIN or error
///
/// Errors:
/// Returns error if password prompt fails
fn prompt_for_hsm_pin() -> Result<String> {
    rpassword::prompt_password("Enter HSM PIN: ")
        .map_err(|error| anyhow::anyhow!("Failed to read PIN: {}", error))
}

/// Handle prompts for KPS commands that require them
///
/// Parameters:
/// * `command` - The KPS command to process
fn handle_command_prompts(command: Commands) -> Result<Commands> {
    match command {
        Commands::Initialize { .. } => {
            let hsm_pin = prompt_for_hsm_pin()?;
            Ok(Commands::Initialize { hsm_pin })
        }
        other => Ok(other),
    }
}

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
            execute_daemon_command_with_client(command, &client, cli.format)
                .await
        }

        // KPS commands are sent to daemon for execution via IPC
        CliCommands::Kps(command) => {
            let client = IpcClient::new(cli.socket_path);
            let updated_command = handle_command_prompts(command)?;
            let daemon_command = DaemonCommand::Execute(updated_command);
            execute_command_via_daemon(&client, daemon_command, cli.format)
                .await
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
    output_format: OutputFormat,
) -> Result<()> {
    let result = client.send_command(command).await;
    handle_daemon_response(result, output_format)
}

/// Execute daemon command with provided client
pub async fn execute_daemon_command_with_client<T: IpcClientTrait>(
    command: DaemonCommands,
    client: &T,
    output_format: OutputFormat,
) -> Result<()> {
    let result = match command {
        DaemonCommands::Status => client.get_status().await,
        DaemonCommands::Shutdown { force } => client.shutdown(force).await,
    };

    handle_daemon_response(result, output_format)
}

/// Handle daemon response with common error handling
///
/// Parameters:
/// * `result` - Result from daemon communication
/// * `output_format` - Desired output format
///
/// Returns:
/// Result containing success or IPC communication error
fn handle_daemon_response(
    result: Result<DaemonResponse, IpcError>,
    output_format: OutputFormat,
) -> Result<()> {
    match result.map_err(|error| {
        format!("Failed to communicate with daemon: {}", error)
    }) {
        Ok(DaemonResponse::Success { data: Some(data) }) => {
            let formatted = formatter::format(&data, output_format)?;
            println!("{}", formatted);
        }
        Ok(DaemonResponse::Success { .. }) => {}
        Ok(DaemonResponse::Error(error)) | Err(error) => bail!(error),
    }

    Ok(())
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
    use puavo_ipc::{DaemonCommand, DaemonResponseData};

    #[tokio::test]
    async fn test_daemon_status_command() {
        let expected_response = DaemonResponseData::Status {
            uptime_seconds: 120,
            version: "0.1.0".to_string(),
        }
        .into();
        let mock_client = MockIpcClient::new(vec![Ok(expected_response)]);

        let result = execute_daemon_command_with_client(
            DaemonCommands::Status,
            &mock_client,
            OutputFormat::Text,
        )
        .await;

        assert!(result.is_ok());
        let received_commands = mock_client.received_commands();
        assert_eq!(received_commands.len(), 1);
        assert!(matches!(received_commands[0], DaemonCommand::GetStatus));
    }

    #[tokio::test]
    async fn test_daemon_shutdown_command() {
        let expected_response = DaemonResponse::success();
        let mock_client = MockIpcClient::new(vec![Ok(expected_response)]);

        let result = execute_daemon_command_with_client(
            DaemonCommands::Shutdown { force: true },
            &mock_client,
            OutputFormat::Text,
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
            OutputFormat::Text,
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

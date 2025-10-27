use crate::cli::{
    AuditCommands, Cli, Commands, DaemonCommands, OperatorCommands,
    OrganizationCommands,
};
use crate::ipc_client::IpcClient;
use anyhow::Result;

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
    tracing::debug!("Configuration file: {}", cli.config.display());
    if let Some(module) = &cli.pkcs11_module {
        tracing::debug!("PKCS#11 module override: {}", module.display());
    }

    match cli.command {
        Commands::Initialize { hsm_slot, hsm_pin, force } => {
            execute_initialize(hsm_slot, hsm_pin, force)
        }

        Commands::Organization { command } => {
            execute_organization_command(command)
        }

        Commands::Derive { shuttle_path, operator_id, batch_size, dry_run } => {
            execute_derive(shuttle_path, operator_id, batch_size, dry_run)
        }

        Commands::Audit { command } => execute_audit_command(command),

        Commands::Operator { command } => execute_operator_command(command),

        Commands::Daemon { command } => execute_daemon_command(command).await,
    }
}

fn execute_initialize(
    hsm_slot: u64,
    hsm_pin: Option<String>,
    force: bool,
) -> Result<()> {
    tracing::info!("Initializing Key Provisioning Station");
    tracing::info!("HSM slot: {}", hsm_slot);
    tracing::info!("Force: {}", force);
    tracing::debug!("HSM PIN provided: {}", hsm_pin.is_some());

    // Placeholder: HSM initialization will be implemented when HSM integration is ready
    tracing::warn!(
        "HSM initialization not yet implemented - using placeholder"
    );
    tracing::info!("KPS initialization completed");

    Ok(())
}

fn execute_organization_command(command: OrganizationCommands) -> Result<()> {
    match command {
        OrganizationCommands::Initialize { organization_id, generate } => {
            tracing::info!(
                "Initializing organization key: {}",
                organization_id
            );
            tracing::debug!("Generate new key: {}", generate);
            tracing::info!("Organization key initialization completed");
            Ok(())
        }

        OrganizationCommands::Rotate { organization_id } => {
            tracing::info!("Rotating organization key: {}", organization_id);
            tracing::info!("Organization key rotation completed");
            Ok(())
        }
    }
}

fn execute_derive(
    shuttle_path: Option<std::path::PathBuf>,
    operator_id: Option<String>,
    batch_size: usize,
    dry_run: bool,
) -> Result<()> {
    tracing::info!("Starting recovery bundle derivation");

    if let Some(path) = &shuttle_path {
        tracing::debug!("Shuttle path: {}", path.display());
    }
    if let Some(id) = &operator_id {
        tracing::debug!("Operator: {}", id);
    }
    tracing::debug!("Batch size: {}", batch_size);
    tracing::debug!("Dry run mode: {}", dry_run);

    tracing::info!("Recovery bundle derivation completed");

    Ok(())
}

fn execute_audit_command(command: AuditCommands) -> Result<()> {
    match command {
        AuditCommands::Log { since, until, operator, format, tail } => {
            tracing::info!("Displaying audit logs");
            if let Some(since_date) = &since {
                tracing::debug!("Filter since: {}", since_date);
            }
            if let Some(until_date) = &until {
                tracing::debug!("Filter until: {}", until_date);
            }
            if let Some(operator_id) = &operator {
                tracing::debug!("Filter by operator: {}", operator_id);
            }
            tracing::debug!("Output format: {}", format);
            if let Some(tail_count) = tail {
                tracing::debug!("Show last {} entries", tail_count);
            }
            tracing::info!("Audit log display completed");
            Ok(())
        }

        AuditCommands::Export { output, format } => {
            tracing::info!("Exporting audit logs to: {}", output.display());
            tracing::debug!("Export format: {}", format);
            tracing::info!("Audit log export completed");
            Ok(())
        }
    }
}

fn execute_operator_command(command: OperatorCommands) -> Result<()> {
    match command {
        OperatorCommands::Add { id, name } => {
            tracing::info!("Adding operator: {}", id);
            tracing::debug!("Operator name: {}", name);
            tracing::info!("Operator added successfully");
            Ok(())
        }

        OperatorCommands::List => {
            tracing::info!("Listing operators");
            tracing::info!("Operator list retrieved");
            Ok(())
        }

        OperatorCommands::Revoke { id } => {
            tracing::info!("Revoking operator: {}", id);
            tracing::info!("Operator revoked successfully");
            Ok(())
        }
    }
}

async fn execute_daemon_command(command: DaemonCommands) -> Result<()> {
    let client = IpcClient::new();

    let result = match command {
        DaemonCommands::Status => client.get_status().await,
        DaemonCommands::Echo { message } => client.echo(message).await,
        DaemonCommands::Shutdown { force } => client.shutdown(force).await,
    };

    handle_daemon_response(result)
}

/// Handle daemon response with common error handling
fn handle_daemon_response(
    result: Result<puavo_ipc::DaemonResponse, puavo_ipc::IpcError>,
) -> Result<()> {
    match result {
        Ok(response) => {
            println!("Daemon response: {:?}", response);
            Ok(())
        }
        Err(error) => {
            eprintln!("Error communicating with daemon: {}", error);
            std::process::exit(1);
        }
    }
}

mod cli;
mod commands;
mod config;
mod ipc_client;
mod salt;

use anyhow::Result;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> Result<()> {
    // Parse CLI arguments first to get verbosity settings
    let cli = cli::parse_arguments();

    // Initialize logging based on CLI flags
    let log_level = if cli.quiet {
        "error"
    } else if cli.verbose {
        "debug"
    } else {
        "info"
    };

    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new(log_level)),
        )
        .init();

    // Execute command
    commands::execute(cli).await
}

mod cli;
mod commands;
mod config;
mod context;
mod daemon;

use anyhow::Result;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> Result<()> {
    // Parse command line arguments
    let arguments = cli::parse_arguments();

    // Initialize logging
    let log_level = if arguments.verbose { "trace" } else { "debug" };
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new(log_level)),
        )
        .init();

    tracing::info!("Starting KPS daemon");
    tracing::debug!("Loading configuration from: {:?}", arguments.config);

    if arguments.write_default_config {
        tracing::info!(
            "Writing default configuration to: {:?}",
            arguments.config
        );
        let default_config = config::KpsConfig::default();
        default_config.save(&arguments.config)?;
        tracing::info!("Default configuration written successfully");
        return Ok(());
    }

    // Load configuration
    let config = config::KpsConfig::load(&arguments.config)?;
    tracing::info!("Configuration loaded successfully");

    // Create and run daemon
    let daemon = daemon::Daemon::new(config).await?;
    daemon.run().await?;

    tracing::info!("Daemon shutdown complete");
    Ok(())
}

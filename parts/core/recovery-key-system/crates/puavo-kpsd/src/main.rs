mod daemon;

use anyhow::Result;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize logging
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new("debug")),
        )
        .init();

    tracing::info!("Starting KPS daemon");

    // Create and run daemon
    let daemon = daemon::Daemon::new().await?;
    daemon.run().await?;

    tracing::info!("Daemon shutdown complete");
    Ok(())
}

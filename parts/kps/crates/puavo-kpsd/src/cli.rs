use clap::Parser;
use std::path::PathBuf;

const DEFAULT_CONFIG_PATH: &str = "/etc/puavo-kps/config.toml";

#[derive(Parser, Debug)]
#[command(name = "puavo-kpsd")]
#[command(about = "Puavo Key Provisioning Station Daemon", long_about = None)]
#[command(version)]
pub struct Cli {
    /// Path to configuration file
    #[arg(short, long, default_value = DEFAULT_CONFIG_PATH)]
    pub config: PathBuf,

    /// Enable verbose output
    #[arg(short, long)]
    pub verbose: bool,

    /// Write default configuration to the config path and exit
    #[arg(long)]
    pub write_default_config: bool,
}

/// Parse command line arguments
///
/// Returns:
/// Parsed CLI configuration
pub fn parse_arguments() -> Cli {
    Cli::parse()
}

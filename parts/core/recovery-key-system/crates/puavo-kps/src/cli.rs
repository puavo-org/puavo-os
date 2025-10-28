use clap::{Parser, Subcommand};
use std::path::PathBuf;

pub use puavo_ipc::Commands;

#[derive(Parser, Debug)]
#[command(name = "puavo-kps")]
#[command(about = "Puavo Key Provisioning Station", long_about = None)]
#[command(version)]
pub struct Cli {
    /// Path to configuration file
    #[arg(long, global = true, default_value = "/etc/puavo/kps/config.toml")]
    pub config: PathBuf,

    /// PKCS#11 module library path
    #[arg(long, global = true)]
    pub pkcs11_module: Option<PathBuf>,

    /// Enable verbose output
    #[arg(short, long, global = true)]
    pub verbose: bool,

    /// Minimal output
    #[arg(short, long, global = true)]
    pub quiet: bool,

    #[command(subcommand)]
    pub command: CliCommands,
}

/// CLI-level commands (includes daemon management)
#[derive(Subcommand, Debug)]
pub enum CliCommands {
    /// Daemon management commands (handled locally by CLI)
    Daemon {
        #[command(subcommand)]
        command: DaemonCommands,
    },

    /// KPS commands (forwarded to daemon for execution)
    #[command(flatten)]
    Kps(Commands),
}

#[derive(Subcommand, Debug)]
pub enum DaemonCommands {
    /// Get daemon status
    Status,

    /// Test daemon communication
    Echo {
        /// Message to echo
        message: String,
    },

    /// Shutdown daemon
    Shutdown {
        /// Force shutdown without graceful cleanup
        #[arg(long)]
        force: bool,
    },
}

/// Parse command line arguments
///
/// Returns:
/// Parsed CLI configuration and command
pub fn parse_arguments() -> Cli {
    Cli::parse()
}

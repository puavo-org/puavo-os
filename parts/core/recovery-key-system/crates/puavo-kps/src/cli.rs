use clap::{Parser, Subcommand};
use std::path::PathBuf;

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
    pub command: Commands,
}

#[derive(Subcommand, Debug)]
pub enum Commands {
    /// Initialize Key Provisioning Station
    Initialize {
        /// HSM slot number
        #[arg(long, default_value = "0")]
        hsm_slot: u64,

        /// HSM user PIN (will prompt if not provided)
        #[arg(long)]
        hsm_pin: Option<String>,

        /// Overwrite existing configuration
        #[arg(long)]
        force: bool,
    },

    /// Organization key management
    Organization {
        #[command(subcommand)]
        command: OrganizationCommands,
    },

    /// Derive recovery bundles from device salts
    Derive {
        /// Custom shuttle mount point
        #[arg(long)]
        shuttle_path: Option<PathBuf>,

        /// Operator identifier
        #[arg(long)]
        operator_id: Option<String>,

        /// Process N devices at a time
        #[arg(long, default_value = "0")]
        batch_size: usize,

        /// Show what would be done without doing it
        #[arg(long)]
        dry_run: bool,
    },

    /// Audit log management
    Audit {
        #[command(subcommand)]
        command: AuditCommands,
    },

    /// Operator management
    Operator {
        #[command(subcommand)]
        command: OperatorCommands,
    },

    /// Daemon management commands
    Daemon {
        #[command(subcommand)]
        command: DaemonCommands,
    },
}

#[derive(Subcommand, Debug)]
pub enum OrganizationCommands {
    /// Initialize organization key in HSM
    Initialize {
        /// Organization identifier
        #[arg(long)]
        organization_id: String,

        /// Generate new key (default: true)
        #[arg(long, default_value = "true")]
        generate: bool,
    },

    /// Rotate organization key
    Rotate {
        /// Organization identifier
        #[arg(long)]
        organization_id: String,
    },
}

#[derive(Subcommand, Debug)]
pub enum AuditCommands {
    /// Display audit logs
    Log {
        /// Show logs since date (ISO 8601)
        #[arg(long)]
        since: Option<String>,

        /// Show logs until date (ISO 8601)
        #[arg(long)]
        until: Option<String>,

        /// Filter by operator ID
        #[arg(long)]
        operator: Option<String>,

        /// Output format
        #[arg(long, default_value = "text")]
        format: String,

        /// Show last N entries
        #[arg(long)]
        tail: Option<usize>,
    },

    /// Export audit logs
    Export {
        /// Output file path
        #[arg(long)]
        output: PathBuf,

        /// Export format
        #[arg(long, default_value = "jsonl")]
        format: String,
    },
}

#[derive(Subcommand, Debug)]
pub enum OperatorCommands {
    /// Add a new operator
    Add {
        /// Operator identifier (email or username)
        #[arg(long)]
        id: String,

        /// Full name
        #[arg(long)]
        name: String,
    },

    /// List authorized operators
    List,

    /// Revoke operator access
    Revoke {
        /// Operator identifier
        #[arg(long)]
        id: String,
    },
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

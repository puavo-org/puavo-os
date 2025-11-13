/// Main entry point for the Boot Trust Manager application.
///
/// This application manages boot trust state by maintaining a shared LUKS recovery key stored
/// inside a "boot vault" (a LUKS2 filesystem image on the EFI partition).
/// The vault and the primary encrypted system partition share the
/// same unlock policy (TPM-bound tokens and recovery key).
///
/// Configurators are small tasks discovered via JSON trigger
/// configuration files. Each encapsulates a specific maintenance or recovery
/// action such as TPM enrollment or displaying the recovery key.
///
/// This module initializes logging, parses configuration, and delegates management
/// to the `BootTrustManager`.
use std::env;

use clap::{Parser, Subcommand};

use crate::boot_trust_manager::BootTrustManager;

mod boot_trust_manager;
mod configurators;
mod devices;
mod display;
mod error;
mod utils;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct ApplicationConfiguration {
    /// Use console UI instead of Plymouth
    #[arg(long = "force-console")]
    force_console: bool,

    /// Do not reboot after running a configurator
    #[arg(long = "no-reboot")]
    no_reboot: bool,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand, Debug, Clone)]
enum Commands {
    /// Closes the boot vault
    Close {
        /// Path to the boot vault mountpoint
        mountpoint: String,
    },
    /// Run configurators and automatically unmount everything afterwards
    Manage,
    /// Unlock the boot vault and leave it open for external access
    Open {
        /// Device node path containing the EFI partition with boot vault and primary encrypted partition
        #[arg(long = "device")]
        device: Option<String>,
    },
}

fn main() -> Result<(), i32> {
    let _ = env_logger::Builder::from_env(
        env_logger::Env::default().default_filter_or("debug"),
    )
    .format_timestamp_secs()
    .try_init();

    let mut configuration = ApplicationConfiguration::parse();
    configuration.force_console =
        env::var("BOOT_TRUST_MANAGER_FORCE_CONSOLE").is_ok();
    configuration.no_reboot = env::var("BOOT_TRUST_MANAGER_NO_REBOOT").is_ok();

    let command = configuration.command.clone();
    let manager = BootTrustManager::new(configuration);

    match command {
        Commands::Close { mountpoint } => manager.close(mountpoint),
        Commands::Manage => manager.manage(),
        Commands::Open { device } => manager.open(device),
    }
    .map_err(|_| 1)
}

/// Boot Trust Manager entry point.
///
/// Manages boot trust state by maintaining a shared LUKS recovery key stored
/// inside a "boot vault" (a LUKS2 filesystem image on the EFI partition).
/// The vault and the primary encrypted system partition share the
/// same unlock policy (TPM-bound tokens and recovery key).
///
/// Configurators are small tasks discovered via JSON trigger
/// configuration files. Each encapsulates a specific maintenance or recovery
/// action such as TPM enrollment or displaying the recovery key.
/// Each configurator removes its trigger file after execution to
/// prevent repeated runs.
///
/// Initializes logging, parses configuration, and delegates management
/// to the `BootTrustManager`.
use std::env;

use clap::Parser;

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
}

fn main() {
    let _ = env_logger::Builder::from_env(
        env_logger::Env::default().default_filter_or("info"),
    )
    .format_timestamp_secs()
    .try_init();

    let mut configuration = ApplicationConfiguration::parse();
    configuration.force_console =
        env::var("BOOT_TRUST_MANAGER_FORCE_CONSOLE").is_ok();
    configuration.no_reboot = env::var("BOOT_TRUST_MANAGER_NO_REBOOT").is_ok();

    let manager = BootTrustManager::new(configuration);
    manager.manage();
}

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

fn main() -> Result<(), Box<dyn std::error::Error>> {
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
    manager.manage()?;
    Ok(())
}

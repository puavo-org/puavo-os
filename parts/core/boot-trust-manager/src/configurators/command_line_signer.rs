use std::path::Path;
use std::process::Command;

use log::{error, info, warn};

use crate::{
    configurators::Configurator, devices::boot_vault::BootVault,
    display::UserDisplay, error::PuavoError,
    utils::luks_tpm_token_manager::LuksTpmTokenManager,
};

/// Path to the server signing public key. When
/// present in the initramfs, this key is used to
/// verify server authorizations for kernel parameter
/// changes.
const SERVER_PUBLIC_KEY_PATH: &str = "/etc/puavo-conf/server.pub";

/// Path to the initialization script that loads the
/// kernel module and provisions keys.
const INITIALIZE_SCRIPT: &str =
    "/usr/sbin/puavo-command-line-signer-initialize";

/// Configurator that loads the kernel command-line
/// signer module and provisions it with the device
/// Secure Boot private key and server public key.
///
/// This configurator always activates. If
/// initialization fails, it logs a warning and returns
/// success so that other configurators can still run.
pub struct CommandLineSignerConfigurator;

impl CommandLineSignerConfigurator {
    pub fn new() -> Result<Vec<Self>, PuavoError> {
        Ok(vec![CommandLineSignerConfigurator])
    }
}

impl CommandLineSignerConfigurator {
    fn initialize(&self, boot_vault: &mut BootVault) -> Result<(), PuavoError> {
        let secure_boot_key_path =
            boot_vault.resources().secure_boot_private_key_path();

        if !secure_boot_key_path.exists() {
            warn!("Failed to find device Secure Boot private key");
            return Ok(());
        }

        let server_key_path = Path::new(SERVER_PUBLIC_KEY_PATH);

        info!(
            "Initializing kernel command-line signer (server key: {:?}, secure boot key: {:?})",
            server_key_path, secure_boot_key_path,
        );

        let output = Command::new(INITIALIZE_SCRIPT)
            .arg(server_key_path)
            .arg(&secure_boot_key_path)
            .output()
            .map_err(PuavoError::IoError)?;

        if !output.status.success() {
            let standard_error = String::from_utf8_lossy(&output.stderr);
            return Err(PuavoError::ShellError(format!(
                "The kernel command-line signer initialization script failed: {}",
                standard_error,
            )));
        }

        info!("Kernel command-line signer initialized successfully");
        Ok(())
    }
}

impl Configurator for CommandLineSignerConfigurator {
    fn activate(
        &self,
        _boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        // Always activate. The kernel module needs to
        // be loaded and provisioned with keys on every
        // boot.
        Ok(true)
    }

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
        _display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        // Only log errors, so the other configurators can continue.
        self.initialize(boot_vault).inspect_err(|error| {
            error!("Failed to initialize kernel command-line signer: {}", error)
        }).ok();
        Ok(())
    }

    fn name(&self) -> &'static str {
        "CommandLineSignerConfigurator"
    }
}

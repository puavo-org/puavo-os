use std::sync::Arc;

use puavo_hsm::{DEFAULT_PIN, HsmSession, HsmSessionError};
use tokio::sync::Mutex;

use crate::config::KpsConfig;

/// Shared daemon context containing permanent objects
pub struct DaemonContext {
    /// KPS configuration
    config: KpsConfig,

    /// HSM session that persists across requests.
    /// TODO: Investigate multiple sessions through a session manager
    pub hsm_session: Arc<Mutex<HsmSession>>,
}

// HSM sessions
unsafe impl Send for DaemonContext {}
unsafe impl Sync for DaemonContext {}

impl DaemonContext {
    /// Create new daemon context
    ///
    /// Returns:
    /// New daemon context instance
    pub fn new(config: KpsConfig) -> Result<Self, HsmSessionError> {
        let hsm_session = HsmSession::new(
            &config.hsm.module_path,
            &config.hsm.token_label,
            DEFAULT_PIN,
        )?;

        Ok(Self { config, hsm_session: Arc::new(Mutex::new(hsm_session)) })
    }

    /// Get reference to configuration
    pub fn config(&self) -> &KpsConfig {
        &self.config
    }
}

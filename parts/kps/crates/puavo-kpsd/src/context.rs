use std::{sync::Mutex, time::Duration};

use puavo_hsm::{
    HsmSessionError,
    session::{HsmSessionManager, HsmSessionPool},
};
use r2d2::PooledConnection;

use crate::{config::KpsConfig, error::Error};

/// How long to wait for HSM session when acquiring from pool?
pub const SESSION_TIMEOUT_SECONDS: u64 = 4;

/// Shared daemon context containing permanent objects
pub struct DaemonContext {
    /// KPS configuration
    config: KpsConfig,

    /// HSM session pool
    hsm_session_pool: Mutex<Option<HsmSessionPool>>,
}

impl DaemonContext {
    /// Create new daemon context
    ///
    /// Returns:
    /// New daemon context instance
    pub fn new(config: KpsConfig) -> Result<Self, HsmSessionError> {
        Ok(Self { config, hsm_session_pool: Mutex::new(None) })
    }

    /// Initializes the HSM session pool
    ///
    /// Parameters:
    /// * `pin` - HSM PIN to use for sessions
    pub fn initialize_session_pool(&self, pin: String) -> Result<(), Error> {
        let session_manager = HsmSessionManager::new(
            self.config.hsm.module_path.clone(),
            self.config.hsm.token_label.clone(),
            pin,
        );

        let session_pool = HsmSessionPool::builder()
            .build(session_manager)
            .map_err(|error| {
                Error::SessionPoolInitializationFailed(error.to_string())
            })?;

        let mut session_pool_guard = self
            .hsm_session_pool
            .lock()
            .map_err(|_| Error::SessionLockFailure)?;
        let _ = session_pool_guard.insert(session_pool);

        Ok(())
    }

    /// Get HSM session from pool
    ///
    /// Returns:
    /// Pooled HSM session
    ///
    /// Errors:
    /// Returns an error if the session could not be acquired.
    /// This can happen if the session pool is not initialized.
    pub fn get_hsm_session(
        &self,
    ) -> Result<PooledConnection<HsmSessionManager>, Error> {
        let session_pool_guard = self
            .hsm_session_pool
            .lock()
            .map_err(|_| Error::SessionLockFailure)?;

        let session_pool = session_pool_guard
            .as_ref()
            .ok_or(Error::SessionPoolNotInitialized)?;

        session_pool
            .get_timeout(Duration::from_secs(SESSION_TIMEOUT_SECONDS))
            .map_err(|_| Error::SessionAcquisitionTimeout)
    }

    /// Get reference to configuration
    pub fn config(&self) -> &KpsConfig {
        &self.config
    }
}

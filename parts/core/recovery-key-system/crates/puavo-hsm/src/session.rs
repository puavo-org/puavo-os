use cryptoki::context::{CInitializeArgs, Pkcs11};
use cryptoki::session::{Session, UserType};
use cryptoki::types::AuthPin;
use std::path::Path;

/// Errors that can occur during HSM operations
#[derive(Debug, thiserror::Error)]
pub enum HsmSessionError {
    #[error("Failed to initialize PKCS#11 library: {0}")]
    InitializationFailed(String),

    #[error("Failed to open HSM session: {0}")]
    SessionOpenFailed(String),

    #[error("Authentication failed: {0}")]
    AuthenticationFailed(String),

    #[error("HSM slot {0} not found")]
    SlotNotFound(u64),

    #[error("PKCS#11 library not found at path: {0}")]
    LibraryNotFound(String),
}

/// HSM session handle with automatic cleanup
pub struct HsmSession {
    pkcs11: Pkcs11,
    session: Session,
    slot_id: u64,
}

impl HsmSession {
    /// Initialize a new HSM session
    ///
    /// Parameters:
    /// * `module_path` - Path to PKCS#11 module library
    /// * `slot_id` - HSM slot number
    /// * `pin` - User PIN for authentication
    ///
    /// Returns:
    /// Authenticated HSM session
    ///
    /// Errors:
    /// Returns `HsmSessionError` if initialization, session opening, or
    /// authentication fails
    pub fn new(
        module_path: &Path,
        slot_id: u64,
        pin: &str,
    ) -> Result<Self, HsmSessionError> {
        // Check if module exists
        if !module_path.exists() {
            return Err(HsmSessionError::LibraryNotFound(
                module_path.display().to_string(),
            ));
        }

        // Initialize PKCS#11 library
        let pkcs11 = Pkcs11::new(module_path).map_err(|error| {
            HsmSessionError::InitializationFailed(error.to_string())
        })?;

        pkcs11.initialize(CInitializeArgs::OsThreads).map_err(|error| {
            HsmSessionError::InitializationFailed(error.to_string())
        })?;

        // Get slot
        let slot = pkcs11
            .get_slots_with_initialized_token()
            .map_err(|_error| HsmSessionError::SlotNotFound(slot_id))?
            .into_iter()
            .nth(slot_id as usize)
            .ok_or(HsmSessionError::SlotNotFound(slot_id))?;

        // Open session
        let session = pkcs11.open_rw_session(slot).map_err(|error| {
            HsmSessionError::SessionOpenFailed(error.to_string())
        })?;

        // Authenticate
        let pin = AuthPin::new(pin.to_string());
        session.login(UserType::User, Some(&pin)).map_err(|error| {
            HsmSessionError::AuthenticationFailed(error.to_string())
        })?;

        tracing::info!("HSM session initialized for slot {}", slot_id);

        Ok(Self { pkcs11, session, slot_id })
    }

    /// Get reference to the underlying PKCS#11 session
    ///
    /// Returns:
    /// Reference to the PKCS#11 session
    pub fn session(&self) -> &Session {
        &self.session
    }

    /// Get the slot ID
    ///
    /// Returns:
    /// HSM slot identifier
    pub fn slot_id(&self) -> u64 {
        self.slot_id
    }
}

impl Drop for HsmSession {
    fn drop(&mut self) {
        let _ = self.session.logout();
        tracing::debug!("HSM session closed for slot {}", self.slot_id);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_library_not_found() {
        let result = HsmSession::new(
            Path::new("/nonexistent/path/libhsm.so"),
            0,
            "1234",
        );

        assert!(matches!(result, Err(HsmSessionError::LibraryNotFound(_))));
    }
}

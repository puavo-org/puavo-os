use cryptoki::context::Pkcs11;
use cryptoki::error::{Error, RvError};
use cryptoki::session::{Session, UserType};
use cryptoki::slot::Slot;
use cryptoki::types::AuthPin;
use r2d2::ManageConnection;
use std::path::{Path, PathBuf};

use crate::pkcs11;

/// Errors that can occur during HSM operations
#[derive(Debug, thiserror::Error)]
pub enum HsmSessionError {
    #[error("Failed to acquire HSM slot")]
    AcquireSessionFailed,

    #[error("Failed to initialize HSM: {0}")]
    InitializationFailed(Error),

    #[error("No free slots available for token initialization")]
    NoFreeSlots,

    #[error("Token with label '{0}' not found")]
    TokenNotFound(String),

    #[error("Failed to open HSM session: {0}")]
    SessionOpenFailed(Error),

    #[error("Authentication failed: {0}")]
    AuthenticationFailed(Error),
}

/// HSM session handle with automatic cleanup
pub struct HsmSession {
    session: Session,
    slot_id: u64,
}

/// Find slot by token label
///
/// Parameters:
/// * `pkcs11` - PKCS#11 context
/// * `slots` - Available slots to search
/// * `token_label` - Label to match
///
/// Returns:
/// Tuple of the slot and its ID if found
fn find_slot_by_label(
    pkcs11: &Pkcs11,
    slots: &[Slot],
    token_label: &str,
) -> Option<(Slot, u64)> {
    slots
        .iter()
        .enumerate()
        .find(|(_, slot)| {
            pkcs11
                .get_token_info(**slot)
                .map(|token_info| token_info.label().trim() == token_label)
                .unwrap_or(false)
        })
        .map(|(index, slot)| (*slot, index as u64))
}

impl HsmSession {
    /// Initialize a new HSM session
    ///
    /// Parameters:
    /// * `module_path` - Path to PKCS#11 module library
    /// * `token_label` - Token label to find
    /// * `pin` - User PIN for authentication
    ///
    /// Returns:
    /// Authenticated HSM session
    ///
    /// Errors:
    /// Returns `HsmSessionError` if token is not found or authentication fails
    pub fn new(
        module_path: &Path,
        token_label: &str,
        pin: &str,
    ) -> Result<Self, HsmSessionError> {
        // Get or initialize the global PKCS#11 context
        let pkcs11 = pkcs11(module_path);

        // Find slot with matching token label
        let slots = pkcs11
            .get_slots_with_initialized_token()
            .map_err(HsmSessionError::InitializationFailed)?;

        let (slot, slot_id) = find_slot_by_label(&pkcs11, &slots, token_label)
            .ok_or(HsmSessionError::TokenNotFound(token_label.to_string()))?;

        // Open session
        let session = pkcs11
            .open_rw_session(slot)
            .map_err(HsmSessionError::SessionOpenFailed)?;

        // Authenticate
        let pin = AuthPin::new(pin.to_string());
        session
            .login(UserType::User, Some(&pin))
            // If we are already logged in, ignore the error.
            // Only one login is needed for multiple sessions to the same token.
            .or_else(|error| match error {
                Error::Pkcs11(RvError::UserAlreadyLoggedIn, ..) => Ok(()),
                _ => Err(error),
            })
            .map_err(HsmSessionError::AuthenticationFailed)?;

        tracing::info!(
            "HSM session initialized for token '{}' on slot {}",
            token_label,
            slot_id
        );

        Ok(Self { session, slot_id })
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

/// A pool of HSM sessions
pub type HsmSessionPool = r2d2::Pool<HsmSessionManager>;

/// Session manager for HSM connections with error handling
pub struct HsmSessionManager {
    module_path: PathBuf,
    token_label: String,
    pin: String,
}

impl HsmSessionManager {
    /// Create new session manager
    ///
    /// Parameters:
    /// * `module_path` - Path to PKCS#11 module library
    /// * `token_label` - Token label to find
    /// * `pin` - User PIN for session authentication
    ///
    /// Returns:
    /// New HSM session manager instance
    pub fn new(module_path: PathBuf, token_label: String, pin: String) -> Self {
        Self { module_path, token_label, pin }
    }

    /// Attempt to get the slot for the configured token label
    ///
    /// Parameters:
    /// * `pkcs11` - PKCS#11 context
    ///
    /// Returns:
    /// Tuple of the slot and its ID
    ///
    /// Errors:
    /// Returns `HsmSessionError` if the token is not found
    fn get_slot(
        &self,
        pkcs11: &Pkcs11,
    ) -> Result<(Slot, u64), HsmSessionError> {
        // Find the configured slot from all initialized slots
        let slots = pkcs11
            .get_slots_with_initialized_token()
            .map_err(HsmSessionError::InitializationFailed)?;

        let (slot, slot_id) =
            find_slot_by_label(pkcs11, &slots, &self.token_label).ok_or_else(
                || HsmSessionError::TokenNotFound(self.token_label.clone()),
            )?;

        Ok((slot, slot_id))
    }
}

impl ManageConnection for HsmSessionManager {
    type Connection = HsmSession;
    type Error = HsmSessionError;

    /// Attempts to create a new connection
    fn connect(&self) -> Result<Self::Connection, Self::Error> {
        let pkcs11 = pkcs11(&self.module_path);
        let (slot, slot_id) = self.get_slot(&pkcs11)?;

        let session = pkcs11
            .open_rw_session(slot)
            .map_err(HsmSessionError::SessionOpenFailed)?;

        tracing::debug!("Authenticating HSM session on slot {}", slot_id);

        // Authenticate
        let pin = AuthPin::new(self.pin.clone());
        session
            .login(UserType::User, Some(&pin))
            // If we are already logged in, ignore the error.
            // Only one login is needed for multiple sessions to the same token.
            .or_else(|error| match error {
                Error::Pkcs11(RvError::UserAlreadyLoggedIn, ..) => Ok(()),
                _ => Err(error),
            })
            .map_err(HsmSessionError::AuthenticationFailed)?;

        Ok(HsmSession { session, slot_id })
    }

    /// Determines if the connection is still connected to the HSM
    fn is_valid(
        &self,
        connection: &mut Self::Connection,
    ) -> Result<(), Self::Error> {
        connection
            .session
            .get_session_info()
            .map(|_| ())
            .map_err(HsmSessionError::InitializationFailed)
    }

    /// *Quickly* determines if the HSM connection is no longer usable.
    fn has_broken(&self, connection: &mut Self::Connection) -> bool {
        connection.session.get_session_info().is_err()
    }
}

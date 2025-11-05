use cryptoki::context::Pkcs11;
use cryptoki::error::{Error, RvError};
use cryptoki::session::{Session, UserType};
use cryptoki::slot::Slot;
use cryptoki::types::AuthPin;
use std::path::Path;

use crate::pkcs11;

/// Errors that can occur during HSM operations
#[derive(Debug, thiserror::Error)]
pub enum HsmSessionError {
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

use std::sync::OnceLock;
use std::{path::Path, vec};

use cryptoki::session::UserType;
use cryptoki::types::AuthPin;

use crate::{
    DEFAULT_PIN, DEFAULT_SOFTWARE_MODULE, HsmSession, HsmSessionError, pkcs11,
};

/// Shared test token label.
/// All tests use this single token to avoid exhausting SoftHSM slots.
const TEST_TOKEN_LABEL: &str = "puavo-test-token";

/// Ensure test environment is initialized.
/// This initializes the test token and cleans up any leftover objects from
/// previous test runs. Called once on first test.
static TEST_ENVIRONMENT: OnceLock<()> = OnceLock::new();

/// Initialize test environment by ensuring token exists and cleaning up
/// leftover objects
///
/// Errors:
/// Returns error if initialization fails
fn initialize_test_environment() -> Result<(), HsmSessionError> {
    // Ensure the token exists and clean up leftover objects
    tracing::debug!("Initializing test environment");
    ensure_test_token_exists()?;
    cleanup_leftover_objects()?;
    tracing::debug!("Test environment initialized successfully");

    Ok(())
}

/// Clean up leftover objects from previous test runs
fn cleanup_leftover_objects() -> Result<(), HsmSessionError> {
    let module_path = Path::new(DEFAULT_SOFTWARE_MODULE);

    let session = HsmSession::new(module_path, TEST_TOKEN_LABEL, DEFAULT_PIN)
        .inspect_err(|error| {
        tracing::warn!("Failed to open session for cleanup: {}", error);
    })?;

    let template = vec![];
    let objects = session.session().find_objects(&template).unwrap_or(vec![]);

    for object in objects {
        let _ = session.session().destroy_object(object);
    }

    Ok(())
}

/// Ensure the shared test token exists
///
/// Returns:
/// Success if token exists or was created
///
/// Errors:
/// Returns error if token initialization fails
fn ensure_test_token_exists() -> Result<(), HsmSessionError> {
    let module_path = Path::new(DEFAULT_SOFTWARE_MODULE);
    let pkcs11 = pkcs11(module_path);

    // Check if token already exists
    let slots = pkcs11
        .get_slots_with_initialized_token()
        .map_err(HsmSessionError::InitializationFailed)?;

    let token_exists = slots.iter().any(|slot| {
        pkcs11
            .get_token_info(*slot)
            .map(|token_info| token_info.label().trim() == TEST_TOKEN_LABEL)
            .unwrap_or(false)
    });

    if token_exists {
        tracing::debug!("Test token '{}' already exists", TEST_TOKEN_LABEL);
        return Ok(());
    }

    // Token does not exist, create it via PKCS#11 API
    tracing::debug!("Creating test token '{}'", TEST_TOKEN_LABEL);
    initialize_test_token_via_pkcs11()?;

    Ok(())
}

/// Initialize the test token using PKCS#11 API
///
/// Errors:
/// Returns error if token initialization fails
fn initialize_test_token_via_pkcs11() -> Result<(), HsmSessionError> {
    let module_path = Path::new(DEFAULT_SOFTWARE_MODULE);
    let pkcs11 = pkcs11(module_path);

    // Find a free slot (one without an initialized token)
    let all_slots = pkcs11
        .get_all_slots()
        .map_err(HsmSessionError::InitializationFailed)?;

    let free_slot = all_slots
        .iter()
        .find(|slot| {
            pkcs11
                .get_token_info(**slot)
                .map(|info| !info.token_initialized())
                .unwrap_or(true)
        })
        .ok_or(HsmSessionError::NoFreeSlots)?;

    // Initialize the token with SO PIN and label
    let so_pin = AuthPin::new(DEFAULT_PIN.to_string());
    pkcs11
        .init_token(*free_slot, &so_pin, TEST_TOKEN_LABEL)
        .map_err(HsmSessionError::InitializationFailed)?;

    // Open a session and set the user PIN
    let session = pkcs11
        .open_rw_session(*free_slot)
        .map_err(HsmSessionError::SessionOpenFailed)?;

    session
        .login(UserType::So, Some(&so_pin))
        .map_err(HsmSessionError::AuthenticationFailed)?;

    let user_pin = AuthPin::new(DEFAULT_PIN.to_string());
    session
        .init_pin(&user_pin)
        .map_err(HsmSessionError::InitializationFailed)?;

    let _ = session.logout();

    tracing::debug!(
        "Test token '{}' initialized successfully via PKCS#11",
        TEST_TOKEN_LABEL
    );
    Ok(())
}

pub struct TestHsmSession {
    session: HsmSession,
}

impl TestHsmSession {
    /// Create a new test HSM session
    ///
    /// Connects to the shared test token. If the token does not exist, it
    /// will be created automatically. On first call, cleans up any leftover
    /// objects from previous test runs.
    ///
    /// Returns:
    /// Test HSM session
    ///
    /// Errors:
    /// Returns error if token initialization or HSM session creation fails
    pub fn new() -> Result<Self, HsmSessionError> {
        // Initialize test environment on first call
        TEST_ENVIRONMENT.get_or_init(|| {
            initialize_test_environment()
                .expect("Failed to initialize test environment")
        });

        let module_path = Path::new(DEFAULT_SOFTWARE_MODULE);
        let session =
            HsmSession::new(module_path, TEST_TOKEN_LABEL, DEFAULT_PIN)?;

        Ok(Self { session })
    }

    /// Get reference to the HSM session
    pub fn session(&self) -> &HsmSession {
        &self.session
    }

    /// Get the test token label
    pub fn token_label(&self) -> &str {
        TEST_TOKEN_LABEL
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_session() {
        let test_session = TestHsmSession::new().unwrap();
        assert_eq!(test_session.token_label(), TEST_TOKEN_LABEL);
        let _session = test_session.session();
    }

    #[test]
    fn test_multiple_sessions_same_token() {
        let test_session1 = TestHsmSession::new().unwrap();
        let test_session2 = TestHsmSession::new().unwrap();

        let session1 = test_session1.session();
        let session2 = test_session2.session();

        // They both should point to the same token, but be different sessions
        assert_eq!(session1.slot_id(), session2.slot_id());
        assert!(!std::ptr::eq(session1.session(), session2.session()));
    }
}

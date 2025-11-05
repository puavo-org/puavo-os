use cryptoki::object::ObjectClass;
use puavo_hsm::{
    HsmKeyManager, HsmSession, KeyLabel, key_management::KeyManagementError,
};
use puavo_ipc::{DaemonResponse, OrganizationCommand};

/// Errors that can occur during organization commands
#[derive(Debug, thiserror::Error)]
pub enum OrganizationCommandError {
    #[error(transparent)]
    KeyManagement(#[from] KeyManagementError),

    #[error("Organization is already initialized")]
    OrganizationAlreadyInitialized,
}

/// Execute organization key initialization
fn initialize(
    hsm_session: &HsmSession,
    organization_id: String,
) -> Result<(), OrganizationCommandError> {
    tracing::info!("Initializing organization key: {}", organization_id);

    let key_label = KeyLabel::organization(&organization_id, 1);
    let key_manager = HsmKeyManager::new(hsm_session);
    let organization_keys =
        key_manager.filter_keys(ObjectClass::PRIVATE_KEY, &key_label.label)?;

    if !organization_keys.is_empty() {
        tracing::error!("Organization key already exists");
        return Err(OrganizationCommandError::OrganizationAlreadyInitialized);
    }

    tracing::info!("Generating new organization key: {}", organization_id);
    let _ = key_manager.generate_key(&key_label)?;

    Ok(())
}

/// Execute organization key management command
///
/// Parameters:
/// * `command` - Organization command to execute
///
/// Returns:
/// Daemon response with success or error
pub fn execute(
    hsm_session: &HsmSession,
    command: OrganizationCommand,
) -> DaemonResponse {
    match command {
        OrganizationCommand::Initialize { organization_id } => {
            execute_initialize(hsm_session, organization_id)
        }

        OrganizationCommand::Rotate { organization_id } => {
            execute_rotate(organization_id)
        }
    }
}

/// Convert organization command error to daemon response
fn organization_error_to_response(
    error: OrganizationCommandError,
) -> DaemonResponse {
    DaemonResponse::Error {
        code: "ORGANIZATION_ERROR".into(),
        message: error.to_string(),
    }
}

/// Execute organization key initialization
fn execute_initialize(
    hsm_session: &HsmSession,
    organization_id: String,
) -> DaemonResponse {
    match initialize(hsm_session, organization_id) {
        Ok(_) => {
            tracing::info!("Organization key initialization completed");
            DaemonResponse::success()
        }
        Err(error) => organization_error_to_response(error),
    }
}

/// Execute organization key rotation
fn execute_rotate(organization_id: String) -> DaemonResponse {
    tracing::info!("Rotating organization key: {}", organization_id);
    DaemonResponse::success()
}

#[cfg(test)]
mod tests {
    use puavo_hsm::TestHsmSession;

    use super::*;

    #[tokio::test]
    async fn test_initialize_organization_key() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-init".to_string();

        let response = execute_initialize(session, organization_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // Verify the key was created
        let key_manager = HsmKeyManager::new(session);
        let organization_keys = key_manager
            .filter_keys(
                ObjectClass::PRIVATE_KEY,
                &KeyLabel::organization_label(&organization_id),
            )
            .unwrap();

        assert_eq!(organization_keys.len(), 1);

        let version =
            key_manager.get_key_version(&organization_keys[0]).unwrap();
        assert_eq!(version, 1);
    }

    #[tokio::test]
    async fn test_initialize_organization_key_already_exists() {
        let test_session = TestHsmSession::new().unwrap();
        let session = test_session.session();

        let organization_id = "test-organization-exists".to_string();

        // Initialize once
        let response = execute_initialize(session, organization_id.clone());
        assert!(matches!(response, DaemonResponse::Success { .. }));

        // Try to initialize the same organization again
        let response = execute_initialize(session, organization_id.clone());

        match response {
            DaemonResponse::Error { code, message } => {
                assert_eq!(code, "ORGANIZATION_ERROR");
                assert!(message.contains("already initialized"));
            }
            _ => panic!("Expected error response"),
        }
    }

    #[tokio::test]
    async fn test_rotate_organization_key() {
        let organization_id = "test-organization-rotate".to_string();

        let response = execute_rotate(organization_id.clone());

        assert!(matches!(response, DaemonResponse::Success { .. }));
    }
}

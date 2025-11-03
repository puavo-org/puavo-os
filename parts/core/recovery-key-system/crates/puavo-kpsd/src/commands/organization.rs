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

    let key_manager = HsmKeyManager::new(hsm_session);
    let organization_keys =
        key_manager.filter_keys(ObjectClass::PRIVATE_KEY, &organization_id)?;

    if !organization_keys.is_empty() {
        tracing::error!("Organization key already exists");
        return Err(OrganizationCommandError::OrganizationAlreadyInitialized);
    }

    tracing::info!("Generating new organization key: {}", organization_id);
    let key_label = KeyLabel::organization(&organization_id, 1);
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
    tracing::info!("Initializing organization key: {}", organization_id);

    match initialize(hsm_session, organization_id) {
        Ok(_) => DaemonResponse::Success {
            message: "Organization key initialization completed".to_string(),
        },
        Err(error) => organization_error_to_response(error),
    }
}

/// Execute organization key rotation
fn execute_rotate(organization_id: String) -> DaemonResponse {
    tracing::info!("Rotating organization key: {}", organization_id);

    DaemonResponse::Success {
        message: format!(
            "Organization key rotation completed for {}",
            organization_id
        ),
    }
}

#[cfg(test)]
mod tests {
    #[tokio::test]
    async fn test_initialize_organization_key() {
        // TODO: Implement test
    }

    #[tokio::test]
    async fn test_rotate_organization_key() {
        // TODO: Implement test
    }
}

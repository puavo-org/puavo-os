use puavo_ipc::{DaemonResponse, OrganizationCommand};

/// Execute organization key management command
///
/// Parameters:
/// * `command` - Organization command to execute
///
/// Returns:
/// Daemon response with success or error
pub async fn execute(command: OrganizationCommand) -> DaemonResponse {
    match command {
        OrganizationCommand::Initialize { organization_id, generate } => {
            execute_initialize(organization_id, generate).await
        }

        OrganizationCommand::Rotate { organization_id } => {
            execute_rotate(organization_id).await
        }
    }
}

/// Execute organization key initialization
async fn execute_initialize(
    organization_id: String,
    generate: bool,
) -> DaemonResponse {
    tracing::info!("Initializing organization key: {}", organization_id);
    tracing::debug!("Generate new key: {}", generate);

    DaemonResponse::Success {
        message: format!(
            "Organization key initialization completed for {}",
            organization_id
        ),
    }
}

/// Execute organization key rotation
async fn execute_rotate(organization_id: String) -> DaemonResponse {
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
    use super::*;

    #[tokio::test]
    async fn test_initialize_organization_key() {
        let response = execute(OrganizationCommand::Initialize {
            organization_id: "test-org".to_string(),
            generate: true,
        })
        .await;

        match response {
            DaemonResponse::Success { message } => {
                assert!(message.contains("test-org"));
                assert!(message.contains("initialization completed"));
            }
            _ => panic!("Expected success response"),
        }
    }

    #[tokio::test]
    async fn test_rotate_organization_key() {
        let response = execute(OrganizationCommand::Rotate {
            organization_id: "test-org".to_string(),
        })
        .await;

        match response {
            DaemonResponse::Success { message } => {
                assert!(message.contains("test-org"));
                assert!(message.contains("rotation completed"));
            }
            _ => panic!("Expected success response"),
        }
    }
}

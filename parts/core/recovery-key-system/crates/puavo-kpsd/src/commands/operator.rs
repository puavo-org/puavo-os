use puavo_ipc::{DaemonResponse, OperatorCommand};

/// Execute operator management command
///
/// Parameters:
/// * `command` - Operator command to execute
///
/// Returns:
/// Daemon response with success or error
pub async fn execute(command: OperatorCommand) -> DaemonResponse {
    match command {
        OperatorCommand::Add { id, name } => execute_add(id, name).await,
        OperatorCommand::List => execute_list().await,
        OperatorCommand::Revoke { id } => execute_revoke(id).await,
    }
}

/// Execute operator addition
async fn execute_add(id: String, name: String) -> DaemonResponse {
    tracing::info!("Adding operator: {}", id);
    tracing::debug!("Operator name: {}", name);

    DaemonResponse::success()
}

/// Execute operator listing
async fn execute_list() -> DaemonResponse {
    tracing::info!("Listing operators");

    DaemonResponse::success()
}

/// Execute operator revocation
async fn execute_revoke(id: String) -> DaemonResponse {
    tracing::info!("Revoking operator: {}", id);

    DaemonResponse::success()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_add_operator() {
        let response = execute(OperatorCommand::Add {
            id: "operator@example.com".to_string(),
            name: "Test Operator".to_string(),
        })
        .await;

        assert!(matches!(response, DaemonResponse::Success { .. }));
    }

    #[tokio::test]
    async fn test_list_operators() {
        let response = execute(OperatorCommand::List).await;

        assert!(matches!(response, DaemonResponse::Success { .. }));
    }

    #[tokio::test]
    async fn test_revoke_operator() {
        let response = execute(OperatorCommand::Revoke {
            id: "operator@example.com".to_string(),
        })
        .await;

        assert!(matches!(response, DaemonResponse::Success { .. }));
    }
}

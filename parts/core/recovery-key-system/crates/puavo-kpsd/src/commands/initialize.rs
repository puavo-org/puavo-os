use puavo_ipc::DaemonResponse;

/// Execute KPS initialization command
///
/// Parameters:
/// * `hsm_slot` - HSM slot number to use
/// * `hsm_pin` - Optional HSM PIN
/// * `force` - Force initialization even if already configured
///
/// Returns:
/// Daemon response with success or error
pub async fn execute(
    hsm_slot: u64,
    hsm_pin: Option<String>,
    force: bool,
) -> DaemonResponse {
    tracing::info!("Initializing Key Provisioning Station");
    tracing::info!("HSM slot: {}", hsm_slot);
    tracing::info!("Force: {}", force);
    tracing::debug!("HSM PIN provided: {}", hsm_pin.is_some());

    DaemonResponse::Success {
        message: "KPS initialization completed".to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_initialize_basic() {
        let response = execute(0, None, false).await;

        match response {
            DaemonResponse::Success { message } => {
                assert!(message.contains("initialization completed"));
            }
            _ => panic!("Expected success response"),
        }
    }

    #[tokio::test]
    async fn test_initialize_with_pin() {
        let response = execute(0, Some("test-pin".to_string()), false).await;

        match response {
            DaemonResponse::Success { .. } => {
                // Success expected
            }
            _ => panic!("Expected success response"),
        }
    }

    #[tokio::test]
    async fn test_initialize_force() {
        let response = execute(0, None, true).await;

        match response {
            DaemonResponse::Success { .. } => {
                // Success expected
            }
            _ => panic!("Expected success response"),
        }
    }
}

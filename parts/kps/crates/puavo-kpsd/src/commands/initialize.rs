use std::sync::Arc;

use puavo_ipc::DaemonResponse;

use crate::context::DaemonContext;

/// Execute KPS initialization command
///
/// Parameters:
/// * `hsm_pin` - HSM PIN used for session authentication
///
/// Returns:
/// Daemon response with success or error
pub async fn execute(
    context: Arc<DaemonContext>,
    hsm_pin: String,
) -> DaemonResponse {
    tracing::info!("Initializing Key Provisioning Station");

    context
        .initialize_session_pool(hsm_pin)
        .map(|_| DaemonResponse::success())
        .into()
}

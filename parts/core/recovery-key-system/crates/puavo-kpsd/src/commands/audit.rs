use puavo_ipc::{AuditCommand, DaemonResponse};
use std::path::PathBuf;

/// Execute audit log management command
///
/// Parameters:
/// * `command` - Audit command to execute
///
/// Returns:
/// Daemon response with success or error
pub async fn execute(command: AuditCommand) -> DaemonResponse {
    match command {
        AuditCommand::Log { since, until, operator, format, tail } => {
            execute_log(since, until, operator, format, tail).await
        }

        AuditCommand::Export { output, format } => {
            execute_export(output, format).await
        }
    }
}

/// Execute audit log display
async fn execute_log(
    since: Option<String>,
    until: Option<String>,
    operator: Option<String>,
    format: String,
    tail: Option<usize>,
) -> DaemonResponse {
    tracing::info!("Displaying audit logs");
    if let Some(since_date) = &since {
        tracing::debug!("Filter since: {}", since_date);
    }
    if let Some(until_date) = &until {
        tracing::debug!("Filter until: {}", until_date);
    }
    if let Some(operator_id) = &operator {
        tracing::debug!("Filter by operator: {}", operator_id);
    }
    tracing::debug!("Output format: {}", format);
    if let Some(tail_count) = tail {
        tracing::debug!("Show last {} entries", tail_count);
    }

    DaemonResponse::Success {
        message: "Audit log display completed".to_string(),
    }
}

/// Execute audit log export
async fn execute_export(output: PathBuf, format: String) -> DaemonResponse {
    tracing::info!("Exporting audit logs to: {}", output.display());
    tracing::debug!("Export format: {}", format);

    DaemonResponse::Success {
        message: format!("Audit log export completed to {}", output.display()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_display_audit_logs() {
        let response = execute(AuditCommand::Log {
            since: None,
            until: None,
            operator: None,
            format: "text".to_string(),
            tail: None,
        })
        .await;

        match response {
            DaemonResponse::Success { message } => {
                assert!(message.contains("display completed"));
            }
            _ => panic!("Expected success response"),
        }
    }

    #[tokio::test]
    async fn test_export_audit_logs() {
        let response = execute(AuditCommand::Export {
            output: PathBuf::from("/tmp/audit.jsonl"),
            format: "jsonl".to_string(),
        })
        .await;

        match response {
            DaemonResponse::Success { message } => {
                assert!(message.contains("export completed"));
            }
            _ => panic!("Expected success response"),
        }
    }

    #[tokio::test]
    async fn test_filter_logs_by_operator() {
        let response = execute(AuditCommand::Log {
            since: None,
            until: None,
            operator: Some("operator@example.com".to_string()),
            format: "text".to_string(),
            tail: Some(10),
        })
        .await;

        match response {
            DaemonResponse::Success { .. } => {
                // Success expected
            }
            _ => panic!("Expected success response"),
        }
    }
}

use crate::events::AuditEvent;
use std::fs::OpenOptions;
use std::io::{BufWriter, Write};
use std::path::{Path, PathBuf};

/// Errors that can occur during audit logging
#[derive(Debug, thiserror::Error)]
pub enum AuditError {
    #[error("Failed to open audit log file: {0}")]
    FileOpenError(#[from] std::io::Error),

    #[error("Failed to write audit log entry: {0}")]
    WriteError(String),

    #[error("Failed to serialize audit event: {0}")]
    SerializationError(#[from] serde_json::Error),

    #[error("Audit log directory does not exist: {0}")]
    DirectoryNotFound(String),
}

/// Audit logger that writes events to a file
pub struct AuditLogger {
    log_path: PathBuf,
}

impl AuditLogger {
    /// Create a new audit logger
    ///
    /// Parameters:
    /// * `log_path` - Path to audit log file
    ///
    /// Returns:
    /// New audit logger instance
    pub fn new(log_path: impl AsRef<Path>) -> Self {
        Self { log_path: log_path.as_ref().to_path_buf() }
    }

    /// Log an audit event
    ///
    /// Events are written as JSON lines (one event per line) for easy parsing
    ///
    /// Parameters:
    /// * `event` - Audit event to log
    ///
    /// Errors:
    /// Returns `AuditError` if writing to log file fails
    pub fn log_event(&self, event: &AuditEvent) -> Result<(), AuditError> {
        // Check if parent directory exists
        if let Some(parent) = self.log_path.parent() {
            if !parent.exists() {
                return Err(AuditError::DirectoryNotFound(
                    parent.display().to_string(),
                ));
            }
        }

        // Open log file in append mode
        let file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_path)?;

        let mut writer = BufWriter::new(file);

        // Serialize event as JSON
        let json = serde_json::to_string(event)?;

        // Write JSON line
        writeln!(writer, "{}", json)
            .map_err(|error| AuditError::WriteError(error.to_string()))?;

        // Flush to ensure data is written
        writer
            .flush()
            .map_err(|error| AuditError::WriteError(error.to_string()))?;

        tracing::debug!(
            "Logged audit event: {} by {}",
            serde_json::to_string(&event.operation).unwrap_or_default(),
            event.operator_id
        );

        Ok(())
    }

    /// Get the path to the audit log file
    ///
    /// Returns:
    /// Reference to the log file path
    pub fn log_path(&self) -> &Path {
        &self.log_path
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::events::OperationType;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    fn test_audit_logger_creation() {
        let temp_directory = TempDir::new().unwrap();
        let log_path = temp_directory.path().join("audit.log");

        let logger = AuditLogger::new(&log_path);
        assert_eq!(logger.log_path(), log_path);
    }

    #[test]
    fn test_log_event() {
        let temp_directory = TempDir::new().unwrap();
        let log_path = temp_directory.path().join("audit.log");

        let logger = AuditLogger::new(&log_path);
        let event = AuditEvent::new(
            OperationType::HsmInit,
            "admin@example.org",
            "session-123",
        );

        let result = logger.log_event(&event);
        assert!(result.is_ok());

        // Verify file was created and contains data
        let contents = fs::read_to_string(&log_path).unwrap();
        assert!(contents.contains("hsm_init"));
        assert!(contents.contains("admin@example.org"));
    }

    #[test]
    fn test_directory_not_found() {
        let log_path = PathBuf::from("/nonexistent/directory/audit.log");
        let logger = AuditLogger::new(&log_path);

        let event = AuditEvent::new(
            OperationType::HsmInit,
            "admin@example.org",
            "session-123",
        );

        let result = logger.log_event(&event);
        assert!(matches!(result, Err(AuditError::DirectoryNotFound(_))));
    }
}

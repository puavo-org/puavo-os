use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Type of operation being audited
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum OperationType {
    /// HSM initialization
    HsmInit,

    /// Organization key generation
    OrganizationKeyGeneration,

    /// Organization key rotation
    OrganizationKeyRotation,

    /// Recovery bundle derivation
    RecoveryBundleDerivation,

    /// Operator authentication
    OperatorLogin,

    /// Operator logout
    OperatorLogout,

    /// Operator addition
    OperatorAdd,

    /// Operator revocation
    OperatorRevoke,

    /// Configuration change
    ConfigurationChange,
}

/// Audit event record
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditEvent {
    /// Timestamp of the event (ISO 8601 format)
    pub timestamp: DateTime<Utc>,

    /// Type of operation
    pub operation: OperationType,

    /// Operator identifier (email or username)
    pub operator_id: String,

    /// Session identifier (UUID)
    pub session_id: String,

    /// Device salt hash (SHA-256, first 16 characters) for privacy
    #[serde(skip_serializing_if = "Option::is_none")]
    pub device_salt_hash: Option<String>,

    /// Protocol version used
    #[serde(skip_serializing_if = "Option::is_none")]
    pub version: Option<u32>,

    /// Success indicator
    pub success: bool,

    /// Error message if operation failed
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error_message: Option<String>,

    /// Additional metadata as JSON object
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<serde_json::Value>,
}

impl AuditEvent {
    /// Create a new audit event
    ///
    /// Parameters:
    /// * `operation` - Type of operation being audited
    /// * `operator_id` - Identifier of the user performing the operation
    /// * `session_id` - Session identifier
    ///
    /// Returns:
    /// New audit event instance
    pub fn new(
        operation: OperationType,
        operator_id: impl Into<String>,
        session_id: impl Into<String>,
    ) -> Self {
        Self {
            timestamp: Utc::now(),
            operation,
            operator_id: operator_id.into(),
            session_id: session_id.into(),
            device_salt_hash: None,
            version: None,
            success: true,
            error_message: None,
            metadata: None,
        }
    }

    /// Set device salt hash
    ///
    /// Parameters:
    /// * `hash` - Hash of the device salt for privacy-preserving logging
    ///
    /// Returns:
    /// Modified audit event with device salt hash set
    pub fn with_device_salt_hash(mut self, hash: impl Into<String>) -> Self {
        self.device_salt_hash = Some(hash.into());
        self
    }

    /// Set protocol version
    ///
    /// Parameters:
    /// * `version` - Protocol version number
    ///
    /// Returns:
    /// Modified audit event with version set
    pub fn with_version(mut self, version: u32) -> Self {
        self.version = Some(version);
        self
    }

    /// Mark operation as failed
    ///
    /// Parameters:
    /// * `error` - Error message describing the failure
    ///
    /// Returns:
    /// Modified audit event marked as failed with error message
    pub fn with_error(mut self, error: impl Into<String>) -> Self {
        self.success = false;
        self.error_message = Some(error.into());
        self
    }

    /// Add metadata
    ///
    /// Parameters:
    /// * `metadata` - Additional structured data for the audit event
    ///
    /// Returns:
    /// Modified audit event with metadata attached
    pub fn with_metadata(mut self, metadata: serde_json::Value) -> Self {
        self.metadata = Some(metadata);
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_audit_event_creation() {
        let event = AuditEvent::new(
            OperationType::RecoveryBundleDerivation,
            "operator@example.org",
            "session-123",
        );

        assert_eq!(event.operation, OperationType::RecoveryBundleDerivation);
        assert_eq!(event.operator_id, "operator@example.org");
        assert_eq!(event.session_id, "session-123");
        assert!(event.success);
        assert!(event.error_message.is_none());
    }

    #[test]
    fn test_audit_event_with_error() {
        let event = AuditEvent::new(
            OperationType::HsmInit,
            "admin@example.org",
            "session-456",
        )
        .with_error("HSM not found");

        assert!(!event.success);
        assert_eq!(event.error_message, Some("HSM not found".to_string()));
    }

    #[test]
    fn test_audit_event_serialization() {
        let event = AuditEvent::new(
            OperationType::RecoveryBundleDerivation,
            "operator@example.org",
            "session-123",
        )
        .with_device_salt_hash("7f3a9b8c2e1d4f5a")
        .with_version(1);

        let json = serde_json::to_string(&event).unwrap();
        assert!(json.contains("recovery_bundle_derivation"));
        assert!(json.contains("operator@example.org"));
    }
}

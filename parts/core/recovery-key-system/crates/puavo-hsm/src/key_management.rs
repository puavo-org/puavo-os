use crate::session::HsmSession;
use cryptoki::object::{Attribute, ObjectClass, ObjectHandle};

/// Errors that can occur during key management
#[derive(Debug, thiserror::Error)]
pub enum KeyManagementError {
    #[error("Key not found: {0}")]
    KeyNotFound(String),

    #[error("Found multiple keys with same ID: {0}")]
    MultipleKeysFound(String),

    #[error("Key generation failed: {0}")]
    GenerationFailed(String),

    #[error("Key derivation failed: {0}")]
    DerivationFailed(String),

    #[error("HSM operation error: {0}")]
    HsmError(String),

    #[error(transparent)]
    CryptoError(#[from] cryptoki::error::Error),
}

/// Label for HSM keys
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyLabel(String);

impl KeyLabel {
    /// Create a new key label
    ///
    /// Parameters:
    /// * `label` - Label string for the key
    ///
    /// Returns:
    /// New key label instance
    pub fn new(label: impl Into<String>) -> Self {
        Self(label.into())
    }

    /// Organization key label
    ///
    /// Parameters:
    /// * `organization_id` - Unique organization identifier
    ///
    /// Returns:
    /// Key label for the organization
    pub fn organization(organization_id: &str) -> Self {
        Self(format!("puavo-organization-{}", organization_id))
    }

    /// Returns the key label as a string slice
    ///
    /// Returns:
    /// String slice representation of the key label
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// HSM key manager for cryptographic operations
pub struct HsmKeyManager<'a> {
    session: &'a HsmSession,
}

impl<'a> HsmKeyManager<'a> {
    /// Create a new key manager with an existing HSM session
    ///
    /// Parameters:
    /// * `session` - Reference to an authenticated HSM session
    ///
    /// Returns:
    /// New key manager instance
    pub fn new(session: &'a HsmSession) -> Self {
        Self { session }
    }

    /// Generate a new key in the HSM
    ///
    /// Parameters:
    /// * `label` - Key label for identification
    ///
    /// Errors:
    /// Returns `KeyManagementError` if key generation fails
    pub fn generate_key(
        &self,
        label: &KeyLabel,
    ) -> Result<(), KeyManagementError> {
        // TODO: Implement actual PKCS#11 key generation
        tracing::info!("Generating key with label: {}", label.as_str());
        Ok(())
    }

    /// Returns the key associated with the specific label.
    ///
    /// Parameters:
    /// * `label` - Key label for identification
    ///
    /// Errors:
    /// Returns `KeyManagementError` if key is not found or multiple keys are found.
    /// Returns `KeyNotFound` if no key matches the label.
    pub fn get_key(
        &self,
        label: &KeyLabel,
    ) -> Result<ObjectHandle, KeyManagementError> {
        let key_id = &label.0;
        let key_template = vec![
            Attribute::Class(ObjectClass::SECRET_KEY),
            Attribute::Id(key_id.as_bytes().into()),
        ];
        let keys = self.session.session().find_objects(&key_template)?;

        match keys[..] {
            [key] => Ok(key),
            [] => Err(KeyManagementError::KeyNotFound(key_id.clone())),
            _ => Err(KeyManagementError::MultipleKeysFound(key_id.clone())),
        }
    }

    /// Returns a reference to the underlying HSM session
    ///
    /// Returns:
    /// Reference to the HSM session
    pub fn session(&self) -> &HsmSession {
        self.session
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_key_label_organization() {
        let label = KeyLabel::organization("example-organization");
        assert_eq!(label.as_str(), "puavo-organization-example-organization");
    }
}

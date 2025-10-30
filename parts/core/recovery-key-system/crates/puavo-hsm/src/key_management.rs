use std::fmt::{self, Display, Formatter};

use crate::session::HsmSession;
use cryptoki::object::{
    Attribute, AttributeType, KeyType, ObjectClass, ObjectHandle,
};
use rand::RngCore;

/// Errors that can occur during key management
#[derive(Debug, thiserror::Error)]
pub enum KeyManagementError {
    #[error("Key not found: {0}")]
    KeyNotFound(String),

    #[error("Found multiple keys with same ID: {0}")]
    MultipleKeysFound(String),

    #[error("Key version not found")]
    KeyVersionNotFound,

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
pub struct KeyLabel {
    pub label: String,
    pub version: u32,
}

impl KeyLabel {
    /// Create a new key label
    ///
    /// Parameters:
    /// * `label` - Label string for the key
    ///
    /// Returns:
    /// New key label instance
    pub fn new(label: impl Into<String>, version: u32) -> Self {
        Self { label: label.into(), version }
    }

    /// Organization key label
    ///
    /// Parameters:
    /// * `id` - Unique organization identifier
    /// * `version` - Organization key version
    ///
    /// Returns:
    /// Key label for the organization
    pub fn organization(id: &str, version: u32) -> Self {
        Self { label: format!("puavo-organization-{}", id), version }
    }
}

impl Display for KeyLabel {
    fn fmt(&self, formatter: &mut Formatter<'_>) -> fmt::Result {
        write!(formatter, "{}-v{}", self.label, self.version)
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

    /// Generate a new key, store it in the HSM, and return the key value
    ///
    /// Parameters:
    /// * `label` - Key label for identification
    /// * `size` - Key size in bytes
    ///
    /// Errors:
    /// Returns `KeyManagementError` if key generation fails
    pub fn generate_key(
        &self,
        label: &KeyLabel,
        size: usize,
    ) -> Result<Vec<u8>, KeyManagementError> {
        tracing::info!("Generating key with label: {}", label);

        // Generate a random key value
        let mut key_value = vec![0u8; size];
        rand::thread_rng().fill_bytes(&mut key_value);

        // TODO: Fix attributes
        let key_template = vec![
            Attribute::Class(ObjectClass::SECRET_KEY),
            Attribute::KeyType(KeyType::GENERIC_SECRET),
            Attribute::Id(label.label.as_bytes().into()),
            Attribute::Label(label.version.to_le_bytes().into()),
            Attribute::Token(true),
            Attribute::Private(false),
            Attribute::Sensitive(false),
            Attribute::Extractable(true),
            Attribute::Sign(true),
            Attribute::Value(key_value.clone()),
        ];

        self.session.session().create_object(&key_template)?;
        Ok(key_value)
    }

    /// Returns the key associated with the specific label.
    ///
    /// Parameters:
    /// * `key` - Key label for identification
    ///
    /// Errors:
    /// Returns `KeyManagementError` if key is not found or multiple keys are found.
    /// Returns `KeyNotFound` if no key matches the label.
    pub fn get_key_with_version(
        &self,
        key: &KeyLabel,
    ) -> Result<ObjectHandle, KeyManagementError> {
        let key_template = vec![
            Attribute::Class(ObjectClass::SECRET_KEY),
            Attribute::Id(key.label.as_bytes().into()),
            Attribute::Label(key.version.to_le_bytes().into()),
            Attribute::Token(true),
            Attribute::Private(true),
        ];
        let keys = self.session.session().find_objects(&key_template)?;

        match keys[..] {
            [key] => Ok(key),
            [] => Err(KeyManagementError::KeyNotFound(key.label.clone())),
            _ => Err(KeyManagementError::MultipleKeysFound(key.label.clone())),
        }
    }

    /// Returns all keys with the specified prefix.
    ///
    /// Parameters:
    /// * `prefix` - Prefix string to filter keys
    ///
    /// Returns:
    /// List of matching key handles
    pub fn filter_keys(
        &self,
        prefix: &str,
    ) -> Result<Vec<ObjectHandle>, KeyManagementError> {
        let key_template = vec![
            Attribute::Class(ObjectClass::SECRET_KEY),
            Attribute::Id(prefix.as_bytes().into()),
        ];
        let keys = self.session.session().find_objects(&key_template)?;

        Ok(keys)
    }

    /// Returns the version of the specified key.
    ///
    /// Parameters:
    /// * `key_handle` - Handle of the key object
    ///
    /// Returns:
    /// Version number of the key
    pub fn get_key_version(
        &self,
        key_handle: &ObjectHandle,
    ) -> Result<u32, KeyManagementError> {
        let application_attribute = self
            .session
            .session()
            .get_attributes(*key_handle, &[AttributeType::Label])?;

        match &application_attribute[..] {
            [Attribute::Application(application_bytes)] => {
                if application_bytes.len() != 4 {
                    return Err(KeyManagementError::KeyVersionNotFound);
                }

                let version_bytes = &application_bytes[0..4];
                let version =
                    u32::from_le_bytes(version_bytes.try_into().unwrap());
                Ok(version)
            }
            _ => Err(KeyManagementError::KeyVersionNotFound),
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
        let label = KeyLabel::organization("example-organization", 1);
        assert_eq!(
            label.to_string(),
            "puavo-organization-example-organization-v1"
        );
    }
}

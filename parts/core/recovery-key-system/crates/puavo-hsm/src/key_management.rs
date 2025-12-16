use std::fmt::{self, Display, Formatter};

use crate::session::HsmSession;
use cryptoki::{
    mechanism::Mechanism,
    object::{Attribute, AttributeType, KeyType, ObjectClass, ObjectHandle},
};
use rsa::{BigUint, RsaPublicKey};

/// RSA key size in bits
const RSA_KEY_SIZE_BITS: u64 = 4096;

/// This is the most commonly used public exponent for RSA keys. It provides
/// a good balance between security and performance.
const RSA_PUBLIC_EXPONENT: [u8; 3] = [0x01, 0x00, 0x01];

/// Version separator used in key identifiers
const VERSION_SEPARATOR: &str = ":v";

/// Errors that can occur during key management
#[derive(Debug, thiserror::Error)]
pub enum KeyManagementError {
    #[error("Invalid key format")]
    InvalidKeyFormat,

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

    #[error("Failed to extract public key: {0}")]
    PublicKeyExtractionFailed(String),

    #[error("Invalid public key")]
    InvalidPublicKey,

    #[error(transparent)]
    CryptoError(#[from] cryptoki::error::Error),

    #[error("RSA error: {0}")]
    RsaError(#[from] rsa::Error),
}

/// Label for HSM keys
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyLabel {
    pub label: String,
    pub version: u32,
}

const ORGANIZATION_KEY_PREFIX: &str = "puavo-organization-";

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

    /// Base organization key label without version
    ///
    /// Parameters:
    /// * `id` - Unique organization identifier
    ///
    /// Returns:
    /// Base key label for the organization
    pub fn organization_label(id: &str) -> String {
        format!("{}{}", ORGANIZATION_KEY_PREFIX, id)
    }

    /// Returns the organization id from the specified label
    pub fn organization_id_from_label(label: &String) -> Option<&str> {
        label.strip_prefix(ORGANIZATION_KEY_PREFIX)
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
        Self { label: Self::organization_label(id), version }
    }

    /// Generate the versioned identifier for HSM storage
    ///
    /// Returns:
    /// Formatted string combining label and version for use as HSM key ID
    pub fn versioned_id(&self) -> String {
        format!("{}{}{}", self.label, VERSION_SEPARATOR, self.version)
    }

    /// Parse a versioned identifier
    ///
    /// Parameters:
    /// * `versioned_id` - Versioned identifier
    ///
    /// Returns:
    /// The organization label and version number
    ///
    /// Errors:
    /// Returns `InvalidKeyFormat` if the format is incorrect
    pub fn parse(
        versioned_id: &str,
    ) -> Result<(String, u32), KeyManagementError> {
        let parts = versioned_id.split(VERSION_SEPARATOR).collect::<Vec<_>>();

        match parts[..] {
            [label, version] => {
                let version = version
                    .parse::<u32>()
                    .map_err(|_| KeyManagementError::InvalidKeyFormat)?;
                Ok((label.to_owned(), version))
            }
            _ => Err(KeyManagementError::InvalidKeyFormat),
        }
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

    /// Generate a new key pair, store it in the HSM, and return the handles
    ///
    /// Parameters:
    /// * `label` - Key label for identification
    ///
    /// Errors:
    /// Returns `KeyManagementError` if key generation fails
    pub fn generate_key(
        &self,
        label: &KeyLabel,
    ) -> Result<(ObjectHandle, ObjectHandle), KeyManagementError> {
        tracing::info!("Generating key pair with label: {}", label);

        let versioned_id = label.versioned_id();
        let public_exponent = RSA_PUBLIC_EXPONENT.to_vec();

        let public_key_template = vec![
            Attribute::Class(ObjectClass::PUBLIC_KEY),
            Attribute::KeyType(KeyType::RSA),
            Attribute::ModulusBits(RSA_KEY_SIZE_BITS.into()),
            Attribute::PublicExponent(public_exponent),
            Attribute::Id(versioned_id.as_bytes().into()),
            Attribute::Label(label.label.as_bytes().into()),
            Attribute::Token(true),
        ];

        let private_key_template = vec![
            Attribute::Class(ObjectClass::PRIVATE_KEY),
            Attribute::KeyType(KeyType::RSA),
            Attribute::Id(versioned_id.as_bytes().into()),
            Attribute::Label(label.label.as_bytes().into()),
            Attribute::Token(true),
            Attribute::Private(true),
            Attribute::Sensitive(true),
            Attribute::Extractable(true),
            Attribute::Decrypt(true),
            Attribute::WrapWithTrusted(true),
        ];

        let key_handles = self.session.session().generate_key_pair(
            &Mechanism::RsaPkcsKeyPairGen,
            &public_key_template,
            &private_key_template,
        )?;

        Ok(key_handles)
    }

    /// Returns the key associated with the specific label.
    ///
    /// Parameters:
    /// * `key` - Key label for identification
    ///
    /// Returns:
    /// Handle to the private key object
    ///
    /// Errors:
    /// Returns `KeyManagementError` if key is not found or multiple keys are
    /// found.
    pub fn get_key_with_version(
        &self,
        key_class: ObjectClass,
        key: &KeyLabel,
    ) -> Result<ObjectHandle, KeyManagementError> {
        let versioned_id = key.versioned_id();

        let key_template = vec![
            Attribute::Class(key_class),
            Attribute::Id(versioned_id.as_bytes().into()),
            Attribute::Token(true),
        ];
        let keys = self.session.session().find_objects(&key_template)?;

        match keys[..] {
            [key] => Ok(key),
            [] => Err(KeyManagementError::KeyNotFound(versioned_id.clone())),
            _ => {
                Err(KeyManagementError::MultipleKeysFound(versioned_id.clone()))
            }
        }
    }

    /// Returns all keys with the specified label prefix.
    ///
    /// Parameters:
    /// * `label_prefix` - Label prefix string to filter keys
    ///
    /// Returns:
    /// List of matching private key handles with their versions
    pub fn filter_keys(
        &self,
        key_class: ObjectClass,
        label: &str,
    ) -> Result<Vec<ObjectHandle>, KeyManagementError> {
        let key_template = vec![
            Attribute::Class(key_class),
            Attribute::Label(label.as_bytes().into()),
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
    ///
    /// Errors:
    /// Returns `KeyVersionNotFound` if the version cannot be extracted
    pub fn get_key_version(
        &self,
        key_handle: &ObjectHandle,
    ) -> Result<u32, KeyManagementError> {
        let id_attribute = self
            .session
            .session()
            .get_attributes(*key_handle, &[AttributeType::Id])?;

        match &id_attribute[..] {
            [Attribute::Id(id_bytes)] => {
                let id_string = String::from_utf8_lossy(id_bytes);
                KeyLabel::parse(&id_string).map(|(_, version)| version)
            }
            _ => Err(KeyManagementError::InvalidKeyFormat),
        }
    }

    /// Returns the latest version of a key with the specified label.
    ///
    /// Parameters:
    /// * `label` - Base label string without version
    ///
    /// Returns:
    /// Tuple of the handle and version of the latest key, or None if no keys
    ///
    /// Errors:
    /// Returns `KeyManagementError` if HSM operations fail
    pub fn get_latest_key(
        &self,
        key_class: ObjectClass,
        label: &str,
    ) -> Result<Option<(ObjectHandle, u32)>, KeyManagementError> {
        let keys = self.filter_keys(key_class, label)?;

        keys.into_iter()
            .map(|key_handle| {
                let version = self.get_key_version(&key_handle)?;
                Ok((key_handle, version))
            })
            .collect::<Result<Vec<_>, KeyManagementError>>()?
            .into_iter()
            .max_by_key(|(_, version)| *version)
            .map(Ok)
            .transpose()
    }

    /// Returns a reference to the underlying HSM session
    ///
    /// Returns:
    /// Reference to the HSM session
    pub fn session(&self) -> &HsmSession {
        self.session
    }

    /// Extract public key material from HSM for software-based encryption
    ///
    /// Parameters:
    /// * `public_key_handle` - Handle to the public key object in HSM
    ///
    /// Returns:
    /// RSA public key that can be used for software encryption
    ///
    /// Errors:
    /// Returns error if key attributes cannot be retrieved or parsed
    pub fn extract_public_key(
        &self,
        public_key_handle: &ObjectHandle,
    ) -> Result<RsaPublicKey, KeyManagementError> {
        let attributes = self.session.session().get_attributes(
            *public_key_handle,
            &[AttributeType::Modulus, AttributeType::PublicExponent],
        )?;

        let modulus_bytes =
            attributes.iter().find_map(|attribute| match attribute {
                Attribute::Modulus(bytes) => Some(bytes.to_vec()),
                _ => None,
            });
        let exponent_bytes =
            attributes.iter().find_map(|attribute| match attribute {
                Attribute::PublicExponent(bytes) => Some(bytes.to_vec()),
                _ => None,
            });

        let modulus =
            modulus_bytes.ok_or(KeyManagementError::InvalidPublicKey)?;
        let exponent =
            exponent_bytes.ok_or(KeyManagementError::InvalidPublicKey)?;

        let public_key = RsaPublicKey::new(
            BigUint::from_bytes_be(&modulus),
            BigUint::from_bytes_be(&exponent),
        )?;

        Ok(public_key)
    }

    /// List all organization keys stored in the HSM
    ///
    /// Returns:
    /// List of all organization keys with their labels, versions, and handles
    ///
    /// Errors:
    /// Returns error if HSM operations fail
    pub fn list_all_organization_keys(
        &self,
    ) -> Result<Vec<(String, u32, ObjectHandle)>, KeyManagementError> {
        let key_template = vec![
            Attribute::Class(ObjectClass::PUBLIC_KEY),
            Attribute::Token(true),
        ];
        let key_handles = self.session.session().find_objects(&key_template)?;

        let mut organization_keys = Vec::new();

        for key_handle in key_handles {
            tracing::debug!("Inspecting key handle: {:?}", key_handle);

            // Retrieve the ID attribute of the key
            let attributes = self
                .session
                .session()
                .get_attributes(key_handle, &[AttributeType::Id])?;

            // Parse the key label and version from the ID attribute
            let key_info_option = match attributes.first() {
                Some(Attribute::Id(id_bytes)) => {
                    let id = String::from_utf8_lossy(&id_bytes);
                    KeyLabel::parse(&id)
                        .inspect_err(|error| {
                            tracing::error!("Failed to parse key: {}", error)
                        })
                        .ok()
                }
                _ => None,
            };

            // Add to results if parsing was successful
            if let Some((label, version)) = key_info_option {
                organization_keys.push((label, version, key_handle));
            } else {
                tracing::error!("Key did not have valid versioned ID");
            }
        }

        Ok(organization_keys)
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

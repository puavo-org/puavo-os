use rand::RngCore;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256, Sha512};
use std::time::{SystemTime, UNIX_EPOCH};

pub const DEVICE_SALT_VERSION: &str = "1";

/// This structure contains device-specific data that gets hashed to produce
/// the final device salt.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct DeviceSaltSource {
    /// Cryptographic random value
    pub random: String,
    /// Device serial number
    pub serial_number: String,
    /// Timestamp when the salt was generated
    pub timestamp: String,
    /// Version of the salt format
    pub version: String,
    /// Organization ID
    pub organization_id: String,
    /// Organization key version
    pub organization_key_version: u32,
}

/// Hash algorithm choices for device salt hashing
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HashAlgorithm {
    Sha256,
    Sha512,
}

impl Default for HashAlgorithm {
    fn default() -> Self {
        HashAlgorithm::Sha256
    }
}

impl DeviceSaltSource {
    /// Create a new device salt source structure
    ///
    /// Parameters:
    /// * `serial_number` - Device serial number
    /// * `organization_id` - Organization ID
    /// * `organization_key_version` - Organization key version
    ///
    /// Returns:
    /// New DeviceSaltSource with generated random value and current timestamp
    pub fn new(
        serial_number: String,
        organization_id: String,
        organization_key_version: u32,
    ) -> Self {
        let mut random_bytes = vec![0u8; 64];
        rand::thread_rng().fill_bytes(&mut random_bytes);
        let random_hex = hex::encode(random_bytes);

        // Get current timestamp
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();

        Self {
            random: random_hex,
            serial_number,
            timestamp,
            version: DEVICE_SALT_VERSION.to_string(),
            organization_id,
            organization_key_version,
        }
    }

    /// Generate the final device salt by hashing this structure
    ///
    /// Parameters:
    /// * `algorithm` - Hash algorithm to use
    ///
    /// Returns:
    /// Hash of the JSON serialization as hex string
    ///
    /// Errors:
    /// Returns error if JSON serialization fails
    pub fn compute(
        &self,
        algorithm: HashAlgorithm,
    ) -> Result<String, serde_json::Error> {
        let json_string = serde_json::to_string(self)?;
        let hash = match algorithm {
            HashAlgorithm::Sha256 => {
                let hash = Sha256::digest(json_string.as_bytes());
                hex::encode(hash)
            }
            HashAlgorithm::Sha512 => {
                let hash = Sha512::digest(json_string.as_bytes());
                hex::encode(hash)
            }
        };
        Ok(hash)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    pub fn generate_device_salt_with_source(
        serial_number: String,
        organization_id: String,
        organization_key_version: u32,
        algorithm: Option<HashAlgorithm>,
    ) -> Result<(DeviceSaltSource, String), serde_json::Error> {
        let source = DeviceSaltSource::new(
            serial_number,
            organization_id,
            organization_key_version,
        );
        let algorithm = algorithm.unwrap_or_default();
        let final_salt = source.compute(algorithm)?;
        Ok((source, final_salt))
    }

    #[test]
    fn test_device_salt_source_creation() {
        let serial_number = "TEST-DEVICE-123".to_string();
        let organization_id = "test-organization".to_string();
        let organization_key_version = 1;
        let source1 = DeviceSaltSource::new(
            serial_number.clone(),
            organization_id.clone(),
            organization_key_version,
        );
        let source2 = DeviceSaltSource::new(
            serial_number.clone(),
            organization_id.clone(),
            organization_key_version,
        );

        // Same serial number but different random values and timestamps
        assert_eq!(source1.serial_number, source2.serial_number);
        assert_eq!(source1.organization_id, source2.organization_id);
        assert_eq!(
            source1.organization_key_version,
            source2.organization_key_version
        );
        assert_eq!(source1.version, "1");
        assert_eq!(source2.version, "1");
        assert_ne!(source1.random, source2.random);
        assert_eq!(source1.random.len(), 128);
    }

    #[test]
    fn test_device_salt_generation() {
        let serial_number = "TEST-DEVICE-456".to_string();
        let organization_id = "test-organization".to_string();
        let organization_key_version = 1;
        let source = DeviceSaltSource::new(
            serial_number,
            organization_id,
            organization_key_version,
        );

        let salt1 = source.compute(HashAlgorithm::Sha256).unwrap();
        let salt2 = source.compute(HashAlgorithm::Sha256).unwrap();

        // Same source should produce same hash
        assert_eq!(salt1, salt2);
        assert_eq!(salt1.len(), 64); // SHA256 as hex = 64 characters

        // Test SHA512 as well
        let salt3 = source.compute(HashAlgorithm::Sha512).unwrap();
        assert_eq!(salt3.len(), 128); // SHA512 as hex = 128 characters
        assert_ne!(salt1, salt3); // Different algorithms produce different hashes
    }

    #[test]
    fn test_different_sources_produce_different_salts() {
        let (source1, salt1) = generate_device_salt_with_source(
            "DEVICE-001".to_string(),
            "test-organization".to_string(),
            1,
            None,
        )
        .unwrap();
        let (source2, salt2) = generate_device_salt_with_source(
            "DEVICE-002".to_string(),
            "test-organization".to_string(),
            1,
            None,
        )
        .unwrap();

        assert_ne!(source1.serial_number, source2.serial_number);
        assert_ne!(source1.random, source2.random);
        assert_ne!(salt1, salt2);

        // Test with specific algorithm
        let (_source3, salt3) = generate_device_salt_with_source(
            "DEVICE-003".to_string(),
            "test-organization".to_string(),
            1,
            Some(HashAlgorithm::Sha512),
        )
        .unwrap();
        assert_eq!(salt3.len(), 128); // SHA512 produces 128 character hex string
    }

    #[test]
    fn test_json_serialization_roundtrip() {
        let source = DeviceSaltSource {
            random: "a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890".to_string(),
            serial_number: "TEST-DEVICE".to_string(),
            timestamp: "1634567890".to_string(),
            version: "1".to_string(),
            organization_id: "test-organization".to_string(),
            organization_key_version: 1,
        };

        let json = serde_json::to_string(&source).unwrap();
        let deserialized: DeviceSaltSource =
            serde_json::from_str(&json).unwrap();

        assert_eq!(source, deserialized);
    }

    #[test]
    fn test_deterministic_hash_from_same_json() {
        let source = DeviceSaltSource {
            random: "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210".to_string(),
            serial_number: "DETERMINISTIC-TEST".to_string(),
            timestamp: "1000000000".to_string(),
            version: "1".to_string(),
            organization_id: "test-organization".to_string(),
            organization_key_version: 1,
        };

        let hash1 = source.compute(HashAlgorithm::Sha256).unwrap();
        let hash2 = source.compute(HashAlgorithm::Sha256).unwrap();

        assert_eq!(hash1, hash2);
        assert_eq!(hash1.len(), 64);

        let hash3 = source.compute(HashAlgorithm::Sha512).unwrap();
        let hash4 = source.compute(HashAlgorithm::Sha512).unwrap();

        assert_eq!(hash3, hash4);
        assert_eq!(hash3.len(), 128);
        assert_ne!(hash1, hash3); // Different algorithms produce different results
    }
}

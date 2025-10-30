use cryptoki::mechanism::Mechanism;
use sha2::{Digest, Sha256, Sha512};

#[derive(Debug, Clone, Copy)]
pub enum HashAlgorithm {
    Sha1,
    Sha256,
    Sha512,
}

impl HashAlgorithm {
    /// Returns the hash length in bytes
    pub fn hash_length(&self) -> usize {
        match self {
            HashAlgorithm::Sha1 => 20,
            HashAlgorithm::Sha256 => 32,
            HashAlgorithm::Sha512 => 64,
        }
    }

    /// Returns the corresponding PKCS#11 HMAC mechanism
    pub fn hmac_mechanism<'a>(&'a self) -> Mechanism<'a> {
        match self {
            HashAlgorithm::Sha1 => Mechanism::Sha1Hmac,
            HashAlgorithm::Sha256 => Mechanism::Sha256Hmac,
            HashAlgorithm::Sha512 => Mechanism::Sha512Hmac,
        }
    }

    /// Returns digest of the input data
    pub fn digest<T: AsRef<[u8]>>(&self, data: T) -> Vec<u8> {
        let data = data.as_ref();
        match self {
            HashAlgorithm::Sha1 => {
                panic!("SHA1 is not supported for digesting")
            }
            HashAlgorithm::Sha256 => Sha256::digest(data).to_vec(),
            HashAlgorithm::Sha512 => Sha512::digest(data).to_vec(),
        }
    }
}

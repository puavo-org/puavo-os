use cryptoki::object::{Attribute, KeyType, ObjectClass, ObjectHandle};

use crate::{
    key_management::KeyManagementError, mechanisms::hash::HashAlgorithm,
    HsmKeyManager,
};

/// HSM mechanism for HKDF key derivation
pub struct HsmMechanismHkdf<'a> {
    hash_algorithm: HashAlgorithm,
    manager: &'a HsmKeyManager<'a>,
}

/// Result of HKDF key derivation containing both intermediate and final keys
pub struct DerivationResult {
    /// Pseudorandom key from the extract phase
    pub prk: Vec<u8>,
    /// Output keying material from the expand phase
    pub okm: Vec<u8>,
}

/// From RFC 5869:
/// 2.  HMAC-based Key Derivation Function (HKDF)
///
///     HMAC-Hash denotes the HMAC function [HMAC] instantiated with hash
///     function 'Hash'.  HMAC always has two arguments: the first is a key
///     and the second an input (or message).  (Note that in the extract
///     step, 'IKM' is used as the HMAC input, not as the HMAC key.)
/// ...
/// 2.2.  Step 1: Extract
///
///    HKDF-Extract(salt, IKM) -> PRK
///
///    Options:
///       Hash     a hash function; HashLen denotes the length of the
///                hash function output in octets
///
///    Inputs:
///       salt     optional salt value (a non-secret random value);
///                if not provided, it is set to a string of HashLen zeros.
///       IKM      input keying material
///
///    Output:
///       PRK      a pseudorandom key (of HashLen octets)
///
///    The output PRK is calculated as follows:
///
///    PRK = HMAC-Hash(salt, IKM)
///
/// 2.3.  Step 2: Expand
///
///    HKDF-Expand(PRK, info, L) -> OKM
///
///    Options:
///       Hash     a hash function; HashLen denotes the length of the
///                hash function output in octets
///
///    Inputs:
///       PRK      a pseudorandom key of at least HashLen octets
///                (usually, the output from the extract step)
///       info     optional context and application specific information
///                (can be a zero-length string)
///       L        length of output keying material in octets
///                (<= 255*HashLen)
///
///    Output:
///       OKM      output keying material (of L octets)
///
///    The output OKM is calculated as follows:
///
///    N = ceil(L/HashLen)
///    T = T(1) | T(2) | T(3) | ... | T(N)
///    OKM = first L octets of T
///
///    where:
///    T(0) = empty string (zero length)
///    T(1) = HMAC-Hash(PRK, T(0) | info | 0x01)
///    T(2) = HMAC-Hash(PRK, T(1) | info | 0x02)
///    T(3) = HMAC-Hash(PRK, T(2) | info | 0x03)
///    ...
///
///    (where the constant concatenated to the end of each T(n) is a
///    single octet.)
/// ...
/// 3.2.  The 'info' Input to HKDF
///    While the 'info' value is optional in the definition of HKDF, it is
///    often of great importance in applications.  Its main objective is to
///    bind the derived key material to application- and context-specific
///    information.  For example, 'info' may contain a protocol number,
///    algorithm identifiers, user identities, etc.  In particular, it may
///    prevent the derivation of the same keying material for different
///    contexts (when the same input key material (IKM) is used in such
///    different contexts).  It may also accommodate additional inputs to
///    the key expansion part, if so desired (e.g., an application may want
///    to bind the key material to its length L, thus making L part of the
///    'info' field).  There is one technical requirement from 'info': it
///    should be independent of the input key material value IKM.
/// 3.3.  To Skip or not to Skip
///    In some applications, the input key material IKM may already be
///    present as a cryptographically strong key (for example, the premaster
///    secret in TLS RSA cipher suites would be a pseudorandom string,
///    except for the first two octets).  In this case, one can skip the
///    extract part and use IKM directly to key HMAC in the expand step.  On
///    the other hand, applications may still use the extract part for the
///    sake of compatibility with the general case.
/// ...
/// End of RFC 5869
///
/// Discussion:
/// The purpose of the extract part is to produce a fixed-length and
/// high-entropy pseudorandom PRK to protect against weak IKM by using
/// a high-entropy salt.
///
/// In our case organization key is IKM and is already high-entropy,
/// therefore we may skip extract part and use it directly as key
/// for expand part (section 3.3).
///
/// As section 3.2 states, the info value may contain user identities.
/// In our case, we use the info value with user identity to derive
/// user-specific keys.
impl<'a> HsmMechanismHkdf<'a> {
    /// Create a new helper for using HKDF with HSM.
    ///
    /// Parameters:
    /// * `manager` - HSM key manager for cryptographic operations
    /// * `hash_algorithm` - Hash algorithm to use for HKDF operations
    pub fn new(
        manager: &'a HsmKeyManager,
        hash_algorithm: HashAlgorithm,
    ) -> Self {
        Self { manager, hash_algorithm }
    }

    /// Extract phase of HKDF (derive a pseudorandom key from input keying material).
    ///
    /// Parameters:
    /// * `salt` - Optional salt value (non-secret random value)
    /// * `ikm` - Input keying material
    ///
    /// Errors:
    /// Returns `KeyManagementError` if HMAC operation fails or object creation fails
    pub fn extract(
        &self,
        salt: &[u8],
        ikm: &[u8],
    ) -> Result<Vec<u8>, KeyManagementError> {
        let session = self.manager.session().session();

        // If salt is not provided, it should be a string of HashLen zeros (RFC 5869).
        // If salt is shorter than HashLen, it should be padded with zeros (RFC 2104).
        let hash_length = self.hash_algorithm.hash_length();
        let processed_salt = if salt.len() < hash_length {
            let mut padded_salt = salt.to_vec();
            padded_salt.resize(hash_length, 0);
            padded_salt
        } else {
            salt.to_vec()
        };

        // PRK = HMAC-Hash(salt, IKM)
        let prk = session.sign(
            &self.hash_algorithm.hmac_mechanism(),
            session.create_object(&[
                Attribute::Class(ObjectClass::SECRET_KEY),
                Attribute::Token(false),
                Attribute::Private(false),
                Attribute::Sign(true),
                Attribute::KeyType(KeyType::GENERIC_SECRET),
                Attribute::Value(processed_salt),
            ])?,
            ikm,
        )?;

        Ok(prk)
    }

    /// Expand phase of HKDF (derive output keying material from pseudorandom key).
    ///
    /// Parameters:
    /// * `prk` - Pseudorandom key
    /// * `info` - Optional context and application specific information
    /// * `l` - Length of output keying material in octets
    ///
    /// Errors:
    /// Returns `KeyManagementError` if HMAC operation fails
    pub fn expand(
        &self,
        prk: ObjectHandle,
        info: &[u8],
        l: usize,
    ) -> Result<Vec<u8>, KeyManagementError> {
        let session = self.manager.session().session();

        let hash_length = self.hash_algorithm.hash_length();
        assert!(l <= 255 * hash_length);

        let n = l.div_ceil(hash_length);
        let mut t = Vec::new();
        let mut okm = Vec::new();

        for i in 1..(n + 1) {
            // T(i) = HMAC-Hash(PRK, T(i-1) | info | i)
            t = session.sign(
                &self.hash_algorithm.hmac_mechanism(),
                prk,
                &[&t[..], info, &[i as u8]].concat(),
            )?;
            okm.extend_from_slice(&t);
        }

        Ok(okm[..l].to_vec())
    }

    /// Complete HKDF key derivation (extract and expand parts) from RFC 5869.
    ///
    /// Parameters:
    /// * `ikm` - Input keying material
    /// * `salt` - Optional salt value (non-secret random value)
    /// * `info` - Optional context and application specific information
    /// * `l` - Length of output keying material in octets
    ///
    /// Errors:
    /// Returns `KeyManagementError` if extract or expand operations fail
    pub fn derive(
        &self,
        ikm: &[u8],
        salt: &[u8],
        info: &[u8],
        l: usize,
    ) -> Result<DerivationResult, KeyManagementError> {
        let prk_bytes = self.extract(salt, ikm)?;
        let prk = self.manager.session().session().create_object(&[
            Attribute::Class(ObjectClass::SECRET_KEY),
            Attribute::Token(false),
            Attribute::Private(false),
            Attribute::Sign(true),
            Attribute::KeyType(KeyType::GENERIC_SECRET),
            Attribute::Value(prk_bytes.clone()),
        ])?;
        let okm_bytes = self.expand(prk, info, l)?;
        Ok(DerivationResult { prk: prk_bytes, okm: okm_bytes })
    }
}

#[cfg(test)]
mod tests {
    use std::path::Path;

    use crate::{HsmSession, DEFAULT_PIN, DEFAULT_SOFTWARE_MODULE};

    use super::*;

    fn derive(
        hash_algorithm: HashAlgorithm,
        ikm: &str,
        salt: &str,
        info: &str,
        l: usize,
    ) -> Result<DerivationResult, KeyManagementError> {
        let session =
            HsmSession::new(Path::new(DEFAULT_SOFTWARE_MODULE), 0, DEFAULT_PIN)
                .unwrap();

        let manager = HsmKeyManager::new(&session);
        let hkdf = HsmMechanismHkdf::new(&manager, hash_algorithm);

        hkdf.derive(
            &hex::decode(ikm).unwrap(),
            &hex::decode(salt).unwrap(),
            &hex::decode(info).unwrap(),
            l,
        )
    }

    #[test]
    fn test_rfc_case_1() {
        // RFC 5869 Test Case 1
        let DerivationResult { prk, okm } = derive(
            HashAlgorithm::Sha256,
            "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
            "000102030405060708090a0b0c",
            "f0f1f2f3f4f5f6f7f8f9",
            42,
        )
        .unwrap();

        assert_eq!(prk, hex::decode("077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5").unwrap());
        assert_eq!(okm, hex::decode("3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865").unwrap());
    }

    #[test]
    fn test_rfc_case_2() {
        // RFC 5869 Test Case 2
        let DerivationResult { prk, okm } = derive(
            HashAlgorithm::Sha256,
            "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f",
            "606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeaf",
            "b0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
            82
        ).unwrap();

        assert_eq!(prk, hex::decode("06a6b88c5853361a06104c9ceb35b45cef760014904671014a193f40c15fc244").unwrap());
        assert_eq!(okm, hex::decode("b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71cc30c58179ec3e87c14c01d5c1f3434f1d87").unwrap());
    }

    #[test]
    fn test_rfc_case_3() {
        // RFC 5869 Test Case 3
        let DerivationResult { prk, okm } = derive(
            HashAlgorithm::Sha256,
            "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
            "",
            "",
            42,
        )
        .unwrap();

        assert_eq!(prk, hex::decode("19ef24a32c717b167f33a91d6f648bdf96596776afdb6377ac434c1c293ccb04").unwrap());
        assert_eq!(okm, hex::decode("8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8").unwrap());
    }

    #[test]
    fn test_rfc_case_4() {
        // RFC 5869 Test Case 4
        let DerivationResult { prk, okm } = derive(
            HashAlgorithm::Sha1,
            "0b0b0b0b0b0b0b0b0b0b0b",
            "000102030405060708090a0b0c",
            "f0f1f2f3f4f5f6f7f8f9",
            42,
        )
        .unwrap();

        assert_eq!(
            prk,
            hex::decode("9b6c18c432a7bf8f0e71c8eb88f4b30baa2ba243").unwrap()
        );
        assert_eq!(okm, hex::decode("085a01ea1b10f36933068b56efa5ad81a4f14b822f5b091568a9cdd4f155fda2c22e422478d305f3f896").unwrap());
    }

    #[test]
    fn test_rfc_case_5() {
        // RFC 5869 Test Case 5
        let DerivationResult { prk, okm } = derive(
            HashAlgorithm::Sha1,
            "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f",
            "606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeaf",
            "b0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
            82,
        )
        .unwrap();

        assert_eq!(
            prk,
            hex::decode("8adae09a2a307059478d309b26c4115a224cfaf6").unwrap()
        );
        assert_eq!(okm, hex::decode("0bd770a74d1160f7c9f12cd5912a06ebff6adcae899d92191fe4305673ba2ffe8fa3f1a4e5ad79f3f334b3b202b2173c486ea37ce3d397ed034c7f9dfeb15c5e927336d0441f4c4300e2cff0d0900b52d3b4").unwrap());
    }

    #[test]
    fn test_rfc_case_6() {
        // RFC 5869 Test Case 6
        let DerivationResult { prk, okm } = derive(
            HashAlgorithm::Sha1,
            "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
            "",
            "",
            42,
        )
        .unwrap();

        assert_eq!(
            prk,
            hex::decode("da8c8a73c7fa77288ec6f5e7c297786aa0d32d01").unwrap()
        );
        assert_eq!(okm, hex::decode("0ac1af7002b3d761d1e55298da9d0506b9ae52057220a306e07b6b87e8df21d0ea00033de03984d34918").unwrap());
    }

    #[test]
    fn test_rfc_case_7() {
        // RFC 5869 Test Case 7
        let DerivationResult { prk, okm } = derive(
            HashAlgorithm::Sha1,
            "0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c",
            "",
            "",
            42,
        )
        .unwrap();

        assert_eq!(
            prk,
            hex::decode("2adccada18779e7c2077ad2eb19d3f3e731385dd").unwrap()
        );
        assert_eq!(okm, hex::decode("2c91117204d745f3500d636a62f64f0ab3bae548aa53d423b0d1f27ebba6f5e5673a081d70cce7acfc48").unwrap());
    }
}

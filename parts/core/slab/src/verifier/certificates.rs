//! Finds and checks the certificate that made a signature, among the
//! certificates included in the signature.
//!
//! Only one level of issuance is checked. The signer certificate must be
//! issued by the issuer key the caller passes, so no chain is built and no
//! intermediate certificate is followed. The issuer key is trusted as it is,
//! so no certificate of the issuer is checked.

use alloc::vec::Vec;
use cms::cert::CertificateChoices;
use cms::content_info::ContentInfo;
use cms::signed_data::{SignedData, SignerIdentifier, SignerInfo};
use const_oid::db::rfc5280::ID_KP_CODE_SIGNING;
use const_oid::db::rfc5912::{RSA_ENCRYPTION, SHA_256_WITH_RSA_ENCRYPTION};
use der::{Decode, Encode, SliceReader};
use rsa::RsaPublicKey;
use rsa::pkcs1::DecodeRsaPublicKey;
use rsa::pkcs1v15::{Signature, VerifyingKey};
use rsa::signature::Verifier;
use sha2::Sha256;
use x509_cert::Certificate;
use x509_cert::ext::pkix::ExtendedKeyUsage;

/// Returns the certificate of the signer from the certificates included in
/// the signature. Only a signer identified by its issuer and serial number is
/// looked up.
pub fn find_signer_certificate(
    signature: &[u8],
    signer: &SignerInfo,
) -> Option<Certificate> {
    let SignerIdentifier::IssuerAndSerialNumber(signer_identifier) =
        &signer.sid
    else {
        verification!("the signer is not identified by issuer and serial");
        return None;
    };
    let Ok(signer_issuer) = signer_identifier.issuer.to_der() else {
        verification!("failed to encode the issuer of the signer");
        return None;
    };

    let certificate_choices_in_signature = read_certificates(signature)?;
    verification!(
        "the signature includes {} certificates",
        certificate_choices_in_signature.len()
    );
    for certificate_choice in certificate_choices_in_signature.iter() {
        let CertificateChoices::Certificate(certificate) = certificate_choice
        else {
            verification!("skipping an included item that is no certificate");
            continue;
        };
        let to_be_signed = &certificate.tbs_certificate;
        if to_be_signed.serial_number != signer_identifier.serial_number {
            verification!("skipping a certificate with another serial");
            continue;
        }
        let certificate_issuer = to_be_signed.issuer.to_der();
        if !certificate_issuer.is_ok_and(|issuer| issuer == signer_issuer) {
            verification!("skipping a certificate from another issuer");
            continue;
        }

        verification!("found the certificate of the signer");
        return Some(certificate.clone());
    }

    verification!("the signature includes no certificate of its signer");
    None
}

/// Returns whether the issuer key signed the certificate. The key is an RSA
/// public key in PKCS #1 DER form.
pub fn is_issued_by(certificate: &Certificate, issuer_key: &[u8]) -> bool {
    if certificate.signature_algorithm.oid != SHA_256_WITH_RSA_ENCRYPTION {
        verification!("the certificate is not signed with RSA and SHA-256");
        return false;
    }

    let issuer = match RsaPublicKey::from_pkcs1_der(issuer_key) {
        Ok(issuer) => issuer,
        Err(error) => {
            error!("failed to read the issuer key ({error:?})");
            return false;
        }
    };
    let Ok(to_be_signed) = certificate.tbs_certificate.to_der() else {
        verification!("failed to encode the signed part of the certificate");
        return false;
    };
    let Some(signature_bytes) = certificate.signature.as_bytes() else {
        verification!("the signature on the certificate is malformed");
        return false;
    };
    let Ok(certificate_signature) = Signature::try_from(signature_bytes) else {
        verification!("the signature on the certificate is malformed");
        return false;
    };

    VerifyingKey::<Sha256>::new(issuer)
        .verify(&to_be_signed, &certificate_signature)
        .is_ok()
}

/// Returns whether the extended key usage of the certificate allows code
/// signing.
pub fn allows_code_signing(certificate: &Certificate) -> bool {
    match certificate.tbs_certificate.get::<ExtendedKeyUsage>() {
        Ok(Some((_, purposes))) => {
            purposes.0.iter().any(|purpose| *purpose == ID_KP_CODE_SIGNING)
        }
        _ => false,
    }
}

/// Returns the public key of the certificate.
pub fn read_public_key(certificate: &Certificate) -> Option<RsaPublicKey> {
    let key = &certificate.tbs_certificate.subject_public_key_info;
    if key.algorithm.oid != RSA_ENCRYPTION {
        verification!("the certificate does not hold an RSA key");
        return None;
    }

    match RsaPublicKey::from_pkcs1_der(key.subject_public_key.as_bytes()?) {
        Ok(public_key) => Some(public_key),
        Err(error) => {
            verification!("failed to read the certificate key ({error:?})");
            None
        }
    }
}

/// Returns the certificates included in a signature.
fn read_certificates(signature: &[u8]) -> Option<Vec<CertificateChoices>> {
    // A signer may pad the signature to 8 bytes, as Microsoft does for shim.
    // Decoding through a reader ignores the padding, which from_der would
    // refuse as trailing data.
    let Ok(mut reader) = SliceReader::new(signature) else {
        verification!("the signature is too large to read");
        return None;
    };
    let Ok(content) = ContentInfo::decode(&mut reader) else {
        verification!("failed to read the signature content");
        return None;
    };
    let Ok(signed_data) = content.content.decode_as::<SignedData>() else {
        verification!("failed to read the signed data of the signature");
        return None;
    };

    let Some(certificates) = signed_data.certificates else {
        verification!("the signature includes no certificates");
        return None;
    };
    Some(certificates.0.into_vec())
}

#[cfg(test)]
mod tests {
    //! unit.sh generates the files these tests read.

    use super::*;
    use der::asn1::BitString;
    use std::env;
    use std::fs;
    use std::path::Path;
    use std::sync::LazyLock;

    /// The variable naming the directory of the generated files.
    const FIXTURES_VARIABLE: &str = "FIXTURES_DIRECTORY";

    static SIGNATURE: LazyLock<Vec<u8>> =
        LazyLock::new(|| read_fixture("signature.pkcs7"));
    static ISSUER: LazyLock<Vec<u8>> =
        LazyLock::new(|| read_fixture("issuer.der"));
    static UNTRUSTED: LazyLock<Vec<u8>> =
        LazyLock::new(|| read_fixture("untrusted.der"));
    static ISSUER_CERTIFICATE: LazyLock<Vec<u8>> =
        LazyLock::new(|| read_fixture("issuer-certificate.der"));

    #[test]
    fn the_certificate_of_the_signer_is_found() {
        assert!(find_signer_certificate(&SIGNATURE, &read_signer()).is_some());
    }

    #[test]
    fn a_padded_signature_is_read() {
        let mut padded = SIGNATURE.clone();
        padded.extend_from_slice(&[0; 7]);
        assert!(find_signer_certificate(&padded, &read_signer()).is_some());
    }

    #[test]
    fn the_certificate_of_the_signer_holds_a_key() {
        let certificate = read_signer_certificate();
        assert!(read_public_key(&certificate).is_some());
    }

    #[test]
    fn a_certificate_is_issued_by_its_issuer() {
        let certificate = read_signer_certificate();
        assert!(is_issued_by(&certificate, &ISSUER));
    }

    #[test]
    fn a_certificate_is_not_issued_by_an_untrusted_key() {
        let certificate = read_signer_certificate();
        assert!(!is_issued_by(&certificate, &UNTRUSTED));
    }

    #[test]
    fn an_altered_certificate_is_not_issued_by_its_issuer() {
        let altered = alter_signature(&read_signer_certificate());
        assert!(!is_issued_by(&altered, &ISSUER));
    }

    #[test]
    fn a_signing_certificate_allows_code_signing() {
        let certificate = read_signer_certificate();
        assert!(allows_code_signing(&certificate));
    }

    #[test]
    fn an_issuer_certificate_does_not_allow_code_signing() {
        let issuer = Certificate::from_der(&ISSUER_CERTIFICATE).unwrap();
        assert!(!allows_code_signing(&issuer));
    }

    #[test]
    fn a_signature_cut_short_is_refused() {
        let signer = read_signer();
        for length in (0..SIGNATURE.len()).step_by(7) {
            let truncated = &SIGNATURE[..length];
            assert!(find_signer_certificate(truncated, &signer).is_none());
        }
    }

    #[test]
    fn bytes_that_are_not_a_signature_are_refused() {
        for filler in [0x00, 0x30, 0xff] {
            let nonsense = [filler; 512];
            assert!(
                find_signer_certificate(&nonsense, &read_signer()).is_none()
            );
        }
    }

    /// Returns the signer of the signature, which identifies its certificate.
    fn read_signer() -> SignerInfo {
        let mut reader = SliceReader::new(&SIGNATURE).unwrap();
        let content = ContentInfo::decode(&mut reader).unwrap();
        let signed_data = content.content.decode_as::<SignedData>().unwrap();
        signed_data.signer_infos.0.as_slice()[0].clone()
    }

    /// Returns the certificate of the signer, which the signature includes.
    fn read_signer_certificate() -> Certificate {
        find_signer_certificate(&SIGNATURE, &read_signer()).unwrap()
    }

    /// Returns a copy of the certificate with its signature altered.
    fn alter_signature(certificate: &Certificate) -> Certificate {
        let mut altered = certificate.clone();
        let mut signature = certificate.signature.as_bytes().unwrap().to_vec();
        signature[0] ^= 1;
        altered.signature = BitString::from_bytes(&signature).unwrap();
        altered
    }

    /// Reads a generated file.
    fn read_fixture(name: &str) -> Vec<u8> {
        let directory = env::var(FIXTURES_VARIABLE).unwrap_or_else(|_| {
            panic!("{FIXTURES_VARIABLE} is not set, run unit.sh")
        });
        let file = Path::new(&directory).join(name);
        fs::read(&file)
            .unwrap_or_else(|error| panic!("failed to read {file:?}: {error}"))
    }
}

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

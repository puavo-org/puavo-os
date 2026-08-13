//! Implements a Secure Boot verifier against built-in authorities.
//! The verifier expects RSA SHA256 signatures.
//! In addition to verification, the implementation also uses TPM
//! to record the approved images and associated authorities.
//!
//! ```text
//!  +- PE FILE ------------------------------------------------+
//!  |  Headers and sections hashed except for the checksum     |
//!  |  and few other entries, such as the attribute            |
//!  |  certificate table below ........................ A      |
//!  |                                                          |
//!  | +- Attribute certificate table ------------------------+ |
//!  | | +- PKCS#7 SignedData #1 ---------------------------+ | |
//!  | | |  eContent = SpcIndirectDataContent               | | |
//!  | | |     The digest of the file .................. A' | | |
//!  | | |                                                  | | |
//!  | | |  signerInfos[0]                                  | | |
//!  | | |     signedAttrs ............................. B  | | |
//!  | | |        contentType = SPC_INDIRECT_DATA           | | |
//!  | | |        messageDigest ........................ B' | | |
//!  | | |     signature over signedAttrs .............. S  | | |
//!  | | |     certificates                                 | | |
//!  | | +--------------------------------------------------+ | |
//!  | |                         ...                          | |
//!  | | +- PKCS#7 SignedData #N ---------------------------+ | |
//!  | | |                       ...                        | | |
//!  | | +--------------------------------------------------+ | |
//!  | +------------------------------------------------------+ |
//!  +----------------------------------------------------------+
//! ```
//!
//! 1. Digest A equals A', so the signature is about this file
//! 2. The digest of eContent equals B', so B is about that content
//! 3. S verifies over B with one of the keys built in here
//! 4. That key says which authority approved the file
//!
//! Read upwards: a key we hold signed the attributes, the attributes commit to
//! the content, and the content commits to the file. Only checks 3 and 4 do any
//! cryptography, the first two compare stored bytes.

mod records;

use crate::debug;
use crate::rollback;
use authenticode::SPC_INDIRECT_DATA_OBJID;
use authenticode::{
    AttributeCertificateIterator, AuthenticodeSignature, PeTrait,
    authenticode_digest,
};
use cms::signed_data::SignerInfo;
use const_oid::ObjectIdentifier;
use const_oid::db::rfc5912::{
    ID_SHA_256, RSA_ENCRYPTION, SHA_256_WITH_RSA_ENCRYPTION,
};
use const_oid::db::rfc6268::{ID_CONTENT_TYPE, ID_MESSAGE_DIGEST};
use core::sync::atomic::{AtomicUsize, Ordering};
use der::asn1::{Any, OctetString};
use der::{Decode, Encode};
use object::read::pe::{ImageOptionalHeader, PeFile64};
use rsa::RsaPublicKey;
use rsa::pkcs1::DecodeRsaPublicKey;
use rsa::pkcs1v15::{Signature, VerifyingKey};
use rsa::signature::Verifier;
use sha2::{Digest, Sha256};
use uefi::Guid;

/// Someone whose signature is accepted here, and the keys they sign with.
struct Authority {
    identity: [u8; 16],
    keys: &'static [&'static [u8]],
}

/// An authority that approved an image, and the bit that says whether it has
/// been recorded yet.
struct Approval {
    authority: &'static Authority,
    bit: usize,
}

// Embed the built-in authorities here.
include!(concat!(env!("OUT_DIR"), "/authorities.rs"));

// One bit per authority, so an authority already recorded is not recorded again.
const _: () = assert!(
    AUTHORITIES.len() <= usize::BITS as usize,
    "more authorities than there are bits to remember them by"
);
static RECORDED: AtomicUsize = AtomicUsize::new(0);

/// Where the image expects to be placed in memory, which belongs in the record
/// of an image the machine is asked to run. Zero when the image does not specify.
fn link_time_address(image: &[u8]) -> u64 {
    PeFile64::parse(image)
        .map(|view| view.nt_headers().optional_header.image_base())
        .unwrap_or(0)
}

/// Logs all built-in authorities to debug output.
pub fn describe() {
    debug!("built in authorities: {}", AUTHORITIES.len());
    for authority in AUTHORITIES {
        debug!(
            "  identity {}, keys: {}",
            Guid::from_bytes(authority.identity),
            authority.keys.len()
        );
        for key in authority.keys {
            debug!("    key {}", debug::hex(&Sha256::digest(key)));
        }
    }
}

/// Returns whether one of the built-in keys accepts the image.
/// An image that is accepted is recorded together with the authority
/// behind it, and a decision that cannot be recorded is refused.
pub fn trusts(image: &[u8], device_path: &[u8]) -> bool {
    let Ok(view) = PeFile64::parse(image) else {
        error!("the image is not readable as a program, refusing");
        return false;
    };
    let signatures = match AttributeCertificateIterator::new(&view) {
        Ok(Some(signatures)) => signatures,
        Ok(None) => {
            verification!("the image carries no signature of its own");
            return false;
        }
        Err(error) => {
            error!("the image hides its signature ({error:?}), refusing");
            return false;
        }
    };

    // An image may carry several signatures, so each is tried until one is
    // approved by a built-in authority. The rest are then left unexamined.
    for attribute_certificate in signatures {
        let attribute_certificate = match attribute_certificate {
            Ok(attribute_certificate) => attribute_certificate,
            Err(error) => {
                verification!("skipping an unreadable signature ({error:?})");
                continue;
            }
        };
        let signature = match attribute_certificate.get_authenticode_signature()
        {
            Ok(signature) => signature,
            Err(error) => {
                verification!(
                    "skipping a signature that cannot be read ({error:?})"
                );
                continue;
            }
        };

        let Some(approval) = approving_authority(&view, &signature) else {
            continue;
        };
        if !record(&approval, image, device_path) {
            return false;
        }
        return true;
    }

    // No built-in authority approved the image.
    // This is not a security violation yet as another verifier may still succeed.
    false
}

/// Upon success returns which built-in authority approved the image.
fn approving_authority(
    view: &PeFile64,
    signature: &AuthenticodeSignature,
) -> Option<Approval> {
    let signer = signature.signer_info();
    if !uses_sha256_with_rsa(signer) {
        verification!("expected an RSA signature over a SHA-256 digest");
        return None;
    }

    // Check 1:
    // The digest of the file against the one stored in SpcIndirectDataContent.
    let mut digest = Sha256::new();
    if let Err(error) = authenticode_digest(view as &dyn PeTrait, &mut digest) {
        error!("the image cannot be hashed as a program ({error:?}), refusing");
        return None;
    }
    if digest.finalize().as_slice() != signature.digest() {
        verification!("the image is not the one the signature was made for");
        return None;
    }

    // Fetch the eContent data, which are the SpcIndirectDataContent above.
    let Some(signed_content) = signature.encapsulated_content() else {
        verification!("the signature says nothing about what was signed");
        return None;
    };

    // Verify the signed attributes has the expected content type.
    match approved_content_type(signer) {
        Some(content_type) if content_type == SPC_INDIRECT_DATA_OBJID => {}
        Some(_) => {
            verification!("the signer approved another kind of content");
            return None;
        }
        None => {
            verification!("the signature does not say what kind of content");
            return None;
        }
    }

    // Check 2:
    // The messageDigest attribute of signedAttrs against the whole
    // eContent, which is what ties those attributes to file contents.
    let Some(approved) = approved_digest(signer) else {
        verification!("the signature does not say what the signer approved");
        return None;
    };
    if Sha256::digest(signed_content).as_slice() != approved.as_bytes() {
        verification!("the signer approved something else");
        return None;
    }

    // Convert signedAttrs to DER, which puts back its natural SET OF tag, the
    // form the signature was made over.
    let approval = match signer.signed_attrs.as_ref().map(Encode::to_der) {
        Some(Ok(approval)) => approval,
        Some(Err(error)) => {
            error!("what the signer approved cannot be read back ({error:?})");
            return None;
        }
        None => {
            verification!("the signature carries no approval to check");
            return None;
        }
    };
    // The signature value of SignerInfo, made over the bytes above.
    let signature = match Signature::try_from(signature.signature()) {
        Ok(signature) => signature,
        Err(error) => {
            verification!("the signature itself is malformed ({error:?})");
            return None;
        }
    };

    // Checks 3 and 4.
    authority_that_signed(&approval, &signature)
}

/// The authority whose key made the approval, if one of them here did.
fn authority_that_signed(
    approval: &[u8],
    signature: &Signature,
) -> Option<Approval> {
    for (index, authority) in AUTHORITIES.iter().enumerate() {
        for key in authority.keys {
            let public_key = match RsaPublicKey::from_pkcs1_der(key) {
                Ok(public_key) => public_key,
                Err(error) => {
                    error!("a built-in key is unreadable ({error:?})");
                    continue;
                }
            };
            if VerifyingKey::<Sha256>::new(public_key)
                .verify(approval, signature)
                .is_ok()
            {
                // The shift stays in range because the assertion above
                // keeps the table no longer than there are bits to shift by.
                return Some(Approval { authority, bit: 1 << index });
            }
        }
    }
    verification!(
        "none of the {} built-in authorities made this approval",
        AUTHORITIES.len()
    );
    None
}

/// Returns whether the digest algorithm is SHA256 and
/// the signature algorithm is RSA with SHA256.
fn uses_sha256_with_rsa(signer: &SignerInfo) -> bool {
    match (signer.digest_alg.oid, signer.signature_algorithm.oid) {
        (ID_SHA_256, RSA_ENCRYPTION)
        | (ID_SHA_256, SHA_256_WITH_RSA_ENCRYPTION) => true,
        _ => false,
    }
}

/// Attempts to return the value of the specified signed attribute from the
/// specified signer info.
fn signed_attribute(
    signer: &SignerInfo,
    wanted: ObjectIdentifier,
) -> Option<&Any> {
    let attributes = signer.signed_attrs.as_ref()?;
    let attribute =
        attributes.iter().find(|attribute| attribute.oid == wanted)?;
    attribute.values.get(0)
}

/// Returns the digest the signer has approved (ID_MESSAGE_DIGEST).
fn approved_digest(signer: &SignerInfo) -> Option<OctetString> {
    let value = signed_attribute(signer, ID_MESSAGE_DIGEST)?;
    match value.to_der().as_deref().map(OctetString::from_der) {
        Ok(Ok(digest)) => Some(digest),
        _ => {
            debug!("the digest the signer approved is not readable");
            None
        }
    }
}

/// Returns the content type the signer has approved (ID_CONTENT_TYPE).
fn approved_content_type(signer: &SignerInfo) -> Option<ObjectIdentifier> {
    let value = signed_attribute(signer, ID_CONTENT_TYPE)?;
    match value.to_der().as_deref().map(ObjectIdentifier::from_der) {
        Ok(Ok(content_type)) => Some(content_type),
        _ => {
            debug!("the kind of content the signer approved is not readable");
            None
        }
    }
}

/// Records the whole decision: who authorised the image and the image itself.
/// Returns whether recording process behaved expectedly.
fn record(approval: &Approval, image: &[u8], device_path: &[u8]) -> bool {
    if !record_authority(approval) {
        security_violation!(
            "the authority cannot be recorded, refusing to rely on it"
        );
        return false;
    }
    if !record_image(image, device_path) {
        security_violation!("the image cannot be recorded, refusing to run it");
        return false;
    }
    true
}

/// Extends the ID of the specified authority into PCR 7, if this is the first time.
fn record_authority(approval: &Approval) -> bool {
    // Only a record that was written is remembered as written, so a failure
    // here leaves the next image to try again.
    if RECORDED.load(Ordering::Relaxed) & approval.bit != 0 {
        verification!("the authority is already recorded");
        return true;
    }

    let Some(mut tcg) = rollback::open_tcg() else {
        verification!("nothing keeps a record, the authority goes unrecorded");
        return true;
    };
    match records::authority(&mut tcg, &approval.authority.identity) {
        Ok(()) => {
            RECORDED.fetch_or(approval.bit, Ordering::Relaxed);
            true
        }
        Err(error) => {
            error!("could not record the authority decided with: {error:?}");
            false
        }
    }
}

/// Extends a digest of the specified image into PCR 4 (mirrors UEFI firmware).
fn record_image(image: &[u8], device_path: &[u8]) -> bool {
    let Some(mut tcg) = rollback::open_tcg() else {
        verification!("nothing keeps an account of images, recording nothing");
        return true;
    };
    match records::image(&mut tcg, image, link_time_address(image), device_path)
    {
        Ok(()) => true,
        Err(error) => {
            error!("could not record the image: {error:?}");
            false
        }
    }
}

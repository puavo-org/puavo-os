//! Reads the certificate entries of a Secure Boot signature database.

use crate::error::PuavoError;
use const_oid::db::rfc4519::COMMON_NAME;
use glob::Pattern;
use log::{debug, warn};
use std::{fs, path::Path, str};
use uuid::Uuid;
use x509_cert::{
    Certificate,
    der::{Decode, pem},
};

/// Size of the fixed part of EFI_SIGNATURE_LIST.
const SIGNATURE_LIST_HEADER_SIZE: usize = 28;

/// Size of the signature owner GUID at the start of each entry.
const SIGNATURE_OWNER_SIZE: usize = 16;

/// Signature type of a certificate list.
const EFI_CERT_X509_GUID: Uuid =
    Uuid::from_u128(0xa5c059a1_94e4_4aa7_87b5_ab155c2bf072);

/// PEM label of a certificate.
const PEM_LABEL: &str = "CERTIFICATE";

/// One entry of a database: a certificate and its signature owner GUID.
#[derive(Debug, Clone, PartialEq)]
pub struct Entry {
    owner: Uuid,
    certificate: Vec<u8>,
    common_name: Option<String>,
}

impl Entry {
    /// The DER certificate of the entry.
    pub fn certificate(&self) -> &[u8] {
        &self.certificate
    }

    /// The signature owner GUID of this entry.
    pub fn owner(&self) -> Uuid {
        self.owner
    }

    /// The common name of the certificate subject, or None when the
    /// certificate has none.
    pub fn common_name(&self) -> Option<&str> {
        self.common_name.as_deref()
    }

    /// The bytes the firmware measures when this entry verifies an image, an
    /// EFI_SIGNATURE_DATA of UEFI 2.10 section 32.4.1:
    ///
    /// typedef struct _EFI_SIGNATURE_DATA {
    ///     EFI_GUID SignatureOwner;
    ///     UINT8 SignatureData[];
    /// } EFI_SIGNATURE_DATA;
    pub fn measured(&self) -> Vec<u8> {
        let mut measured = self.owner.to_bytes_le().to_vec();
        measured.extend_from_slice(&self.certificate);
        measured
    }
}

/// A signature list with one certificate. A database is a sequence of
/// signature lists.
///
/// UEFI 2.10 section 32.4.1:
/// typedef struct _EFI_SIGNATURE_LIST {
///     EFI_GUID SignatureType;
///     UINT32 SignatureListSize;
///     UINT32 SignatureHeaderSize;
///     UINT32 SignatureSize;
///     UINT8 SignatureHeader[SignatureHeaderSize];
///     EFI_SIGNATURE_DATA Signatures[];
/// } EFI_SIGNATURE_LIST;
pub struct SignatureList {
    owner: Uuid,
    certificate: Vec<u8>,
}

impl SignatureList {
    /// Creates a list with one certificate.
    pub fn new(certificate: &[u8], owner: Uuid) -> Self {
        Self { owner, certificate: certificate.to_vec() }
    }

    /// Serializes the list.
    pub fn bytes(&self) -> Vec<u8> {
        let signature_size = SIGNATURE_OWNER_SIZE + self.certificate.len();
        let signature_list_size = SIGNATURE_LIST_HEADER_SIZE + signature_size;

        let mut list = Vec::with_capacity(signature_list_size);
        list.extend_from_slice(EFI_CERT_X509_GUID.to_bytes_le().as_slice());
        list.extend_from_slice(&(signature_list_size as u32).to_le_bytes());
        // A certificate list has no signature header.
        list.extend_from_slice(&0u32.to_le_bytes());
        list.extend_from_slice(&(signature_size as u32).to_le_bytes());
        list.extend_from_slice(self.owner.to_bytes_le().as_slice());
        list.extend_from_slice(&self.certificate);
        list
    }
}

/// The certificate entries of a signature database in order.
#[derive(Debug, Clone, PartialEq)]
pub struct SignatureDatabase {
    entries: Vec<Entry>,
}

impl SignatureDatabase {
    /// Parses a database from the contents of a UEFI variable, a sequence of
    /// signature lists. Lists of other types than certificates are skipped.
    pub fn read(contents: &[u8]) -> Result<Self, PuavoError> {
        let malformed = |what: &str| {
            PuavoError::MalformedSignatureDatabase(what.to_string())
        };
        let mut reader = ByteReader(contents);
        let mut entries = Vec::new();

        while !reader.is_empty() {
            let kind = reader
                .take(SIGNATURE_OWNER_SIZE)
                .and_then(|bytes| Uuid::from_slice_le(bytes).ok())
                .ok_or_else(|| malformed("truncated list type"))?;
            let signature_list_size = reader
                .read_u32()
                .ok_or_else(|| malformed("truncated list size"))?;
            let header_size = reader
                .read_u32()
                .ok_or_else(|| malformed("truncated header size"))?;
            let signature_size = reader
                .read_u32()
                .ok_or_else(|| malformed("truncated signature size"))?;

            let signatures_size = signature_list_size
                .checked_sub(SIGNATURE_LIST_HEADER_SIZE)
                .and_then(|size| size.checked_sub(header_size))
                .ok_or_else(|| malformed("list shorter than its header"))?;
            let certificate_size = signature_size
                .checked_sub(SIGNATURE_OWNER_SIZE)
                .ok_or_else(|| malformed("entry shorter than its owner"))?;

            reader
                .take(header_size)
                .ok_or_else(|| malformed("truncated list header"))?;
            let mut body = ByteReader(
                reader
                    .take(signatures_size)
                    .ok_or_else(|| malformed("truncated list"))?,
            );

            // Only certificate lists are parsed.
            if kind != EFI_CERT_X509_GUID {
                debug!("Skipping a signature list of type {}", kind);
                continue;
            }

            while !body.is_empty() {
                let owner = body
                    .take(SIGNATURE_OWNER_SIZE)
                    .and_then(|bytes| Uuid::from_slice_le(bytes).ok())
                    .ok_or_else(|| malformed("truncated entry owner"))?;
                let certificate = body
                    .take(certificate_size)
                    .ok_or_else(|| malformed("truncated entry"))?;

                // An entry that does not parse as a certificate is dropped.
                let Ok(parsed) = Certificate::from_der(certificate) else {
                    warn!("Skipping an entry that is not a certificate");
                    continue;
                };

                entries.push(Entry {
                    owner,
                    certificate: certificate.to_vec(),
                    common_name: common_name(&parsed),
                });
            }
        }

        debug!(
            "A database of {} bytes holds {} entries",
            contents.len(),
            entries.len()
        );

        Ok(Self { entries })
    }

    /// Returns the entry with this certificate.
    pub fn find_by_certificate(&self, certificate: &[u8]) -> Option<&Entry> {
        self.entries.iter().find(|entry| entry.certificate() == certificate)
    }

    /// Returns the entry whose certificate subject common name matches the
    /// glob pattern. More than one match is an error.
    pub fn find_by_subject_pattern(
        &self,
        pattern: &str,
    ) -> Result<Option<&Entry>, PuavoError> {
        let pattern = Pattern::new(pattern).map_err(|error| {
            PuavoError::MalformedChain(format!(
                "'{pattern}' is an invalid pattern: {error}"
            ))
        })?;

        let matched: Vec<(&Entry, &str)> = self
            .entries
            .iter()
            .filter_map(|entry| {
                let name = entry.common_name()?;
                pattern.matches(name).then_some((entry, name))
            })
            .collect();

        if matched.len() > 1 {
            let names: Vec<String> =
                matched.iter().map(|(_, name)| name.to_string()).collect();
            let pattern = pattern.as_str().to_string();
            return Err(PuavoError::AmbiguousSubject { pattern, names });
        }

        match matched.first() {
            Some((_, name)) => {
                debug!("'{}' matched the entry {}", pattern.as_str(), name)
            }
            None => debug!("'{}' matched no entry", pattern.as_str()),
        }

        Ok(matched.into_iter().next().map(|(entry, _)| entry))
    }

    /// All entries in order.
    pub fn entries(&self) -> &[Entry] {
        &self.entries
    }
}

struct ByteReader<'a>(&'a [u8]);

impl<'a> ByteReader<'a> {
    fn is_empty(&self) -> bool {
        self.0.is_empty()
    }

    /// Takes the specified number of bytes, or None when fewer remain.
    fn take(&mut self, length: usize) -> Option<&'a [u8]> {
        let (taken, remaining) = self.0.split_at_checked(length)?;
        self.0 = remaining;
        Some(taken)
    }

    /// Takes a little endian u32, or None when fewer than four bytes remain.
    fn read_u32(&mut self) -> Option<usize> {
        let (bytes, remaining) = self.0.split_first_chunk::<4>()?;
        self.0 = remaining;
        Some(u32::from_le_bytes(*bytes) as usize)
    }
}

/// Reads a DER or PEM certificate file and returns the DER bytes unchanged.
pub fn read_certificate_file(path: &Path) -> Result<Vec<u8>, PuavoError> {
    let contents = fs::read(path).map_err(PuavoError::IoError)?;
    let malformed = |why: &str| PuavoError::MalformedCertificate {
        path: path.display().to_string(),
        why: why.to_string(),
    };

    // The DER bytes are returned as read, because the firmware measures them
    // exactly.
    let certificate = match pem::decode_vec(&contents) {
        Ok((PEM_LABEL, decoded)) => decoded,
        Ok((label, _)) => return Err(malformed(&format!("holds a {label}"))),
        Err(_) => contents,
    };

    Certificate::from_der(&certificate)
        .map_err(|error| malformed(&error.to_string()))?;

    Ok(certificate)
}

/// The common name of the certificate subject, or None when it has none.
fn common_name(certificate: &Certificate) -> Option<String> {
    certificate
        .tbs_certificate
        .subject
        .0
        .iter()
        .flat_map(|part| part.0.iter())
        .find(|attribute| attribute.oid == COMMON_NAME)
        // Read as UTF-8, which covers the string types certificates use.
        .and_then(|attribute| str::from_utf8(attribute.value.value()).ok())
        .map(|name| name.to_string())
}

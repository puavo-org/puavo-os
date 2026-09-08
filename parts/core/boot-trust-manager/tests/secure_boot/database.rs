//! Checks the database reader against the database a captured boot measured.

use puavo_boot_trust_manager::error::PuavoError;
use puavo_boot_trust_manager::secure_boot::database::{
    SignatureDatabase, read_certificate_file,
};
use std::fs;
use tempfile::{NamedTempFile, TempDir};

use super::capture::slab;
use super::capture::{
    Capture, certificate_file_by_subject_pattern,
    write_variables_into_directory,
};

/// The subject common names of the certificates of that boot.
const SLAB: &str = "Capture Slab";
const NEXT_STAGE: &str = "Capture Next Stage";

/// The database the captured boot measured.
fn database() -> Vec<u8> {
    Capture::read(slab::PROFILE)
        .measured_variables()
        .into_iter()
        .find(|(name, _)| name == "db")
        .expect("capture did not contain database measurement")
        .1
}

/// The measured variables of the captured boot written to files.
fn variables_directory() -> TempDir {
    write_variables_into_directory(&Capture::read(slab::PROFILE)).0
}

#[test]
fn entry_found_by_its_certificate() {
    let read = SignatureDatabase::read(&database()).unwrap();
    let directory = variables_directory();

    for name in [SLAB, NEXT_STAGE] {
        let file = certificate_file_by_subject_pattern(directory.path(), name);
        let certificate = read_certificate_file(&file).unwrap();
        let entry = read
            .find_by_certificate(&certificate)
            .unwrap_or_else(|| panic!("{name} is not in the database"));

        assert_eq!(entry.certificate(), certificate.as_slice());
    }
}

#[test]
fn certificate_not_in_database_not_found() {
    let read = SignatureDatabase::read(&database()).unwrap();

    assert!(read.find_by_certificate(b"not a certificate").is_none());
}

#[test]
fn database_cut_short_is_never_fatal() {
    let whole = database();
    let entries = SignatureDatabase::read(&whole).unwrap().entries().len();

    for length in (1..whole.len()).step_by(97) {
        if let Ok(read) = SignatureDatabase::read(&whole[..length]) {
            // A truncated database yields at most the same entries.
            assert!(read.entries().len() <= entries);
        }
    }
}

#[test]
fn bytes_that_are_no_database_refused() {
    for filler in [0x00u8, 0x30, 0xff] {
        let error = SignatureDatabase::read(&[filler; 512]).err().unwrap();

        assert!(
            matches!(error, PuavoError::MalformedSignatureDatabase(_)),
            "{error}"
        );
    }
}

#[test]
fn empty_database_holds_nothing() {
    let read = SignatureDatabase::read(&[]).unwrap();

    assert!(read.entries().is_empty());
}

#[test]
fn certificate_reads_the_same_in_either_form() {
    let directory = variables_directory();
    let file = certificate_file_by_subject_pattern(directory.path(), SLAB);
    let binary = read_certificate_file(&file).unwrap();

    let text = NamedTempFile::new().unwrap();
    fs::write(text.path(), as_text(&binary)).unwrap();

    assert_eq!(read_certificate_file(text.path()).unwrap(), binary);
}

/// The same certificate in PEM form.
fn as_text(certificate: &[u8]) -> String {
    use base64::Engine;
    let body = base64::engine::general_purpose::STANDARD.encode(certificate);
    let wrapped: Vec<String> = body
        .as_bytes()
        .chunks(64)
        .map(|line| String::from_utf8(line.to_vec()).unwrap())
        .collect();

    format!(
        "-----BEGIN CERTIFICATE-----\n{}\n-----END CERTIFICATE-----\n",
        wrapped.join("\n")
    )
}

#[test]
fn entry_found_by_subject() {
    let read = SignatureDatabase::read(&database()).unwrap();

    let entry = read.find_by_subject_pattern(SLAB).unwrap().unwrap();

    assert_eq!(entry.common_name(), Some(SLAB));
}

#[test]
fn two_entries_with_one_subject_refused() {
    // The database concatenated with itself, so every subject appears twice.
    let mut doubled = database();
    doubled.extend_from_slice(&database());
    let read = SignatureDatabase::read(&doubled).unwrap();

    let error = read.find_by_subject_pattern(SLAB).err().unwrap();

    assert!(matches!(error, PuavoError::AmbiguousSubject { .. }), "{error}");
}

#[test]
fn unknown_subject_is_absent_rather_than_an_error() {
    let read = SignatureDatabase::read(&database()).unwrap();

    assert!(
        read.find_by_subject_pattern("Nobody In Particular").unwrap().is_none()
    );
}

#[test]
fn pattern_matches_longer_subject() {
    let read = SignatureDatabase::read(&database()).unwrap();

    let entry = read.find_by_subject_pattern("Capture Sl*").unwrap().unwrap();

    assert_eq!(entry.common_name(), Some(SLAB));
}

//! Chains this code rejects, and the two ways of naming an authority, using
//! the captured slab boot.

use std::{
    fs,
    path::{Path, PathBuf},
};
use tempfile::TempDir;

use puavo_boot_trust_manager::error::PuavoError;
use puavo_boot_trust_manager::secure_boot::chain::{
    Chain, Entry, Measurement, Source,
};

use super::capture::slab;
use super::capture::{
    Capture, CapturedDevice, certificate_file_by_subject_pattern,
    write_variables_into_directory,
};

/// The subject common names of the certificates of that boot.
const SLAB: &str = "Capture Slab";
const NEXT_STAGE: &str = "Capture Next Stage";

/// The captured boot with its measured variables written to files.
fn captured() -> (Capture, TempDir, CapturedDevice) {
    let capture = Capture::read(slab::PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    (capture, directory, device)
}

fn authority_by_certificate(path: PathBuf) -> Measurement {
    Measurement::Authority {
        database: "db".to_string(),
        entry: Entry::Certificate(path),
    }
}

fn authority_by_subject(name: &str) -> Measurement {
    Measurement::Authority {
        database: "db".to_string(),
        entry: Entry::Subject(name.to_string()),
    }
}

fn database_variable(directory: &Path) -> Measurement {
    Measurement::Variable {
        name: "db".to_string(),
        value: Source::Path(directory.join("db")),
    }
}

#[test]
fn subject_lookup_measures_as_certificate_lookup() {
    let (_capture, directory, device) = captured();

    let by_subject = slab::chain(directory.path());
    let by_certificate: Vec<Measurement> = by_subject
        .iter()
        .map(|measurement| match measurement {
            Measurement::Authority { entry: Entry::Subject(name), .. } => {
                authority_by_certificate(certificate_file_by_subject_pattern(
                    directory.path(),
                    name.as_str(),
                ))
            }
            other => other.clone(),
        })
        .collect();

    assert_eq!(
        Chain::new(&by_certificate).predict(&device).unwrap().value,
        Chain::new(&by_subject).predict(&device).unwrap().value
    );
}

#[test]
fn authority_missing_from_database_refused() {
    let (_capture, directory, device) = captured();

    // A valid certificate that is not in the database.
    let absent = directory.path().join("absent.der");
    let mut certificate =
        fs::read(certificate_file_by_subject_pattern(directory.path(), SLAB))
            .unwrap();
    *certificate.last_mut().unwrap() ^= 0xff;
    fs::write(&absent, certificate).unwrap();

    let chain = vec![
        database_variable(directory.path()),
        authority_by_certificate(absent),
    ];
    let error = Chain::new(&chain).predict(&device).err().unwrap();

    assert!(
        matches!(&error, PuavoError::NotFound(what) if what.contains("db")),
        "{error}"
    );
}

#[test]
fn authority_before_its_database_refused() {
    let (_capture, directory, device) = captured();

    let chain = vec![authority_by_certificate(
        certificate_file_by_subject_pattern(directory.path(), NEXT_STAGE),
    )];
    let error = Chain::new(&chain).predict(&device).err().unwrap();

    assert!(
        matches!(&error, PuavoError::MalformedChain(why) if why.contains("db")),
        "{error}"
    );
}

#[test]
fn empty_chain_leaves_register_as_is() {
    let (_capture, _directory, device) = captured();

    assert_eq!(
        Chain::new(&[]).predict(&device).unwrap().value,
        hex::encode([0u8; 32])
    );
}

#[test]
fn variable_outside_register_refused() {
    let (_capture, directory, device) = captured();

    let chain = vec![Measurement::Variable {
        name: "BootOrder".to_string(),
        value: Source::Path(directory.path().join("db")),
    }];
    let error = Chain::new(&chain).predict(&device).err().unwrap();

    assert!(
        matches!(&error, PuavoError::MalformedChain(why) if why.contains("BootOrder")),
        "{error}"
    );
}

#[test]
fn malformed_identity_refused() {
    let declared = r#"{ "slab-authority": { "identity": "not-a-guid" } }"#;

    assert!(serde_json::from_str::<Measurement>(declared).is_err());
}

#[test]
fn unknown_subject_refused() {
    let (_capture, directory, device) = captured();

    let chain = vec![
        database_variable(directory.path()),
        authority_by_subject("Nobody In Particular"),
    ];
    let error = Chain::new(&chain).predict(&device).err().unwrap();

    assert!(
        matches!(&error, PuavoError::NotFound(what) if what.contains("Nobody In Particular")),
        "{error}"
    );
}

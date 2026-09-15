//! Helpers shared by the tests of preparing and applying an update.

use std::{
    collections::BTreeMap,
    env, fs,
    path::{Path, PathBuf},
    sync::Once,
};

use tempfile::TempDir;
use uuid::Uuid;

use crate::{
    configurators::enrollment::EnrollmentItemConfiguration,
    devices::boot_vault::BootVaultResources,
    luks::tokens::LuksTpmEnrollmentPolicy,
    secure_boot::{
        chain::{Measurement, Source},
        database::SignatureList,
        update::{SecureBootDatabaseUpdate, Variable},
    },
};

static SCRIPTS_ON_PATH: Once = Once::new();

/// Puts the scripts under tests/scripts ahead of the installed commands, so
/// a test runs them instead. Call it first in a test that runs a command.
pub fn use_test_scripts() {
    SCRIPTS_ON_PATH.call_once(|| {
        let scripts =
            Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/scripts");
        let path = env::var("PATH").unwrap_or_default();

        unsafe {
            env::set_var("PATH", format!("{}:{}", scripts.display(), path));
        }
    });
}

/// Tells the stub update command where to record its arguments and returns
/// that file.
pub fn stub_update_command(directory: &Path) -> PathBuf {
    let record = directory.join("asked");

    unsafe {
        env::set_var("PUAVO_TEST_RECORD", &record);
    }

    record
}

/// A self signed certificate with the given common name.
fn certificate(name: &str) -> rcgen::CertifiedKey<rcgen::KeyPair> {
    rcgen::generate_simple_self_signed(vec![name.to_string()]).unwrap()
}

/// A boot vault with a device certificate.
pub fn vault() -> (TempDir, BootVaultResources) {
    let directory = TempDir::new().unwrap();
    let resources = BootVaultResources::new(directory.path());
    let device = certificate("Test Device Secure Boot Key");

    fs::write(resources.secure_boot_certificate_path(), device.cert.pem())
        .unwrap();

    (directory, resources)
}

/// Writes a database with one certificate and its build date, in the layout
/// of an image.
pub fn shipped_database(directory: &Path, built: u64) {
    let authority = certificate("Test Image Authority");
    let database =
        SignatureList::new(authority.cert.der(), Uuid::nil()).bytes();

    fs::write(directory.join("db.esl"), database).unwrap();
    fs::write(directory.join("built"), built.to_string()).unwrap();
}

/// Writes an empty revocation list beside the database, as the images have
/// none.
pub fn shipped_revocations(directory: &Path) {
    fs::write(directory.join("dbx.bin"), b"").unwrap();
}

/// An enrollment in the format of an installed one, measuring the named
/// variables.
pub fn shipped_enrollment(
    name: &str,
    variables: &[&str],
) -> EnrollmentItemConfiguration {
    let mut chain: Vec<Measurement> = variables
        .iter()
        .map(|variable| Measurement::Variable {
            name: variable.to_string(),
            value: Source::Device,
        })
        .collect();
    chain.push(Measurement::Separator);

    let mut pcrs = BTreeMap::new();
    pcrs.insert("7:sha256".to_string(), Some(chain));

    EnrollmentItemConfiguration {
        name: name.to_string(),
        version: 1,
        policy: LuksTpmEnrollmentPolicy {
            specific_pcrs: Some(pcrs),
            public_key_pcrs_expressions: Vec::new(),
            public_key_directory: None,
            public_keys: Vec::new(),
        },
    }
}

/// The update for one variable in an image directory.
pub fn shipped(image: &Path, variable: Variable) -> SecureBootDatabaseUpdate {
    SecureBootDatabaseUpdate::read(image, variable).unwrap().unwrap()
}

//! A boot of slab under Secure Boot, with keys generated for that boot.

use std::{fs, path::Path};

use boot_trust_manager::secure_boot::chain::{
    Chain, Entry, Measurement, Source,
};

use super::{
    Capture, CapturedDevice, REGISTER, write_variables_into_directory,
};

/// The capture directory.
pub const PROFILE: &str = "slab-boot";

/// The chain that describes the captured boot, reading the variables from
/// files in the directory.
pub fn chain(directory: &Path) -> Vec<Measurement> {
    let variable = |name: &str| Measurement::Variable {
        name: name.to_string(),
        value: Source::Path(directory.join(name)),
    };
    let authority = |subject: &str| Measurement::Authority {
        database: "db".to_string(),
        entry: Entry::Subject(subject.to_string()),
    };

    vec![
        variable("SecureBoot"),
        variable("PK"),
        variable("KEK"),
        variable("db"),
        variable("dbx"),
        Measurement::Separator,
        authority("Capture Slab"),
        Measurement::SlabBase,
        authority("Capture Next Stage"),
    ]
}

#[test]
fn variables_measured_in_order_chain_states() {
    let capture = Capture::read(PROFILE);
    let (_directory, measured) = write_variables_into_directory(&capture);

    assert_eq!(measured, ["SecureBoot", "PK", "KEK", "db", "dbx"]);
}

#[test]
fn every_step_matches_logged_digest() {
    let capture = Capture::read(PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    let predicted =
        Chain::new(&chain(directory.path())).predict(&device).unwrap();
    let logged = capture.events_of(REGISTER);

    assert_eq!(predicted.steps.len(), logged.len());

    for (step, event) in predicted.steps.iter().zip(logged) {
        assert_eq!(
            step.digest, event.digest,
            "{} does not measure as the firmware did",
            step.measurement
        );
    }
}

#[test]
fn chain_reproduces_captured_register() {
    let capture = Capture::read(PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    let predicted =
        Chain::new(&chain(directory.path())).predict(&device).unwrap();

    assert_eq!(predicted.value, capture.register(REGISTER));
}

#[test]
fn other_database_predicts_other_value() {
    let capture = Capture::read(PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    let database = directory.path().join("db");
    let mut contents = fs::read(&database).unwrap();
    *contents.last_mut().unwrap() ^= 0xff;
    fs::write(&database, contents).unwrap();

    let predicted =
        Chain::new(&chain(directory.path())).predict(&device).unwrap();

    assert_ne!(predicted.value, capture.register(REGISTER));
}

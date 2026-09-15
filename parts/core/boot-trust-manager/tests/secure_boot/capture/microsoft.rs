//! A boot of Microsoft signed shim under the variables the firmware ships
//! with. Shim also measures its SBAT level, which no chain describes, so that
//! event is taken from the capture.

use std::path::Path;

use boot_trust_manager::secure_boot::chain::{
    Chain, Entry, Measurement, Source,
};
use sha2::{Digest, Sha256};

use super::{
    AUTHORITY, Capture, CapturedDevice, REGISTER,
    write_variables_into_directory,
};

/// The capture directory.
pub(super) const PROFILE: &str = "microsoft-boot";

/// The certificate that verified shim.
const MICROSOFT: &str = "Microsoft Corporation UEFI CA 2011";

/// The certificate that verified the measurements binary.
const MEASUREMENTS_CERTIFICATE: &str = "Capture Measurements";

/// Shim measures its SBAT level as a variable with this name.
const SHIM_LEVEL: &str = "SbatLevel";

/// Extends a PCR value with one digest as the TPM does.
fn extend(value: &str, digest: &str) -> String {
    let mut hash = Sha256::new();
    hash.update(hex::decode(value).unwrap());
    hash.update(hex::decode(digest).unwrap());
    hex::encode(hash.finalize())
}

/// The measurements the firmware made before shim ran, reading the variables
/// from files in the directory.
fn firmware_chain(directory: &Path) -> Vec<Measurement> {
    let variable = |name: &str| Measurement::Variable {
        name: name.to_string(),
        value: Source::Path(directory.join(name)),
    };

    vec![
        variable("SecureBoot"),
        variable("PK"),
        variable("KEK"),
        variable("db"),
        variable("dbx"),
        Measurement::Separator,
        Measurement::Authority {
            database: "db".to_string(),
            entry: Entry::Subject(MICROSOFT.to_string()),
        },
    ]
}

#[test]
fn firmware_steps_match_logged_digests() {
    let capture = Capture::read(PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    let predicted =
        Chain::new(&firmware_chain(directory.path())).predict(&device).unwrap();
    let logged = capture.events_of(REGISTER);

    for (step, event) in predicted.steps.iter().zip(&logged) {
        assert_eq!(
            step.digest, event.digest,
            "{} does not measure as the firmware did",
            step.measurement
        );
    }
}

#[test]
fn chain_and_shim_events_reproduce_register() {
    let capture = Capture::read(PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    let predicted =
        Chain::new(&firmware_chain(directory.path())).predict(&device).unwrap();
    let logged = capture.events_of(REGISTER);

    // No chain describes what shim measured. Those events are taken from the
    // capture and extended onto the predicted value in order, so the final
    // value agrees only when the predicted part is right.
    let mut value = predicted.value;
    for event in logged.iter().skip(predicted.steps.len()) {
        value = extend(&value, &event.digest);
    }

    assert_eq!(value, capture.register(REGISTER));
}

#[test]
fn authority_for_capture_certificate_is_measured() {
    let capture = Capture::read(PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    // The last event of the boot is shim verifying the measurements binary
    // with the certificate added for the capture. Only the digest of that
    // step is compared, and the digest of a step does not depend on the
    // events before it. The database is read first so that the certificate
    // can be found in it.
    let chain = vec![
        Measurement::Variable {
            name: "db".to_string(),
            value: Source::Path(directory.path().join("db")),
        },
        Measurement::Authority {
            database: "db".to_string(),
            entry: Entry::Subject(MEASUREMENTS_CERTIFICATE.to_string()),
        },
    ];
    let predicted = Chain::new(&chain).predict(&device).unwrap();

    let logged = capture.events_of(REGISTER);
    let last = logged.last().unwrap();

    assert_eq!(last.kind, AUTHORITY);
    assert_eq!(predicted.steps.last().unwrap().digest, last.digest);
}

#[test]
fn shim_measures_level_no_chain_describes() {
    let capture = Capture::read(PROFILE);

    let names: Vec<String> = capture
        .events_of(REGISTER)
        .iter()
        .filter_map(|event| event.variable())
        .map(|(name, _)| name)
        .collect();

    assert!(
        names.iter().any(|name| name == SHIM_LEVEL),
        "the capture measured {names:?}"
    );
}

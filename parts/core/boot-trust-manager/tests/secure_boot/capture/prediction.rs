//! The prediction report of a captured boot, checked as the predict command
//! builds it.

use std::{
    collections::BTreeMap,
    fs,
    path::{Path, PathBuf},
};
use tempfile::TempDir;

use boot_trust_manager::configurators::enrollment::EnrollmentItemConfiguration;
use boot_trust_manager::error::PuavoError;
use boot_trust_manager::luks::tokens::LuksTpmEnrollmentPolicy;
use boot_trust_manager::secure_boot::chain::{Measurement, Source};
use boot_trust_manager::secure_boot::prediction::{Register, Report};

use super::slab;
use super::{
    Capture, CapturedDevice, REGISTER, write_variables_into_directory,
};

/// The PCR of the chain, as a policy names it.
const REGISTER_NAME: &str = "7:sha256";

/// Writes a policy with one chain and returns its path.
fn policy_file(
    directory: &Path,
    name: &str,
    chain: Vec<Measurement>,
) -> PathBuf {
    let mut pcrs = BTreeMap::new();
    pcrs.insert(REGISTER_NAME.to_string(), Some(chain));

    let policy = EnrollmentItemConfiguration {
        name: name.to_string(),
        version: 1,
        policy: LuksTpmEnrollmentPolicy {
            specific_pcrs: Some(pcrs),
            public_key_pcrs_expressions: Vec::new(),
            public_key_directory: None,
            public_keys: Vec::new(),
        },
    };

    let path = directory.join("policy.json");
    fs::write(&path, serde_json::to_string(&policy).unwrap()).unwrap();
    path
}

/// The report the predict command builds for a policy file.
fn report_of(policy: &Path, device: &CapturedDevice) -> Report {
    let configuration = EnrollmentItemConfiguration::read(policy).unwrap();
    let chains = configuration.policy.specific_pcrs.unwrap_or_default();

    Report::new(&configuration.name, &chains, device)
}

#[test]
fn policy_describing_boot_reports_agreement() {
    let capture = Capture::read(slab::PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    let policy =
        policy_file(directory.path(), "primary", slab::chain(directory.path()));
    let report = report_of(&policy, &device);

    assert!(report.all_chains_predicted());
    assert_eq!(report.policy, "primary");

    let Register::Predicted(comparison) = &report.registers[0] else {
        panic!("the register was not predicted");
    };
    assert_eq!(comparison.register, REGISTER_NAME);
    assert_eq!(comparison.predicted, capture.register(REGISTER));
    assert_eq!(comparison.matches, Some(true));
}

#[test]
fn policy_with_bad_measurement_reports_failure() {
    let capture = Capture::read(slab::PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    let chain = vec![Measurement::Variable {
        name: "BootOrder".to_string(),
        value: Source::Path(directory.path().join("db")),
    }];
    let policy = policy_file(directory.path(), "a policy", chain);
    let report = report_of(&policy, &device);

    assert!(!report.all_chains_predicted());
    assert!(matches!(report.registers[0], Register::Failed { .. }));
}

#[test]
fn non_policy_file_is_refused() {
    let directory = TempDir::new().unwrap();

    let path = directory.path().join("not-a-policy.json");
    fs::write(&path, b"{}").unwrap();

    let error = EnrollmentItemConfiguration::read(&path).err().unwrap();

    assert!(matches!(error, PuavoError::MalformedPolicy { .. }), "{error}");
}

#[test]
fn missing_policy_refused() {
    let error =
        EnrollmentItemConfiguration::read(Path::new("/nowhere/policy.json"))
            .err()
            .unwrap();

    assert!(matches!(error, PuavoError::IoError(_)), "{error}");
}

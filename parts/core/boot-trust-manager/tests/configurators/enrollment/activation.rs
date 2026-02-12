use puavo_boot_trust_manager::configurators::{
    Configurator, enrollment::EnrollmentConfigurator,
};
use serial_test::serial;

use crate::common::{fixture_directory, tpm};

use super::common::*;

#[test]
#[serial]
fn activation_skipped_when_pcr_cache_matches() {
    let images = setup();

    // Set PCR 16 to a known value before enrollment
    tpm::extend(
        16,
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    );

    let (mut boot_vault, mut primary_manager) =
        enroll_and_tpm_unlock_default(&images);

    // PCR has not changed since enrollment, so cache should match
    let configurator = enrollment_configurator();
    let activated = configurator
        .activate(&mut boot_vault, &mut primary_manager)
        .expect("Activation check failed");

    assert!(!activated, "Should not activate when PCR cache matches");
}

#[test]
#[serial]
fn activation_triggered_when_token_invalid_due_to_pcr_change() {
    let images = setup();

    // Set both PCRs to known values
    tpm::extend(
        16,
        "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    );
    tpm::extend(
        23,
        "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    );

    // Enroll with two TPM tokens (PCR 16 and 23)
    let (mut boot_vault, mut primary_manager) =
        enroll_and_tpm_unlock(&images, "two-pcr-enrollment", None);

    // Clear PCR cache to force token validation
    boot_vault
        .resources()
        .write_property("pcr.state", String::new())
        .expect("Failed to clear PCR cache");

    // Change only PCR 23, which invalidates one token.
    tpm::extend(
        23,
        "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
    );

    // Use the same enrollment configurator for activation check
    let configurator = EnrollmentConfigurator::from_directory(
        fixture_directory("two-pcr-enrollment").as_str(),
    )
    .expect("Failed to load two-PCR enrollment configuration")
    .remove(0);

    let activated = configurator
        .activate(&mut boot_vault, &mut primary_manager)
        .expect("Activation check failed");

    // Token should be invalid now because PCR 23 changed after unlock
    assert!(
        activated,
        "Should activate when token is invalid due to PCR change after unlock"
    );
}

#[test]
#[serial]
fn activation_triggered_when_configuration_changes() {
    let images = setup();

    // Extend PCR 16 to a known value
    tpm::extend(
        16,
        "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    );

    // Enroll with the default test configuration
    let (mut boot_vault, mut primary_manager) =
        enroll_and_tpm_unlock_default(&images);

    // Load a different enrollment configuration, which should trigger enrollment.
    // This simulates a configuration update between boots.
    let new_configurator = EnrollmentConfigurator::from_directory(
        fixture_directory("multiple-enrollments").as_str(),
    )
    .expect("Failed to load new enrollment configuration")
    .remove(0);

    let activated = new_configurator
        .activate(&mut boot_vault, &mut primary_manager)
        .expect("Activation check failed");

    assert!(
        activated,
        "Should activate when enrollment configuration has changed"
    );
}

#[test]
#[serial]
fn activation_validates_tokens_when_pcr_cache_missing() {
    let images = setup();

    // Set PCR 16 to a known value
    tpm::extend(
        16,
        "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    );

    // Enroll and unlock with TPM
    let (mut boot_vault, mut primary_manager) =
        enroll_and_tpm_unlock_default(&images);

    // Clear the PCR cache to force token validation path
    boot_vault
        .resources()
        .write_property("pcr.state", String::new())
        .expect("Failed to clear PCR cache");

    let configurator = enrollment_configurator();
    let activated = configurator
        .activate(&mut boot_vault, &mut primary_manager)
        .expect("Activation check failed");

    // Tokens are still valid, because PCRs did not change.
    // This tests the token validation path since PCR cache is missing.
    assert!(
        !activated,
        "Should not activate when tokens are valid, even without PCR cache"
    );
}

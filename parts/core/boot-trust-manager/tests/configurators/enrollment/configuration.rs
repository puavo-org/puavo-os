use std::path::PathBuf;

use puavo_boot_trust_manager::{
    boot_trust_manager::BootTrustManager,
    configurators::{Configurator, enrollment::EnrollmentConfigurator},
    devices::boot_vault::BootVault,
    utils::luks_tpm_token_manager::LuksTpmTokenManager,
};
use serial_test::serial;

use crate::common::fixture_directory;

use super::common::*;

#[test]
#[serial]
fn enrollment_does_not_activate_when_unlocked_with_recovery_key() {
    let images = setup();

    let configurator = enrollment_configurator();

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Boot vault was unlocked with recovery key, because the base LUKS images have no TPM tokens.
    // By default, enrollment is skipped if boot vault is opened with recovery key.

    let activated = configurator
        .activate(&mut boot_vault, &mut primary_manager)
        .expect("Activation check failed");

    assert!(
        !activated,
        "Enrollment should not activate when unlocked with recovery key"
    );
}

#[test]
#[serial]
fn enrollment_activates_when_no_tpm_tokens_exist() {
    let images = setup();

    let configurator = enrollment_configurator();

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Force enrollment to be required.
    // By default, enrollment is skipped if boot vault is opened with recovery key.
    boot_vault.set_enrollment_required(true);

    let activated = configurator
        .activate(&mut boot_vault, &mut primary_manager)
        .expect("Activation check failed");

    assert!(activated, "Enrollment should activate when explicitly required");
}

#[test]
#[serial]
fn enroll_all_creates_tpm_tokens() {
    let images = setup();

    let mut configurator = enrollment_configurator();

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Verify there are no TPM tokens on the boot vault and primary manager
    verify_no_tokens(&mut [boot_vault.device_mut(), &mut primary_manager]);

    // Set up for TPM unlock simulation
    boot_vault.set_pin(None); // No PIN, just TPM

    // Perform enrollment
    configurator
        .enroll_all(&mut boot_vault, &mut primary_manager)
        .expect("Enrollment failed");

    // Reload LUKS metadata to see changes made by systemd-cryptenroll
    boot_vault.device_mut().reload().expect("Failed to reload vault device");
    primary_manager.reload().expect("Failed to reload primary device");

    // Verify only the boot vault has TPM tokens
    let vault_tokens = boot_vault
        .device_mut()
        .list_tokens()
        .expect("Failed to list vault tokens");
    let primary_tokens =
        primary_manager.list_tokens().expect("Failed to list primary tokens");

    assert!(
        !vault_tokens.is_empty(),
        "Boot vault should have TPM tokens after enrollment"
    );
    assert!(
        primary_tokens.is_empty(),
        "Primary partition should not have TPM tokens after enrollment"
    );
}

#[test]
#[serial]
fn enrollment_with_pin_creates_pin_protected_tokens() {
    let images = setup();

    let mut configurator = enrollment_configurator();

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Verify there are no TPM tokens on the boot vault and primary manager
    verify_no_tokens(&mut [boot_vault.device_mut(), &mut primary_manager]);

    // Set up with a PIN
    let test_pin = "1234".to_string();
    boot_vault.set_pin(Some(test_pin.clone()));

    // Perform enrollment
    configurator
        .enroll_all(&mut boot_vault, &mut primary_manager)
        .expect("Enrollment with PIN failed");

    // Reload LUKS metadata to see changes made by systemd-cryptenroll
    boot_vault.device_mut().reload().expect("Failed to reload vault device");

    // Verify all tokens require PIN on both devices
    let vault_tokens = boot_vault
        .device_mut()
        .list_tokens()
        .expect("Failed to list vault tokens");

    let primary_tokens = primary_manager
        .list_tokens()
        .expect("Failed to list primary manager tokens");

    let all_require_pin = vault_tokens
        .iter()
        .chain(primary_tokens.iter())
        .all(|(_, token)| token.use_pin);
    assert!(all_require_pin, "All tokens should be PIN-protected");
}

#[test]
#[serial]
fn run_configurators_enrolls_only_boot_vault() {
    let images = setup();

    let configurators: Vec<Box<dyn Configurator>> =
        EnrollmentConfigurator::from_directory(
            fixture_directory("simple-enrollment").as_str(),
        )
        .expect("Failed to load enrollment configurator")
        .into_iter()
        .map(|configurator| Box::new(configurator) as Box<dyn Configurator>)
        .collect();

    assert!(!configurators.is_empty(), "Expected at least one configurator");

    // Set up loop device for primary partition
    let primary_loop = std::process::Command::new("losetup")
        .args(["--find", "--show", &images.primary])
        .output()
        .expect("Failed to set up loop device for primary");
    let primary_device_path =
        String::from_utf8_lossy(&primary_loop.stdout).trim().to_string();

    // Mount boot vault
    let mut boot_vault = BootVault::default();
    boot_vault
        .mount(&PathBuf::from(&images.vault), &display())
        .expect("Failed to mount boot vault");

    // Force enrollment
    boot_vault.set_enrollment_required(true);
    boot_vault.set_pin(None);

    let primary_manager =
        LuksTpmTokenManager::from_device_path(primary_device_path.clone())
            .expect("Failed to create primary partition manager");

    // Run configurators directly
    BootTrustManager::run_configurators(
        &display(),
        boot_vault,
        primary_manager,
        configurators,
    )
    .expect("Configuration failed");

    // Check tokens on primary device as well
    let mut verify_manager =
        LuksTpmTokenManager::from_device_path(primary_device_path)
            .expect("Failed to create verification manager");
    let tokens = verify_manager.list_tokens().expect("Failed to list tokens");

    assert!(
        tokens.is_empty(),
        "Primary partition should not have TPM tokens after configuration"
    );
}

#[test]
#[serial]
fn empty_enrollment_directory_returns_no_configurators() {
    let images = setup();
    let empty_dir = format!("{}/empty-enrollment", images.directory);
    std::fs::create_dir_all(&empty_dir)
        .expect("Failed to create empty directory");

    let configurators = EnrollmentConfigurator::from_directory(&empty_dir)
        .expect("Failed to load from empty directory");

    assert!(
        configurators.is_empty(),
        "Empty directory should return no configurators"
    );
}

#[test]
#[serial]
fn nonexistent_directory_returns_no_configurators() {
    let configurators = EnrollmentConfigurator::from_directory(
        "/non-existent/path/to/enrollment",
    )
    .expect("Should handle non-existent directory gracefully");

    assert!(
        configurators.is_empty(),
        "Non-existent directory should return no configurators"
    );
}

#[test]
#[serial]
fn loads_multiple_enrollment_configurations() {
    let configurators = EnrollmentConfigurator::from_directory(
        fixture_directory("multiple-enrollments").as_str(),
    )
    .expect("Failed to load multiple enrollment configurations");

    assert_eq!(
        configurators.len(),
        1,
        "Multiple configurations should be combined into one configurator"
    );

    let configurator = &configurators[0];
    let enrollments = configurator.enrollments();

    // Verify all enrollment configurations were loaded internally
    assert_eq!(
        enrollments.len(),
        3,
        "All three enrollment configurations should be loaded"
    );

    let first = &enrollments[0];
    assert_eq!(first.name, "first-enrollment");
    assert_eq!(first.version, 1);
    assert_eq!(
        first.policy.specific_pcrs_expressions,
        Some(vec!["7:sha256".to_string()])
    );
    assert!(first.policy.public_key_pcrs_expressions.is_empty());

    let second = &enrollments[1];
    assert_eq!(second.name, "second-enrollment");
    assert_eq!(second.version, 2);
    assert_eq!(
        second.policy.specific_pcrs_expressions,
        Some(vec!["8:sha256".to_string()])
    );
    assert!(second.policy.public_key_pcrs_expressions.is_empty());

    let third = &enrollments[2];
    assert_eq!(third.name, "third-enrollment");
    assert_eq!(third.version, 3);
    assert_eq!(
        third.policy.specific_pcrs_expressions,
        Some(vec!["11:sha256".to_string()])
    );
    assert_eq!(
        third.policy.public_key_pcrs_expressions,
        vec!["4:sha256", "9:sha256"]
    );
}

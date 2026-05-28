use std::path::PathBuf;

use serial_test::serial;
use zeroize::Zeroizing;

use crate::common::{display::TestDisplay, efi, luks, tpm};
use puavo_boot_trust_manager::{
    configurators::{Configurator, pin::PinConfigurator},
    devices::boot_vault::BootVault,
    display::UserDisplay,
    utils::luks_tpm_token_manager::LuksTpmTokenManager,
};

fn setup() -> luks::TestImages {
    tpm::reset();
    efi::reset();
    luks::setup("pin")
}

fn display() -> Box<dyn UserDisplay> {
    Box::new(TestDisplay::with_password(luks::RECOVERY_KEY))
}

/// Helper to set up loop device for primary partition
fn setup_primary_loop(images: &luks::TestImages) -> String {
    let primary_loop = std::process::Command::new("losetup")
        .args(["--find", "--show", &images.primary])
        .output()
        .expect("Failed to set up loop device for primary");
    assert!(
        primary_loop.status.success(),
        "Failed to create primary loop device"
    );
    String::from_utf8_lossy(&primary_loop.stdout).trim().to_string()
}

/// Helper to mount the boot vault and return it along with the primary partition manager.
fn mount_vault_and_primary(
    images: &luks::TestImages,
    display: &Box<dyn UserDisplay>,
) -> (BootVault, LuksTpmTokenManager) {
    let primary_device_path = setup_primary_loop(images);

    let mut boot_vault = BootVault::default();
    boot_vault
        .mount(&PathBuf::from(&images.vault), display)
        .expect("Failed to mount boot vault");

    let primary_partition_manager =
        LuksTpmTokenManager::from_device_path(primary_device_path)
            .expect("Failed to create primary partition manager");

    (boot_vault, primary_partition_manager)
}

#[test]
#[serial]
fn activates_when_unlocked_with_recovery_key() {
    let images = setup();

    let configurator = PinConfigurator::new()
        .expect("Failed to create PIN configurator")
        .remove(0);

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Boot vault was unlocked with recovery key (default for base images without TPM tokens)
    let activated = configurator
        .activate(&mut boot_vault, &mut primary_manager)
        .expect("Activation check failed");

    assert!(
        activated,
        "PIN configurator should activate when unlocked with recovery key"
    );
}

#[test]
#[serial]
fn activates_when_pin_change_requested_via_efi() {
    let images = setup();
    efi::with_pin_change_requested();

    let configurator = PinConfigurator::new()
        .expect("Failed to create PIN configurator")
        .remove(0);

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Simulate TPM unlock
    boot_vault.set_pin(None);

    let activated = configurator
        .activate(&mut boot_vault, &mut primary_manager)
        .expect("Activation check failed");

    assert!(
        activated,
        "PIN configurator should activate when PIN change requested via EFI"
    );
}

#[test]
#[serial]
fn does_not_activate_when_unlocked_with_tpm() {
    let images = setup();

    let configurator = PinConfigurator::new()
        .expect("Failed to create PIN configurator")
        .remove(0);

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Simulate TPM unlock by setting the unlock method
    boot_vault.set_pin(None);

    let activated = configurator
        .activate(&mut boot_vault, &mut primary_manager)
        .expect("Activation check failed");

    assert!(
        !activated,
        "PIN configurator should not activate when unlocked with TPM"
    );
}

#[test]
#[serial]
fn configure_sets_new_pin() {
    let images = setup();

    let mut configurator = PinConfigurator::new()
        .expect("Failed to create PIN configurator")
        .remove(0);

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Create display that provides PIN and confirmation
    let pin_display: Box<dyn UserDisplay> = Box::new(
        TestDisplay::with_passwords(vec!["1234", "1234"])
            .with_yes_no_responses(vec![true]), // "Change PIN?" -> yes
    );

    configurator
        .configure(&mut boot_vault, &mut primary_manager, &pin_display)
        .expect("Configure failed");

    // Verify PIN was set
    assert_eq!(boot_vault.pin(), Some(&Zeroizing::new("1234".to_string())));

    // Verify enrollment is required after PIN change
    assert!(
        boot_vault.is_enrollment_required(),
        "Enrollment should be required after PIN change"
    );
}

#[test]
#[serial]
fn configure_removes_pin_when_empty() {
    let images = setup();

    let mut configurator = PinConfigurator::new()
        .expect("Failed to create PIN configurator")
        .remove(0);

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Create display that provides empty PIN and confirms removal
    let pin_display: Box<dyn UserDisplay> = Box::new(
        TestDisplay::with_passwords(vec![""]).with_yes_no_responses(vec![
            true, // "Change PIN?" -> yes
            true, // "Remove PIN protection?" -> yes
        ]),
    );

    configurator
        .configure(&mut boot_vault, &mut primary_manager, &pin_display)
        .expect("Configure failed");

    // Verify PIN was removed (set to None)
    assert_eq!(boot_vault.pin(), None);

    // Verify enrollment is required after PIN removal
    assert!(
        boot_vault.is_enrollment_required(),
        "Enrollment should be required after PIN removal"
    );
}

#[test]
#[serial]
fn configure_cancelled_by_user() {
    let images = setup();

    let mut configurator = PinConfigurator::new()
        .expect("Failed to create PIN configurator")
        .remove(0);

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Create display that cancels the PIN change
    let pin_display: Box<dyn UserDisplay> = Box::new(
        TestDisplay::with_passwords(vec!["1234"])
            .with_yes_no_responses(vec![false]), // "Change PIN?" -> no
    );

    configurator
        .configure(&mut boot_vault, &mut primary_manager, &pin_display)
        .expect("Configure failed");

    // Verify PIN was not changed and enrollment is not required
    assert!(
        !boot_vault.is_enrollment_required(),
        "Enrollment should not be required when user cancels"
    );
}

#[test]
#[serial]
fn configure_retries_on_pin_mismatch() {
    let images = setup();

    let mut configurator = PinConfigurator::new()
        .expect("Failed to create PIN configurator")
        .remove(0);

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Create display that first provides mismatched PINs, then matching PINs
    let pin_display: Box<dyn UserDisplay> = Box::new(
        TestDisplay::with_passwords(vec![
            "1234", "5678", // First attempt: mismatch
            "abcd", "abcd", // Second attempt: match
        ])
        .with_yes_no_responses(vec![
            true, // "Change PIN?" -> yes (first attempt)
            true, // "Change PIN?" -> yes (retry after mismatch)
        ]),
    );

    configurator
        .configure(&mut boot_vault, &mut primary_manager, &pin_display)
        .expect("Configure failed");

    // Verify the correct PIN was set after retry
    assert_eq!(boot_vault.pin(), Some(&Zeroizing::new("abcd".to_string())));
}

#[test]
#[serial]
fn configure_cancels_pin_removal() {
    let images = setup();

    let mut configurator = PinConfigurator::new()
        .expect("Failed to create PIN configurator")
        .remove(0);

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Create display that provides empty PIN but cancels the removal
    let pin_display: Box<dyn UserDisplay> = Box::new(
        TestDisplay::with_passwords(vec![
            "", // First attempt: empty PIN
            "1234", "1234", // Second attempt: valid PIN with confirmation
        ])
        .with_yes_no_responses(vec![
            true,  // "Change PIN?" -> yes (first attempt)
            false, // "Remove PIN protection?" -> no (cancel removal)
            true,  // "Change PIN?" -> yes (retry after cancellation)
        ]),
    );

    configurator
        .configure(&mut boot_vault, &mut primary_manager, &pin_display)
        .expect("Configure failed");

    // Verify the PIN was set (not removed) after user cancelled removal
    assert_eq!(boot_vault.pin(), Some(&Zeroizing::new("1234".to_string())));

    // Verify enrollment is required after PIN change
    assert!(
        boot_vault.is_enrollment_required(),
        "Enrollment should be required after PIN change"
    );
}

#[test]
#[serial]
fn configure_handles_display_error() {
    let images = setup();

    let mut configurator = PinConfigurator::new()
        .expect("Failed to create PIN configurator")
        .remove(0);

    let (mut boot_vault, mut primary_manager) =
        mount_vault_and_primary(&images, &display());

    // Create display that will fail when asking for password
    let pin_display: Box<dyn UserDisplay> = Box::new(
        TestDisplay::with_passwords(vec![]).with_yes_no_responses(vec![true]), // "Change PIN?" -> yes
    );

    // The configure should propagate the display error instead of looping infinitely.
    // In boot environment, if the display fails, the system should not get stuck.
    let result = configurator.configure(
        &mut boot_vault,
        &mut primary_manager,
        &pin_display,
    );

    assert!(
        result.is_err(),
        "Configure should propagate display error instead of looping infinitely"
    );

    // Verify enrollment was not triggered due to error
    assert!(
        !boot_vault.is_enrollment_required(),
        "Enrollment should not be required when display fails"
    );
}

#[test]
#[serial]
fn new_returns_single_configurator() {
    let configurators =
        PinConfigurator::new().expect("Failed to create PIN configurators");

    assert_eq!(
        configurators.len(),
        1,
        "Should return exactly one configurator"
    );
}

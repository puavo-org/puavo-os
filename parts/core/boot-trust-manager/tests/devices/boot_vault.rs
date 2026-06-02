use std::path::PathBuf;

use serial_test::serial;

use crate::common::{display::TestDisplay, fixture_directory, luks, tpm};
use puavo_boot_trust_manager::{
    configurators::enrollment::EnrollmentConfigurator,
    devices::boot_vault::{BootVault, BootVaultUnlockMethod},
    display::UserDisplay,
    utils::luks_tpm_token_manager::LuksTpmTokenManager,
};

fn setup() -> luks::TestImages {
    tpm::reset();
    luks::setup("boot_vault")
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

/// Enroll TPM tokens to the boot vault and primary partition.
fn enroll_tpm_tokens(
    boot_vault: &mut BootVault,
    primary_manager: &mut LuksTpmTokenManager,
) {
    // Use the simple enrollment configuration, which binds to PCR 16
    let mut configurator = EnrollmentConfigurator::from_directory(
        fixture_directory("simple-enrollment").as_str(),
    )
    .expect("Failed to create enrollment configurator")
    .remove(0);

    boot_vault.set_pin(None);

    configurator
        .enroll_all(boot_vault, primary_manager)
        .expect("TPM enrollment failed");
}

#[test]
#[serial]
fn mount_with_recovery_key() {
    let images = setup();

    let mut vault = BootVault::default();
    let result = vault.mount(&PathBuf::from(&images.vault), &*display());
    assert!(result.is_ok(), "Failed to mount boot vault: {:?}", result.err());

    let key = vault.resources().read_recovery_key();
    assert!(key.is_ok(), "Failed to read recovery key: {:?}", key.err());
    assert_eq!(key.unwrap().as_str(), luks::RECOVERY_KEY);

    assert!(
        matches!(
            vault.unlock_method(),
            Some(BootVaultUnlockMethod::RecoveryKey)
        ),
        "Expected unlock method to be recovery key"
    );
}

#[test]
#[serial]
fn mount_with_wrong_key_fails() {
    let images = setup();
    let wrong_display: Box<dyn UserDisplay> =
        Box::new(TestDisplay::with_password("wrong-key").with_max_attempts(3));

    let mut vault = BootVault::default();
    let result = vault.mount(&PathBuf::from(&images.vault), &*wrong_display);
    assert!(result.is_err(), "Mount should fail with wrong key");
}

#[test]
#[serial]
fn resources_read_write_property() {
    let images = setup();

    let mut vault = BootVault::default();
    vault.mount(&PathBuf::from(&images.vault), &*display()).unwrap();

    let resources = vault.resources();
    resources
        .write_property("test-property", "test-value".to_string())
        .unwrap();

    let value = resources.read_property("test-property").unwrap();
    assert_eq!(value, Some("test-value".to_string()));
}

#[test]
#[serial]
fn mount_with_tpm_succeeds_when_pcr_matches() {
    let images = setup();
    let primary_device_path = setup_primary_loop(&images);

    // Initialize PCR 16 with non-zero value
    tpm::extend(
        16,
        "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789",
    );

    // First, mount with recovery key and enroll TPM tokens
    {
        let mut vault = BootVault::default();
        vault
            .mount(&PathBuf::from(&images.vault), &*display())
            .expect("Initial mount failed");

        let mut primary_manager =
            LuksTpmTokenManager::from_device_path(primary_device_path.clone())
                .expect("Failed to create primary manager");

        enroll_tpm_tokens(&mut vault, &mut primary_manager);
    }
    // Vault is dropped and unmounted here

    // TPM based unlock should succeed since PCR 16 has not changed
    let no_password_display: Box<dyn UserDisplay> =
        Box::new(TestDisplay::with_password("").with_max_attempts(0));

    let mut vault = BootVault::default();
    let result =
        vault.mount(&PathBuf::from(&images.vault), &*no_password_display);

    assert!(result.is_ok(), "TPM unlock should succeed: {:?}", result.err());
    assert!(
        matches!(
            vault.unlock_method(),
            Some(BootVaultUnlockMethod::TpmToken(None))
        ),
        "Expected unlock method to be TPM without PIN"
    );
}

#[test]
#[serial]
fn mount_with_tpm_fails_when_pcr_changes() {
    let images = setup();
    let primary_device_path = setup_primary_loop(&images);

    // Initialize PCR 16 with non-zero value
    tpm::extend(
        16,
        "9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba",
    );

    // First, mount with recovery key and enroll TPM tokens
    {
        let mut vault = BootVault::default();
        vault
            .mount(&PathBuf::from(&images.vault), &*display())
            .expect("Initial mount failed");

        let mut primary_manager =
            LuksTpmTokenManager::from_device_path(primary_device_path.clone())
                .expect("Failed to create primary manager");

        enroll_tpm_tokens(&mut vault, &mut primary_manager);
    }
    // Vault is dropped and unmounted here

    // Extend PCR 16 to change its value
    tpm::extend(
        16,
        "0000000000000000000000000000000000000000000000000000000000000001",
    );

    // TPM based unlock should fail, because we changed PCR 16
    let mut vault = BootVault::default();
    let result = vault.mount(&PathBuf::from(&images.vault), &*display());

    assert!(
        result.is_ok(),
        "Mount should succeed with recovery key fallback: {:?}",
        result.err()
    );
    assert!(
        matches!(
            vault.unlock_method(),
            Some(BootVaultUnlockMethod::RecoveryKey)
        ),
        "Expected fallback to recovery key after PCR change"
    );
}

#[test]
#[serial]
fn mount_with_tpm_fails_completely_when_pcr_changes_and_no_recovery_key() {
    let images = setup();
    let primary_device_path = setup_primary_loop(&images);

    // Initialize PCR 16 with non-zero value
    tpm::extend(
        16,
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    );

    // First, mount with recovery key and enroll TPM tokens
    {
        let mut vault = BootVault::default();
        vault
            .mount(&PathBuf::from(&images.vault), &*display())
            .expect("Initial mount failed");

        let mut primary_manager =
            LuksTpmTokenManager::from_device_path(primary_device_path.clone())
                .expect("Failed to create primary manager");

        enroll_tpm_tokens(&mut vault, &mut primary_manager);
    }
    // Vault is dropped and unmounted here

    // Extend PCR 16 to change its value
    tpm::extend(
        16,
        "0000000000000000000000000000000000000000000000000000000000000001",
    );

    // Try to mount without providing recovery key, the unlock should fail completely
    let no_password_display: Box<dyn UserDisplay> =
        Box::new(TestDisplay::with_password("wrong-key").with_max_attempts(3));

    let mut vault = BootVault::default();
    let result =
        vault.mount(&PathBuf::from(&images.vault), &*no_password_display);

    assert!(
        result.is_err(),
        "Mount should fail when TPM token is invalid and no valid recovery key"
    );
}

use std::path::PathBuf;

use puavo_boot_trust_manager::{
    configurators::enrollment::EnrollmentConfigurator,
    devices::boot_vault::{BootVault, BootVaultUnlockMethod},
    display::UserDisplay,
    utils::luks_tpm_token_manager::LuksTpmTokenManager,
};
use zeroize::Zeroizing;

use crate::common::{display::TestDisplay, fixture_directory, luks, tpm};

pub fn setup() -> luks::TestImages {
    tpm::reset();
    luks::setup("enrollment")
}

pub fn display() -> Box<dyn UserDisplay> {
    Box::new(TestDisplay::with_password(luks::RECOVERY_KEY))
}

pub fn enrollment_configurator() -> EnrollmentConfigurator {
    EnrollmentConfigurator::from_directory(
        fixture_directory("simple-enrollment").as_str(),
    )
    .expect("Failed to create enrollment configurator")
    .remove(0)
}

pub fn verify_no_tokens(token_managers: &mut [&mut LuksTpmTokenManager]) {
    for manager in token_managers {
        let tokens = manager.list_tokens().expect("Failed to list TPM tokens");
        assert!(tokens.is_empty(), "Token manager has tokens");
    }
}

/// Helper to mount the boot vault and return it along with the primary partition manager.
pub fn mount_vault_and_primary(
    images: &luks::TestImages,
    display: &dyn UserDisplay,
) -> (BootVault, LuksTpmTokenManager) {
    // Set up loop device for primary partition
    let primary_loop = std::process::Command::new("losetup")
        .args(["--find", "--show", &images.primary])
        .output()
        .expect("Failed to set up loop device for primary");
    assert!(
        primary_loop.status.success(),
        "Failed to create primary loop device"
    );

    let primary_device_path =
        String::from_utf8_lossy(&primary_loop.stdout).trim().to_string();

    // Mount the boot vault
    let mut boot_vault = BootVault::default();
    boot_vault
        .mount(&PathBuf::from(&images.vault), display)
        .expect("Failed to mount boot vault");

    // Create primary partition manager
    let primary_partition_manager =
        LuksTpmTokenManager::from_device_path(primary_device_path)
            .expect("Failed to create primary partition manager");

    (boot_vault, primary_partition_manager)
}

/// Helper to set up loop device for primary partition
pub fn setup_primary_loop(images: &luks::TestImages) -> String {
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

/// Enroll with the specified configuration and then TPM unlock.
///
/// Parameters:
/// - `images`: Test LUKS images
/// - `enrollment_configuration`: Name of the enrollment fixture directory
/// - `pin`: Optional PIN to protect the TPM tokens. None for automatic unlock.
pub fn enroll_and_tpm_unlock(
    images: &luks::TestImages,
    enrollment_configuration: &str,
    pin: Option<&str>,
) -> (BootVault, LuksTpmTokenManager) {
    let primary_device_path = setup_primary_loop(images);

    // Setup the boot vault with automatic TPM unlock
    {
        let mut boot_vault = BootVault::default();
        boot_vault
            .mount(&PathBuf::from(&images.vault), &*display())
            .expect("Initial mount failed");

        let mut primary_manager =
            LuksTpmTokenManager::from_device_path(primary_device_path.clone())
                .expect("Failed to create primary manager");

        boot_vault.set_pin(pin.map(|pin| Zeroizing::new(pin.to_string())));

        let mut configurator = EnrollmentConfigurator::from_directory(
            fixture_directory(enrollment_configuration).as_str(),
        )
        .expect("Failed to create enrollment configurator")
        .remove(0);

        configurator
            .enroll_all(&mut boot_vault, &mut primary_manager)
            .expect("Enrollment failed");
    }
    // Vault unmounts on drop

    // Unlock the vault with TPM
    let unlock_display: Box<dyn UserDisplay> = match pin {
        Some(pin) => Box::new(TestDisplay::with_password(pin)),
        None => Box::new(TestDisplay::with_password("").with_max_attempts(0)),
    };

    let mut boot_vault = BootVault::default();
    boot_vault
        .mount(&PathBuf::from(&images.vault), &*unlock_display)
        .expect("TPM unlock should succeed");

    let expected_unlock_method = match pin {
        Some(_) => BootVaultUnlockMethod::TpmToken(Some(Zeroizing::new(
            pin.unwrap().to_string(),
        ))),
        None => BootVaultUnlockMethod::TpmToken(None),
    };
    assert!(
        boot_vault.unlock_method() == Some(&expected_unlock_method),
        "Unexpected unlock method (pin={:?})",
        pin
    );

    let primary_manager =
        LuksTpmTokenManager::from_device_path(primary_device_path)
            .expect("Failed to create primary manager");

    (boot_vault, primary_manager)
}

/// Enroll with the default simple-enrollment configuration and automatic TPM unlock.
pub fn enroll_and_tpm_unlock_default(
    images: &luks::TestImages,
) -> (BootVault, LuksTpmTokenManager) {
    enroll_and_tpm_unlock(images, "simple-enrollment", None)
}

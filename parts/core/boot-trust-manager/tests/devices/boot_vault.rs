use std::path::PathBuf;

use serial_test::serial;

use crate::common::{display::TestDisplay, luks};
use puavo_boot_trust_manager::{
    devices::boot_vault::BootVault, display::UserDisplay,
};

fn setup() -> luks::TestImages {
    luks::setup("vault")
}

fn display() -> Box<dyn UserDisplay> {
    Box::new(TestDisplay::with_password(luks::RECOVERY_KEY))
}

#[test]
fn mount_with_recovery_key() {
    let images = setup();

    let mut vault = BootVault::default();
    let result = vault.mount(&PathBuf::from(&images.vault), &display());
    assert!(result.is_ok(), "mount failed: {:?}", result.err());

    let key = vault.resources().read_recovery_key();
    assert!(key.is_ok(), "read_recovery_key failed: {:?}", key.err());
    assert_eq!(key.unwrap(), luks::RECOVERY_KEY);
}

#[test]
fn mount_with_wrong_key_fails() {
    let images = setup();
    let wrong_display: Box<dyn UserDisplay> =
        Box::new(TestDisplay::with_password("wrong-key").with_max_attempts(3));

    let mut vault = BootVault::default();
    let result = vault.mount(&PathBuf::from(&images.vault), &wrong_display);
    assert!(result.is_err(), "mount should fail with wrong key");
}

#[test]
fn resources_read_write_property() {
    let images = setup();

    let mut vault = BootVault::default();
    vault.mount(&PathBuf::from(&images.vault), &display()).unwrap();

    let resources = vault.resources();
    resources
        .write_property("test-property", "test-value".to_string())
        .unwrap();

    let value = resources.read_property("test-property").unwrap();
    assert_eq!(value, Some("test-value".to_string()));
}

use serial_test::serial;
use tempfile::TempDir;
use zeroize::Zeroizing;

use puavo_boot_trust_manager::devices::boot_vault::BootVaultResources;

#[test]
#[serial]
fn write_and_read_property() {
    let temp = TempDir::new().unwrap();
    let resources = BootVaultResources::new(temp.path());

    resources.write_property("test_key", "test_value".to_string()).unwrap();

    let value = resources.read_property("test_key").unwrap();
    assert_eq!(value, Some("test_value".to_string()));
}

#[test]
#[serial]
fn read_missing_property_returns_none() {
    let temp = TempDir::new().unwrap();
    let resources = BootVaultResources::new(temp.path());

    let value = resources.read_property("nonexistent").unwrap();
    assert_eq!(value, None);
}

#[test]
#[serial]
fn write_and_read_recovery_key() {
    let temp = TempDir::new().unwrap();
    let resources = BootVaultResources::new(temp.path());

    resources
        .write_recovery_key(&Zeroizing::new("test-recovery-key".to_string()))
        .unwrap();

    let key = resources.read_recovery_key().unwrap();
    assert_eq!(key.as_str(), "test-recovery-key");
}

#[test]
#[serial]
fn read_missing_recovery_key_fails() {
    let temp = TempDir::new().unwrap();
    let resources = BootVaultResources::new(temp.path());

    let result = resources.read_recovery_key();
    assert!(result.is_err());
}

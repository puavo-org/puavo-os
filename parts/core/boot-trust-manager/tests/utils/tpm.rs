use std::path::PathBuf;

use serial_test::serial;
use tempfile::NamedTempFile;

use crate::{
    common::{display::TestDisplay, luks, tpm},
    configurators::enrollment::common::enroll_and_tpm_unlock,
};
use puavo_boot_trust_manager::{
    devices::boot_vault::BootVault,
    display::UserDisplay,
    utils::tpm::{
        clear_dictionary_lockout, is_in_lockout, read_pcrs, read_pcrs_as_string,
    },
};

#[test]
#[serial]
fn test_read_pcrs_matches_tpm2_tools() {
    tpm::reset();

    // Extend PCRs 16 and 23 to get non-zero values
    tpm::extend(
        16,
        "1111111111111111111111111111111111111111111111111111111111111111",
    );
    tpm::extend(
        23,
        "2222222222222222222222222222222222222222222222222222222222222222",
    );

    let result =
        read_pcrs_as_string(&[16, 23]).expect("Failed to read PCR values");

    let pcr16 = tpm::read(16);
    let pcr23 = tpm::read(23);

    assert!(
        result.contains(&pcr16),
        "Expected PCR 16 value {} not in {}",
        pcr16,
        result
    );
    assert!(
        result.contains(&pcr23),
        "Expected PCR 23 value {} not in {}",
        pcr23,
        result
    );
}

#[test]
#[serial]
fn test_read_pcrs_sees_extended_value() {
    tpm::reset();

    let hash =
        "0000000000000000000000000000000000000000000000000000000000000001";
    tpm::extend(16, hash);

    let after = tpm::read(16);
    let result = read_pcrs_as_string(&[16]).expect("Failed to read PCR values");

    assert!(
        result.contains(&after),
        "Extended PCR value {} not in {}",
        after,
        result
    );
}

#[test]
#[serial]
fn test_read_pcrs_empty_list() {
    tpm::reset();

    let result = read_pcrs(&[]).expect("Failed to read empty PCR list");

    assert_eq!(result.len(), 0, "Empty PCR list should return empty result");
}

#[test]
#[serial]
fn test_read_pcrs_invalid_index() {
    tpm::reset();

    let result = read_pcrs(&[32]);

    assert!(
        result.is_err(),
        "Reading invalid PCR index should return an error"
    );

    // Verify the error message mentions the invalid index
    let error = format!("{:?}", result.unwrap_err());
    assert!(
        error.contains("32") || error.to_lowercase().contains("invalid"),
        "Error should mention invalid PCR index, got: {}",
        error
    );
}

#[test]
#[serial]
fn test_read_pcrs_multiple_invalid_indices() {
    tpm::reset();

    // Multiple invalid PCR indices
    let result = read_pcrs(&[30, 31, 32]);

    assert!(
        result.is_err(),
        "Reading multiple invalid PCR indices should return an error"
    );
}

#[test]
#[serial]
fn test_read_pcrs_mixed_valid_invalid() {
    tpm::reset();

    // Mix of valid and invalid PCR indices
    let result = read_pcrs(&[7, 32]);

    assert!(
        result.is_err(),
        "Reading invalid PCR indices should return an error"
    );
}

#[test]
#[serial]
fn test_read_pcrs_sorted_output() {
    tpm::reset();

    // Request PCRs in non-sorted order
    let result = read_pcrs(&[23, 7, 16]).expect("Failed to read PCRs");

    // Verify the output is sorted by index
    let indices: Vec<u32> = result.iter().map(|(index, _)| *index).collect();
    assert_eq!(indices, vec![7, 16, 23], "PCRs should be sorted by index");
}

#[test]
#[serial]
fn test_clear_dictionary_lockout_missing_auth_file() {
    let non_existent_path = "/tmp/nonexistent_lockout_auth_file.txt";

    let result = clear_dictionary_lockout(non_existent_path);

    assert!(
        result.is_ok(),
        "Clearing dictionary lockout should skip and succeed when auth file is missing"
    );
}

#[test]
#[serial]
fn test_dictionary_lockout_and_clear() {
    tpm::reset();
    let images = luks::setup("dictionary_lockout");

    {
        // Enroll with PIN to enable TPM-based PIN unlock
        let (_boot_vault, _primary_manager) =
            enroll_and_tpm_unlock(&images, "simple-enrollment", Some("1234"));
    }

    // Verify TPM is not locked out initially
    assert!(
        !is_in_lockout().expect("Failed to check lockout status"),
        "TPM should not be locked out initially"
    );

    // TPM is configured to allow 8 attempts
    let wrong_passwords: Vec<&str> = (0..9).map(|_| "wrong_password").collect();
    let display: Box<dyn UserDisplay> =
        Box::new(TestDisplay::with_passwords(wrong_passwords.clone()));

    let mut boot_vault = BootVault::default();

    for _ in 0..wrong_passwords.len() {
        let _ = boot_vault.mount(&PathBuf::from(&images.vault), &display);
    }

    // Verify TPM is now locked out
    assert!(
        is_in_lockout().expect("Failed to check lockout status"),
        "TPM should be locked out after failed attempts"
    );

    // Now test clearing the lockout
    // Create lockout auth file (empty for test TPM)
    let auth_file = NamedTempFile::new().expect("Failed to create auth file");

    let result = clear_dictionary_lockout(auth_file.path());
    assert!(result.is_ok(), "Clearing lockout should succeed");

    // Verify lockout was cleared
    assert!(
        !is_in_lockout().expect("Failed to check lockout status"),
        "TPM should not be locked out after clearing"
    );
}

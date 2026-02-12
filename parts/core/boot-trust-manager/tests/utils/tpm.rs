use serial_test::serial;

use crate::common::tpm;
use puavo_boot_trust_manager::utils::tpm::read_pcrs_as_string;

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

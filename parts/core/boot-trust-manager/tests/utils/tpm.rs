use crate::common::tpm;
use puavo_boot_trust_manager::utils::tpm::read_pcrs_as_string;

#[test]
fn test_read_pcrs_matches_tpm2_tools() {
    tpm::reset();

    let result =
        read_pcrs_as_string(&[0, 7]).expect("Failed to read PCR values");

    let pcr0 = tpm::read(0);
    let pcr7 = tpm::read(7);

    assert!(
        result.contains(&pcr0),
        "Expected PCR 0 value {} not in {}",
        pcr0,
        result
    );
    assert!(
        result.contains(&pcr7),
        "Expected PCR 7 value {} not in {}",
        pcr7,
        result
    );
}

#[test]
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

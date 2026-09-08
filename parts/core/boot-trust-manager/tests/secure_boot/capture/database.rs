//! Rebuilds the databases the captured boots measured from their entries and
//! compares the bytes, which checks that the lists this code writes have the
//! format the firmware reads.

use puavo_boot_trust_manager::secure_boot::database::{
    SignatureDatabase, SignatureList,
};

use super::{Capture, microsoft, slab};

/// The contents of the database variable in a capture.
fn measured_database(profile: &str) -> Vec<u8> {
    Capture::read(profile)
        .measured_variables()
        .into_iter()
        .find(|(name, _)| name == "db")
        .expect("capture did not contain database measurement")
        .1
}

/// The same database rebuilt from the entries it reads as.
fn recreate_from_measurement_data(measured: &[u8]) -> Vec<u8> {
    SignatureDatabase::read(measured)
        .unwrap()
        .entries()
        .iter()
        .flat_map(|entry| {
            SignatureList::new(entry.certificate(), entry.owner()).bytes()
        })
        .collect()
}

#[test]
fn recreated_database_is_measured_one() {
    let measured = measured_database(slab::PROFILE);

    assert_eq!(recreate_from_measurement_data(&measured), measured);
}

#[test]
fn microsoft_database_recreates_the_same() {
    let measured = measured_database(microsoft::PROFILE);

    assert_eq!(recreate_from_measurement_data(&measured), measured);
}

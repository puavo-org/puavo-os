//! Tests the validator with a captured boot. The fake device returns the
//! captured PCR value as the current value.

use boot_trust_manager::secure_boot::validator::Validator;

use super::slab;
use super::{Capture, CapturedDevice, write_variables_into_directory};

/// The PCR of the chain, as written in a policy.
const REGISTER_NAME: &str = "7:sha256";

#[test]
fn register_holding_predicted_value_agrees() {
    let capture = Capture::read(slab::PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    let comparison = Validator::new(&device)
        .check(REGISTER_NAME, &slab::chain(directory.path()))
        .unwrap();

    assert_eq!(comparison.matches, Some(true));
    assert_eq!(comparison.current, Some(comparison.predicted.clone()));
}

#[test]
fn register_holding_other_value_disagrees() {
    let capture = Capture::read(slab::PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let mut device = CapturedDevice::of(&capture);
    device.register = Some(hex::encode([0u8; 32]));

    let comparison = Validator::new(&device)
        .check(REGISTER_NAME, &slab::chain(directory.path()))
        .unwrap();

    assert_eq!(comparison.matches, Some(false));
}

#[test]
fn unreadable_register_agrees_with_nothing() {
    // The prediction was not compared with anything, so the caller must not
    // treat it as the current state.
    let capture = Capture::read(slab::PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let mut device = CapturedDevice::of(&capture);
    device.register = None;

    let comparison = Validator::new(&device)
        .check(REGISTER_NAME, &slab::chain(directory.path()))
        .unwrap();

    assert_eq!(comparison.matches, None);
    assert_eq!(comparison.current, None);
}

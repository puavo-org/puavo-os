//! Reads the event log of the captured boots from the bytes the firmware
//! stores, the format the kernel publishes, and compares it with the events
//! the measurements binary printed in the same boot.

use boot_trust_manager::error::PuavoError;
use boot_trust_manager::secure_boot::event_log::{self, Event};

use super::{
    Capture, INITIAL_REGISTER_VALUE, extend_register, microsoft, slab,
};

/// Events of this type are logged but not extended.
const NO_ACTION: &str = "NO_ACTION";

/// The captured boots.
const CAPTURED_PROFILES: [&str; 2] = [slab::PROFILE, microsoft::PROFILE];

/// The register and SHA-256 digest of each extended event.
fn registers_and_digests(events: &[Event]) -> Vec<(u32, String)> {
    events
        .iter()
        .map(|event| (event.register, hex::encode(&event.digest)))
        .collect()
}

#[test]
fn stored_log_holds_the_events_the_capture_printed() {
    for profile in CAPTURED_PROFILES {
        let capture = Capture::read(profile);

        let events = event_log::parse(capture.stored_event_log()).unwrap();

        let printed: Vec<(u32, String)> = capture
            .events
            .iter()
            .filter(|event| event.kind != NO_ACTION)
            .map(|event| (event.register, event.digest.clone()))
            .collect();
        assert_eq!(registers_and_digests(&events), printed, "{profile}");
    }
}

#[test]
fn replaying_the_stored_log_reproduces_the_captured_registers() {
    for profile in CAPTURED_PROFILES {
        let capture = Capture::read(profile);
        let events = event_log::parse(capture.stored_event_log()).unwrap();

        for (register, value) in &capture.registers {
            let replayed = events
                .iter()
                .filter(|event| event.register == *register)
                .fold(hex::encode(INITIAL_REGISTER_VALUE), |value, event| {
                    extend_register(&value, &hex::encode(&event.digest))
                });

            assert_eq!(&replayed, value, "{profile} PCR {register}");
        }
    }
}

#[test]
fn log_missing_its_last_byte_is_refused() {
    let capture = Capture::read(slab::PROFILE);
    let log = capture.stored_event_log();

    let result = event_log::parse(&log[..log.len() - 1]);

    assert!(matches!(result, Err(PuavoError::MalformedEventLog(_))));
}

#[test]
fn log_that_does_not_list_its_digest_algorithms_is_refused() {
    let result = event_log::parse(&[0; 64]);

    assert!(matches!(result, Err(PuavoError::MalformedEventLog(_))));
}

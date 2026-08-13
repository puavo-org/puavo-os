//! The TPM based anti-rollback implementation.
//! Reads monotonic counter and a base, refuses
//! next stage bootloaders below the minimum versions.
//! Raises the version to match the embedded list version.

use crate::debug;
use crate::revocations;
use crate::shutdown;
use crate::tpm::{self, CommandError};
use alloc::string::String;
use core::fmt::Write;
use uefi::boot::{self, ScopedProtocol};
use uefi::proto::tcg::v2::Tcg;

/// NV index holding the revocation counter.
const COUNTER_INDEX: u32 = 0x0151_4B00;
/// NV index holding the base, the counter value the device started from.
const BASE_INDEX: u32 = 0x0151_4B01;

/// Opens the firmware TCG2 protocol.
/// Returns `None` when no TPM is present.
pub fn open_tcg() -> Option<ScopedProtocol<Tcg>> {
    let handle = boot::get_handle_for_protocol::<Tcg>().ok()?;
    boot::open_protocol_exclusive::<Tcg>(handle).ok()
}

/// Enforces the rollback floor, then raises and locks the counter to this
/// slab's list version. Any failure that cannot be proven safe shuts the
/// machine down rather than continuing the boot.
pub fn enforce(tcg: &mut Tcg) {
    let (base, counter) = match ensure_indices(tcg) {
        Some(values) => values,
        None => shutdown(),
    };

    // Pin the base and record slab presence in PCR 7.
    if let Err(error) = tpm::extend_base(tcg, base) {
        error_with_tpm_code("failed to extend the base into PCR 7", error);
        shutdown();
    }
    if debug::is_enabled() {
        if let Ok(pcr) = tpm::read_pcr(tcg, tpm::BASE_PCR) {
            debug!("PCR 7 after extend: {}", hex(&pcr));
        }
    }

    // Only a counter cannot be lowered, so an index of another type at this
    // handle must not be trusted as the floor.
    match tpm::is_counter(tcg, COUNTER_INDEX) {
        Ok(true) => {}
        Ok(false) => {
            security_violation!(
                "counter index is not a proper counter, refusing"
            );
            shutdown();
        }
        Err(_) => {
            error!("cannot read counter public area, refusing");
            shutdown();
        }
    }

    if counter < base {
        // The counter starts at the base and should only rise.
        security_violation!("counter below base, refusing to continue");
        shutdown();
    }

    // Compute the current minimum version (floor) and
    // fetch the embedded list version for comparison.
    let floor = counter - base;
    let list_version = revocations::LIST_VERSION;
    debug!("counter {counter}, base {base}");
    debug!("floor {floor}, list version {list_version}");

    if list_version < floor {
        security_violation!(
            "this device could not start because its startup software is too old, please contact your administrator"
        );
        shutdown();
    }

    // Raise the version to match the embedded list version.
    if list_version > floor {
        raise_counter_to(tcg, counter, base + list_version);
    }

    // Lock write access to the counter to prevent misuse.
    if let Err(error) = tpm::write_lock(tcg, COUNTER_INDEX) {
        error_with_tpm_code("could not write-lock the counter", error);
        shutdown();
    }

    debug!("counter write-locked for the rest of this boot");
}

/// Reads the base and counter. Defines both when both are absent.
/// If exactly one is absent, the mapping is inconsistent, so it refuses.
/// A define sets the base to the current counter, so on an enrolled
/// device the floor can never end up lower, without PCR change.
fn ensure_indices(tcg: &mut Tcg) -> Option<(u64, u64)> {
    let base = tpm::read_value(tcg, BASE_INDEX);
    let counter = tpm::read_value(tcg, COUNTER_INDEX);
    match (base, counter) {
        (Ok(base), Ok(counter)) => Some((base, counter)),
        (Err(_), Err(_)) => {
            if initialize_indices(tcg).is_err() {
                error!("failed to initialize NV indices, refusing to continue");
                return None;
            }
            let base = tpm::read_value(tcg, BASE_INDEX).ok()?;
            let counter = tpm::read_value(tcg, COUNTER_INDEX).ok()?;
            Some((base, counter))
        }
        _ => {
            error!("NV indices inconsistent, refusing to continue");
            None
        }
    }
}

/// Defines the counter and base on a fresh device, with the base set to the
/// counter's start value so the floor starts at zero.
fn initialize_indices(tcg: &mut Tcg) -> Result<(), ()> {
    tpm::define_counter(tcg, COUNTER_INDEX).map_err(|error| {
        error_with_tpm_code("could not define the counter index", error)
    })?;
    tpm::increment_counter(tcg, COUNTER_INDEX).map_err(|error| {
        error_with_tpm_code("could not initialize the counter", error)
    })?;
    let initial = tpm::read_value(tcg, COUNTER_INDEX).map_err(|error| {
        error_with_tpm_code("could not read the initial counter", error)
    })?;
    tpm::define_base(tcg, BASE_INDEX).map_err(|error| {
        error_with_tpm_code("could not define the base index", error)
    })?;
    tpm::write_value(tcg, BASE_INDEX, initial)
        .map_err(|error| error_with_tpm_code("could not write the base", error))
}

/// Raises the counter to the target. The counter only rises, so
/// this moves the floor forward and never lowers it. A failed raise
/// shuts the machine down so revocation cannot silently stall.
fn raise_counter_to(tcg: &mut Tcg, current: u64, target: u64) {
    if target <= current {
        return;
    }
    debug!("raising counter from {current} to {target}");
    let mut value = current;
    while value < target {
        if let Err(error) = tpm::increment_counter(tcg, COUNTER_INDEX) {
            error_with_tpm_code("could not raise the counter", error);
            shutdown();
        }
        value = match tpm::read_value(tcg, COUNTER_INDEX) {
            Ok(current_value) => current_value,
            Err(error) => {
                error_with_tpm_code("could not read the raised counter", error);
                shutdown();
            }
        };
    }
}

/// Prints the error message with the cause of the failure.
fn error_with_tpm_code(message: &str, error: CommandError) {
    match error {
        CommandError::Rejected(code) => {
            error!("{message} (TPM code {code:#06x})")
        }
        CommandError::Transport(status) => {
            error!("{message} (EFI status {status:?})")
        }
        CommandError::MalformedResponse => {
            error!("{message} (malformed TPM response)")
        }
    }
}

/// Formats a byte slice as lowercase hex, for printing a PCR digest.
fn hex(bytes: &[u8]) -> String {
    let mut text = String::new();
    for byte in bytes {
        let _ = write!(text, "{byte:02x}");
    }
    text
}

// Slab bootloader. Firmware loads it first. It enforces a TPM anti-rollback
// floor and then chainloads the next stage. The revocation list is embedded,
// so the firmware Secure Boot check on slab vouches for it and slab needs no
// signature code.
#![no_main]
#![no_std]

extern crate alloc;

#[macro_use]
mod debug;
mod chainload;
mod revocations;
mod pe;
mod rollback;
mod tpm;

use uefi::runtime::{self, ResetType};
use uefi::{entry, Status};

#[entry]
fn main() -> Status {
    if uefi::helpers::init().is_err() {
        return Status::ABORTED;
    }

    debug::initialize();
    debug!("slab: starting");

    // A device without a TPM has no counter to enforce and no sealed disk to
    // protect, so slab continues. A present but broken or tampered TPM still
    // refuses, inside enforce.
    match rollback::open_tcg() {
        Some(mut tcg) => rollback::enforce(&mut tcg),
        None => {
            debug!("no TPM present, continuing without enforcement")
        }
    };

    let next_stage = match chainload::read() {
        Some(bytes) => bytes,
        None => {
            error!("next stage missing, refusing to continue");
            shutdown();
        }
    };

    if !chainload::is_allowed(&next_stage) {
        shutdown();
    }

    debug!("chainloading next stage");
    debug::pause_before_handoff();

    match chainload::start(&next_stage) {
        Ok(()) => error!("next stage returned to slab"),
        Err(status) => error!("chainload failed: {status:?}"),
    }

    shutdown();
}

/// Powers the machine off.
pub fn shutdown() -> ! {
    runtime::reset(ResetType::SHUTDOWN, Status::SUCCESS, None)
}

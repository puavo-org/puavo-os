// First stage bootloader. Firmware loads it first. It enforces a TPM
// anti-rollback floor and then chainloads the next stage. The revocation list
// is embedded, so the firmware Secure Boot check on this image vouches for the
// list and no signature code is needed for it.
#![no_main]
#![no_std]

extern crate alloc;

#[macro_use]
mod debug;
mod chainload;
mod pe;
mod revocations;
mod rollback;
mod shim_lock;
mod tpm;
#[cfg(feature = "verifier")]
mod verifier;

use uefi::runtime::{self, ResetType};
use uefi::{Status, entry};

#[entry]
fn main() -> Status {
    if uefi::helpers::init().is_err() {
        return Status::ABORTED;
    }

    debug::initialize();
    debug!("slab: starting");

    // Prevent nested chainloading of this bootloader.
    if shim_lock::installed_already() {
        security_violation!(
            "another image verification protocol is already in place, refusing in order to protect against undefined behavior"
        );
        shutdown();
    }

    // A device without a TPM has no counter to enforce and no sealed disk to
    // protect, so the boot continues. A present but broken or tampered TPM
    // still refuses, inside enforce.
    match rollback::open_tcg() {
        Some(mut tcg) => rollback::enforce(&mut tcg),
        None => {
            debug!("no TPM present, continuing without enforcement")
        }
    };

    // The next stage can verify the images it loads through this protocol.
    if !shim_lock::initialize() {
        error!("failed to install the image verification protocol, refusing");
        shutdown();
    }

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
        Ok(()) => error!("next stage returned back"),
        Err(status) => error!("chainload failed: {status:?}"),
    }

    shutdown();
}

/// Powers the machine off.
pub fn shutdown() -> ! {
    runtime::reset(ResetType::SHUTDOWN, Status::SUCCESS, None)
}

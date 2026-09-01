use log::{debug, error, info};
use nix::libc::{RB_AUTOBOOT, reboot, sync};
use std::sync::atomic::{AtomicBool, Ordering};

/// Set when something requires the machine to reboot upon program exit.
static REBOOT_REQUESTED: AtomicBool = AtomicBool::new(false);

/// Request reboot upon program exit.
pub fn request() {
    debug!("Requesting reboot...");
    REBOOT_REQUESTED.store(true, Ordering::SeqCst);
}

/// Whether a reboot has been requested.
pub fn is_requested() -> bool {
    REBOOT_REQUESTED.load(Ordering::SeqCst)
}

/// If requested, flush filesystems and restart the machine.
pub fn reboot_if_requested() {
    if !is_requested() {
        debug!("Reboot was not requested");
        return;
    }

    info!("Reboot requested, restarting now");
    // SAFETY: Sync takes no arguments and reboot takes a command constant.
    let result = unsafe {
        sync();
        reboot(RB_AUTOBOOT)
    };
    error!("Reboot system call returned with code {}", result);
}

#[cfg(test)]
pub fn reset() {
    REBOOT_REQUESTED.store(false, Ordering::SeqCst);
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;

    #[test]
    #[serial]
    fn request_sets_flag_and_reset_clears_it() {
        reset();
        assert!(!is_requested());

        request();
        assert!(is_requested());

        reset();
        assert!(!is_requested());
    }
}

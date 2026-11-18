//! Restarting and powering off the device through systemd, which stops the
//! services and unmounts the disks first.

use std::process::Command;

pub fn restart() {
    run_systemctl(&["reboot"]);
}

pub fn power_off() {
    run_systemctl(&["poweroff"]);
}

/// Restarts into the setup program of the firmware where the firmware takes
/// such a request, otherwise just restarts.
pub fn open_firmware_setup() {
    if !run_systemctl(&["reboot", "--firmware-setup"]) {
        log::warn!("failed to ask for the firmware setup");
        restart();
    }
}

/// Whether systemctl did what the arguments ask.
fn run_systemctl(arguments: &[&str]) -> bool {
    Command::new("systemctl")
        .args(arguments)
        .status()
        .is_ok_and(|status| status.success())
}

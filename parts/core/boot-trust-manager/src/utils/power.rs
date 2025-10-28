use std::process::Command;

/// Attempt to reboot the system. If the reboot command returns, spin to
/// prevent further execution.
pub fn reboot_or_halt() {
    let _ = Command::new("reboot").status();
    loop {}
}

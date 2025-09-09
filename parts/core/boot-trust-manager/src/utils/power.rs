use std::process::Command;

pub fn reboot_or_halt() {
    let _ = Command::new("reboot").status();
    loop {}
}
//! Console output.

use alloc::string::String;
use core::fmt::Write;
use core::sync::atomic::{AtomicBool, Ordering};
use uefi::runtime::{self, VariableVendor};
use uefi::{CStr16, boot, cstr16, guid};

/// Prints only in debug mode, so a normal boot stays silent.
macro_rules! debug {
    ($($arg:tt)*) => {
        if $crate::debug::is_enabled() {
            uefi::println!($($arg)*);
        }
    };
}

/// Prints one step of deciding about an image. Steps are indented under the
/// line that announces the decision, so what belongs to which decision can be
/// told apart when several images are decided about in one boot.
macro_rules! verification {
    ($($arg:tt)*) => {
        debug!("  {}", format_args!($($arg)*))
    };
}

/// Prints an error. Always prints, even on a silent boot.
macro_rules! error {
    ($($arg:tt)*) => {
        uefi::println!("error: {}", format_args!($($arg)*))
    };
}

/// Prints a security violation. Always prints, even on a silent boot.
macro_rules! security_violation {
    ($($arg:tt)*) => {
        uefi::println!("security violation: {}", format_args!($($arg)*))
    };
}

/// Stores whether the debug mode is active.
static ENABLED: AtomicBool = AtomicBool::new(false);

/// Name of the debug mode EFI variable.
const VARIABLE: &CStr16 = cstr16!("SlabDebug");
/// EFI variable vendor GUIDs for the debug mode variable.
const VENDORS: [VariableVendor; 2] = [
    VariableVendor(guid!("7cb44677-9bb9-4504-bb8f-923def5fa3b1")),
    VariableVendor::GLOBAL_VARIABLE,
];
/// How long to pause before handing off control to the next stage.
const PAUSE_MICROSECONDS: usize = 5_000_000;

/// Formats bytes as lowercase hex.
pub fn hex(bytes: &[u8]) -> String {
    let mut text = String::new();
    for byte in bytes {
        let _ = write!(text, "{byte:02x}");
    }
    text
}

/// Reads the debug variable once and remembers whether debug is on.
pub fn initialize() {
    ENABLED.store(detect(), Ordering::Relaxed);
}

/// Whether debug output is on.
pub fn is_enabled() -> bool {
    ENABLED.load(Ordering::Relaxed)
}

/// Pauses before the next stage in debug mode so a human can read the output.
pub fn pause_before_handoff() {
    if is_enabled() {
        debug!("debug mode, pausing before the next stage");
        boot::stall(PAUSE_MICROSECONDS);
    }
}

/// A read error is treated as off.
fn detect() -> bool {
    VENDORS.iter().any(|vendor| {
        runtime::variable_exists(VARIABLE, vendor).unwrap_or(false)
    })
}

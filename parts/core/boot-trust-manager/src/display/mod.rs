use std::time::Duration;

use log::{debug, warn};

use crate::{
    display::{console::ConsoleDisplay, plymouth::PlymouthDisplay},
    error::PuavoError,
};

pub mod console;
pub mod plymouth;

/// How long to wait after showing a message with Plymouth?
const DISPLAY_STOP_DURATION: u64 = 1000;

/// Abstraction for displaying messages and asking for secrets to the user.
pub trait UserDisplay {
    /// Ask the user for a password.
    ///
    /// Parameters:
    /// - `prompt`: The human-readable text shown before password entry.
    ///
    /// Errors:
    /// Returns a `PuavoError` if the underlying backend fails.
    fn ask_password(&self, prompt: &str) -> Result<String, PuavoError>;

    /// Show a message to the user.
    ///
    /// Parameters:
    /// - `text`: The message to display.
    ///
    /// Errors:
    /// Returns a `PuavoError` if the backend fails to render the message.
    fn show_message(&self, text: &str) -> Result<(), PuavoError>;
}

/// Pick a suitable display backend.
///
/// Parameters:
/// - `force_console`: If `true`, always return a console-based display.
///                    If `false` and Plymouth is available, returns
///                    a Plymouth-based display. Otherwise fall back to console.
///
/// Errors:
/// This function never errors.
/// Failures to initialize Plymouth are logged and the console display is returned.
pub fn choose_display(force_console: bool) -> Box<dyn UserDisplay> {
    let console_display =
        Box::new(ConsoleDisplay::new()) as Box<dyn UserDisplay>;

    let plymouth_available = PlymouthDisplay::ping().is_ok();
    debug!("Plymouth available: {}", plymouth_available);

    if force_console || !plymouth_available {
        return console_display;
    }

    PlymouthDisplay::new(Duration::from_millis(DISPLAY_STOP_DURATION))
        .inspect_err(|error| {
            warn!("Failed to initialize Plymouth display: {}", error)
        })
        .map(|plymouth| Box::new(plymouth) as Box<dyn UserDisplay>)
        .unwrap_or(console_display) // Fallback
}

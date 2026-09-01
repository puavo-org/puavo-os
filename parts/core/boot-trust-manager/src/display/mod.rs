use std::time::Duration;

use log::{debug, warn};
use zeroize::Zeroizing;

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
    /// - `prompt`: The text shown before password entry.
    ///
    /// Errors:
    /// Returns a `PuavoError` if the underlying backend fails.
    fn ask_password(
        &self,
        prompt: &str,
    ) -> Result<Zeroizing<String>, PuavoError>;

    /// Show text alongside whatever else is on screen.
    /// Replaces any overlay already shown.
    fn show_overlay(&self, _text: &str) -> Result<(), PuavoError> {
        Ok(())
    }

    /// Hide the overlay that is shown alongside whatever else is on screen.
    fn hide_overlay(&self) -> Result<(), PuavoError> {
        Ok(())
    }

    /// Ask the user a yes/no question.
    ///
    /// Parameters:
    /// - `prompt`: The text shown before asking.
    ///
    /// Returns:
    /// - `Ok(true)` if the user answered yes.
    /// - `Ok(false)` if the user answered no.
    ///
    /// Errors:
    /// Returns a `PuavoError` if the underlying backend fails.
    fn ask_yes_no(&self, prompt: &str) -> Result<bool, PuavoError>;

    /// Show a message to the user.
    ///
    /// Parameters:
    /// - `text`: The message to display.
    ///
    /// Errors:
    /// Returns a `PuavoError` if the backend fails to render the message.
    fn show_message(&self, text: &str) -> Result<(), PuavoError>;

    /// Clear any displayed messages.
    ///
    /// Errors:
    /// Returns a `PuavoError` if the backend fails to clear the display.
    fn clear(&self) -> Result<(), PuavoError>;
}

/// Pick a suitable display backend.
///
/// Parameters:
/// - `force_console`: Should console-based display be used.
///
/// Errors:
/// This function never errors.
/// Failures to initialize Plymouth are logged and the console display is returned.
pub fn choose_display(force_console: bool) -> Box<dyn UserDisplay> {
    let console_display =
        Box::new(ConsoleDisplay::new()) as Box<dyn UserDisplay>;

    let plymouth_available = PlymouthDisplay::ping().unwrap_or(false);
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

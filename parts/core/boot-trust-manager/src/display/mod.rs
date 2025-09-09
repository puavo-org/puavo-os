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

pub trait UserDisplay {
    fn ask_password(&self, prompt: &str) -> Result<String, PuavoError>;
    fn show_message(&self, text: &str) -> Result<(), PuavoError>;
}

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

use std::{process::Command, thread, time::Duration};

use crate::{display::UserDisplay, error::PuavoError};

/// Plymouth-backed `UserDisplay` implementation.
pub struct PlymouthDisplay {
    display_stop_duration: Duration,
}

impl PlymouthDisplay {
    /// Create a new Plymouth display.
    ///
    /// Parameters:
    /// - `display_stop_duration`: How long to sleep after displaying a message,
    ///   to ensure the user has time to read it.
    /// 
    /// Errors:
    /// This function never errors.
    pub fn new(display_stop_duration: Duration) -> Result<Self, PuavoError> {
        Ok(Self { display_stop_duration })
    }

    /// Check if Plymouth is reachable.
    ///
    /// Returns:
    /// - `Ok(true)` if Plymouth is running and reachable.
    /// - `Ok(false)` if Plymouth is not running.
    /// 
    /// Errors:
    /// Returns an `PuavoError::IoError` if invoking the command fails.
    pub fn ping() -> Result<bool, PuavoError> {
        let status = Command::new("plymouth").arg("--ping").status()?;
        Ok(status.success())
    }
}

impl UserDisplay for PlymouthDisplay {
    /// Ask for a password via Plymouth.
    ///
    /// Parameters:
    /// - `prompt`: Text to show in the Plymouth password dialog.
    ///
    /// Errors:
    /// Returns `PuavoError::PlymouthError` if the command exits non-zero,
    /// or an `PuavoError::IoError` if invoking the command fails.
    fn ask_password(&self, prompt: &str) -> Result<String, PuavoError> {
        let output = Command::new("plymouth")
            .arg("ask-for-password")
            .arg(format!("--prompt={}", prompt))
            .output()?;

        if !output.status.success() {
            return Err(PuavoError::PlymouthError(
                output.status.code().unwrap_or(-1),
            ));
        }

        let password = String::from_utf8_lossy(&output.stdout).to_string();
        Ok(password.trim_end_matches(['\n', '\r']).to_string())
    }

    /// Display an informational message via Plymouth.
    /// After displaying the message, waits for a short duration,
    /// so the user has time to read it.
    ///
    /// Parameters:
    /// - `text`: The message to display.
    ///
    /// Errors:
    /// Returns `PuavoError::PlymouthError` if the command exits non-zero,
    /// or an `PuavoError::IoError` if invoking the command fails.
    fn show_message(&self, text: &str) -> Result<(), PuavoError> {
        let status = Command::new("plymouth")
            .arg("display-message")
            .arg(format!("--text={}", text))
            .status()?;

        if !status.success() {
            return Err(PuavoError::PlymouthError(status.code().unwrap_or(-1)));
        }

        thread::sleep(self.display_stop_duration);

        Ok(())
    }
}

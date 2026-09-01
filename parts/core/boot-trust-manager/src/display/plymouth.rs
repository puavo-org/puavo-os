use std::{path::Path, process::Command, thread, time::Duration};

use log::info;
use zeroize::{Zeroize as _, Zeroizing};

use crate::{display::UserDisplay, error::PuavoError};

/// Path where Plymouth script expects images to be placed.
const PLYMOUTH_IMAGE_PATH: &str = "/run/plymouth-image.png";

/// Plymouth status string that tells the active theme to
/// load and display an image from the expected location.
const COMMAND_SHOW_IMAGE: &str = "001";

/// Show text in a corner of the screen.
const COMMAND_SHOW_OVERLAY: &str = "002";

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
    /// Returns `PuavoError::IoError` if invoking the command fails.
    pub fn ping() -> Result<bool, PuavoError> {
        let status = Command::new("plymouth").arg("--ping").status()?;
        Ok(status.success())
    }
}

/// Send a status update to the Plymouth theme,
/// which triggers a handler function in the theme's script.
pub fn send_status_update(status: &str) -> Result<(), PuavoError> {
    let result = Command::new("plymouth")
        .arg("update")
        .arg(format!("--status={}", status))
        .status()?;

    if !result.success() {
        return Err(PuavoError::PlymouthError(result.code().unwrap_or(-1)));
    }

    Ok(())
}

/// Send a command to the Plymouth theme.
pub fn send_command(command: &str, argument: &str) -> Result<(), PuavoError> {
    send_status_update(&format!("{}:{}", command, argument))
}

/// Displays the specified image using Plymouth.
pub fn show_image(source_path: &Path) -> Result<(), PuavoError> {
    let destination = Path::new(PLYMOUTH_IMAGE_PATH);
    std::fs::copy(source_path, destination)?;

    info!("Plymouth image copied to {}", destination.display());

    send_command(COMMAND_SHOW_IMAGE, "")
}

impl UserDisplay for PlymouthDisplay {
    /// Ask for a password via Plymouth.
    ///
    /// Parameters:
    /// - `prompt`: Text to show in the Plymouth password dialog.
    ///
    /// Errors:
    /// Returns `PuavoError::PlymouthError` if the command exits non-zero,
    /// or `PuavoError::IoError` if invoking the command fails.
    fn ask_password(
        &self,
        prompt: &str,
    ) -> Result<Zeroizing<String>, PuavoError> {
        let mut output = Command::new("plymouth")
            .arg("ask-for-password")
            .arg(format!("--prompt={}", prompt))
            .output()?;

        if !output.status.success() {
            return Err(PuavoError::PlymouthError(
                output.status.code().unwrap_or(-1),
            ));
        }

        let password = Zeroizing::new(
            String::from_utf8_lossy(&output.stdout)
                .trim_end_matches(['\n', '\r'])
                .to_string(),
        );
        output.stdout.zeroize();
        Ok(password)
    }

    /// Show text alongside whatever else is on screen.
    /// Replaces any overlay already shown.
    fn show_overlay(&self, text: &str) -> Result<(), PuavoError> {
        send_command(COMMAND_SHOW_OVERLAY, text)
    }

    /// Hide the overlay that is shown alongside whatever else is on screen.
    fn hide_overlay(&self) -> Result<(), PuavoError> {
        send_command(COMMAND_SHOW_OVERLAY, "")
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
    /// or `PuavoError::IoError` if invoking the command fails.
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

    /// Clear all displayed messages via Plymouth.
    /// This is done by displaying a whitespace message (unfortunately).
    ///
    /// Errors:
    /// Returns `PuavoError::PlymouthError` if the command exits non-zero,
    /// or `PuavoError::IoError` if invoking the command fails.
    fn clear(&self) -> Result<(), PuavoError> {
        self.show_message(" ")
    }

    /// Ask a yes/no question via Plymouth.
    ///
    /// Parameters:
    /// - `prompt`: Text to show in the Plymouth question dialog.
    ///
    /// Returns:
    /// - `Ok(true)` if the user answered yes.
    /// - `Ok(false)` if the user answered no.
    ///
    /// Errors:
    /// Returns `PuavoError::PlymouthError` if the command exits non-zero,
    /// or `PuavoError::IoError` if invoking the command fails.
    fn ask_yes_no(&self, prompt: &str) -> Result<bool, PuavoError> {
        let output = Command::new("plymouth")
            .arg("ask-question")
            .arg(format!("--prompt={} [y/n]", prompt))
            .output()?;

        if !output.status.success() {
            return Err(PuavoError::PlymouthError(
                output.status.code().unwrap_or(-1),
            ));
        }

        let answer =
            String::from_utf8_lossy(&output.stdout).trim().to_lowercase();

        Ok(answer == "y" || answer == "yes")
    }
}

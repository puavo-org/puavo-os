use crate::{display::UserDisplay, error::PuavoError};

use std::io::{self, BufRead, Write};
use zeroize::Zeroizing;

/// Console-backed `UserDisplay` implementation.
pub struct ConsoleDisplay;

impl ConsoleDisplay {
    /// Create a new console display.
    pub fn new() -> Self {
        Self
    }
}

impl Default for ConsoleDisplay {
    fn default() -> Self {
        Self::new()
    }
}

impl UserDisplay for ConsoleDisplay {
    /// Ask for a password on the controlling terminal.
    ///
    /// Parameters:
    /// - `prompt`: Text printed before reading the password.
    ///
    /// Errors:
    /// Returns `PuavoError` if reading from the terminal fails.
    fn ask_password(
        &self,
        prompt: &str,
    ) -> Result<Zeroizing<String>, PuavoError> {
        print!("{}: ", prompt);
        io::stdout().flush().unwrap();

        let password = rpassword::read_password()?;
        Ok(Zeroizing::new(password))
    }

    /// Ask a yes/no question on the controlling terminal.
    ///
    /// Parameters:
    /// - `prompt`: Text printed before reading the answer.
    ///
    /// Returns:
    /// - `Ok(true)` if the user answered yes.
    /// - `Ok(false)` if the user answered no.
    ///
    /// Errors:
    /// Returns `PuavoError` if reading from the terminal fails.
    fn ask_yes_no(&self, prompt: &str) -> Result<bool, PuavoError> {
        loop {
            print!("{} [y/n]: ", prompt);
            let _ = io::stdout().flush();

            let mut input = String::new();
            io::stdin().lock().read_line(&mut input)?;

            match input.trim().to_lowercase().as_str() {
                "y" | "yes" => return Ok(true),
                "n" | "no" => return Ok(false),
                _ => {
                    println!("Please answer 'y' or 'n'");
                    continue;
                }
            }
        }
    }

    /// Print an informational message to the console.
    ///
    /// Parameters:
    /// - `text`: The message to output.
    ///
    /// Errors:
    /// This function never errors.
    fn show_message(&self, text: &str) -> Result<(), PuavoError> {
        println!("{}", text);
        Ok(())
    }

    /// Show text alongside whatever else is on screen.
    /// Replaces any overlay already shown.
    fn show_overlay(&self, text: &str) -> Result<(), PuavoError> {
        println!("{}", text);
        Ok(())
    }

    /// Clear the display (no-op).
    ///
    /// Errors:
    /// This function never errors.
    fn clear(&self) -> Result<(), PuavoError> {
        Ok(())
    }
}

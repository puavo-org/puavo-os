use crate::{display::UserDisplay, error::PuavoError};

use std::io::{self, Write};

/// Console-backed `UserDisplay` implementation.
pub struct ConsoleDisplay;

impl ConsoleDisplay {
    /// Create a new console display.
    pub fn new() -> Self {
        Self
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
    fn ask_password(&self, prompt: &str) -> Result<String, PuavoError> {
        print!("{}", prompt);
        io::stdout().flush().unwrap();

        let password = rpassword::read_password()?;
        Ok(password)
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
}
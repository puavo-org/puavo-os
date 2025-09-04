use crate::{display::UserDisplay, error::PuavoError};

use std::io::{self, Write};

pub struct ConsoleDisplay;

impl ConsoleDisplay {
    pub fn new() -> Self {
        Self
    }
}

impl UserDisplay for ConsoleDisplay {
    fn ask_password(&self, prompt: &str) -> Result<String, PuavoError> {
        print!("{}", prompt);
        io::stdout().flush().unwrap();

        let password = rpassword::read_password()?;
        Ok(password)
    }

    fn show_message(&self, text: &str) -> Result<(), PuavoError> {
        println!("{}", text);
        Ok(())
    }
}
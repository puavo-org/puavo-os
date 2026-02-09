use std::cell::Cell;

use puavo_boot_trust_manager::display::UserDisplay;
use puavo_boot_trust_manager::error::PuavoError;

pub struct TestDisplay {
    password: Option<String>,
    max_attempts: u32,
    attempts: Cell<u32>,
}

impl TestDisplay {
    pub fn with_password(password: &str) -> Self {
        Self {
            password: Some(password.to_string()),
            max_attempts: u32::MAX,
            attempts: Cell::new(0),
        }
    }

    pub fn with_max_attempts(mut self, max: u32) -> Self {
        self.max_attempts = max;
        self
    }
}

impl UserDisplay for TestDisplay {
    fn ask_password(&self, _prompt: &str) -> Result<String, PuavoError> {
        let current = self.attempts.get();
        if current >= self.max_attempts {
            return Err(PuavoError::UnlockError);
        }
        self.attempts.set(current + 1);

        self.password.clone().ok_or(PuavoError::UnlockError)
    }

    fn ask_yes_no(&self, _prompt: &str) -> Result<bool, PuavoError> {
        Ok(true)
    }

    fn show_message(&self, _text: &str) -> Result<(), PuavoError> {
        Ok(())
    }

    fn clear(&self) -> Result<(), PuavoError> {
        Ok(())
    }
}

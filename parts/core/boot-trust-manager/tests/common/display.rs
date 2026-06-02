use std::cell::{Cell, RefCell};

use puavo_boot_trust_manager::display::UserDisplay;
use puavo_boot_trust_manager::error::PuavoError;
use zeroize::Zeroizing;

/// A test display that can be configured with sequences of responses.
pub struct TestDisplay {
    /// Sequence of passwords to return
    passwords: RefCell<Vec<String>>,
    /// Sequence of yes/no responses to return
    yes_no_responses: RefCell<Vec<bool>>,
    /// Maximum number of password attempts before failing
    max_attempts: u32,
    /// Current attempt count
    attempts: Cell<u32>,
    /// Prompts passed to `ask_password`, in order.
    prompts: RefCell<Vec<String>>,
}

impl TestDisplay {
    /// Create a display that returns the same password for all prompts.
    pub fn with_password(password: &str) -> Self {
        Self {
            passwords: RefCell::new(vec![password.to_string()]),
            yes_no_responses: RefCell::new(Vec::new()),
            max_attempts: u32::MAX,
            attempts: Cell::new(0),
            prompts: RefCell::new(Vec::new()),
        }
    }

    /// Create a display with a sequence of passwords to return.
    pub fn with_passwords(passwords: Vec<&str>) -> Self {
        Self {
            passwords: RefCell::new(
                passwords.into_iter().map(String::from).collect(),
            ),
            yes_no_responses: RefCell::new(Vec::new()),
            max_attempts: u32::MAX,
            attempts: Cell::new(0),
            prompts: RefCell::new(Vec::new()),
        }
    }

    /// Return the prompts passed to `ask_password` so far, in order.
    pub fn recorded_prompts(&self) -> Vec<String> {
        self.prompts.borrow().clone()
    }

    /// Set the maximum number of password attempts before returning an error.
    pub fn with_max_attempts(mut self, max: u32) -> Self {
        self.max_attempts = max;
        self
    }

    /// Set a sequence of yes/no responses to return.
    pub fn with_yes_no_responses(mut self, responses: Vec<bool>) -> Self {
        self.yes_no_responses = RefCell::new(responses);
        self
    }
}

impl UserDisplay for TestDisplay {
    fn ask_password(
        &self,
        prompt: &str,
    ) -> Result<Zeroizing<String>, PuavoError> {
        self.prompts.borrow_mut().push(prompt.to_string());

        let current = self.attempts.get();
        if current >= self.max_attempts {
            return Err(PuavoError::UnlockError);
        }
        self.attempts.set(current + 1);

        self.passwords
            .borrow_mut()
            .pop()
            .map(Zeroizing::new)
            .ok_or(PuavoError::UnlockError)
    }

    fn ask_yes_no(&self, _prompt: &str) -> Result<bool, PuavoError> {
        self.yes_no_responses.borrow_mut().pop().ok_or(PuavoError::UnlockError)
    }

    fn show_message(&self, _text: &str) -> Result<(), PuavoError> {
        Ok(())
    }

    fn clear(&self) -> Result<(), PuavoError> {
        Ok(())
    }
}

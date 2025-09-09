use std::{process::Command, thread, time::Duration};

use crate::{display::UserDisplay, error::PuavoError};

pub struct PlymouthDisplay {
    display_stop_duration: Duration,
}

impl PlymouthDisplay {
    pub fn new(display_stop_duration: Duration) -> Result<Self, PuavoError> {
        Ok(Self { display_stop_duration })
    }

    pub fn ping() -> Result<bool, PuavoError> {
        let status = Command::new("plymouth").arg("--ping").status()?;
        Ok(status.success())
    }
}

impl UserDisplay for PlymouthDisplay {
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

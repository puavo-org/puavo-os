use crate::error::PuavoError;

pub mod console;
pub mod plymouth;

pub trait UserDisplay {
    fn ask_password(&self, prompt: &str) -> Result<String, PuavoError>;
    fn show_message(&self, text: &str) -> Result<(), PuavoError>;
}
//! Keys from the console. The kernel keymap turns them into characters, so
//! the keyboard layout of the environment applies.

use std::io::{self, Write};
use std::time::Duration;

use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use crossterm::terminal;
use slint::platform::Key;
use slint::SharedString;

const CURSOR_BLINK: &str = "/sys/class/graphics/fbcon/cursor_blink";
const HIDE_CURSOR: &str = "\x1b[?25l";

pub struct Keyboard;

impl Keyboard {
    /// Takes the console keys and keeps the console cursor off the drawing.
    pub fn open() -> io::Result<Self> {
        terminal::enable_raw_mode()?;
        let _ = std::fs::write(CURSOR_BLINK, "0");
        let mut output = io::stdout();
        output.write_all(HIDE_CURSOR.as_bytes())?;
        output.flush()?;
        Ok(Keyboard)
    }

    /// Waits up to the timeout for a key and returns its text for Slint.
    pub fn read(&self, timeout: Duration) -> io::Result<Option<SharedString>> {
        if !event::poll(timeout)? {
            return Ok(None);
        }
        let Event::Key(key) = event::read()? else {
            return Ok(None);
        };
        if key.kind != KeyEventKind::Press {
            return Ok(None);
        }
        let text: SharedString = match key.code {
            KeyCode::Char(character) => character.to_string().into(),
            KeyCode::Enter => Key::Return.into(),
            KeyCode::Backspace => Key::Backspace.into(),
            KeyCode::Delete => Key::Delete.into(),
            KeyCode::Tab => Key::Tab.into(),
            KeyCode::Esc => Key::Escape.into(),
            KeyCode::Up => Key::UpArrow.into(),
            KeyCode::Down => Key::DownArrow.into(),
            KeyCode::Left => Key::LeftArrow.into(),
            KeyCode::Right => Key::RightArrow.into(),
            KeyCode::Home => Key::Home.into(),
            KeyCode::End => Key::End.into(),
            _ => return Ok(None),
        };
        Ok(Some(text))
    }
}

impl Drop for Keyboard {
    fn drop(&mut self) {
        let _ = terminal::disable_raw_mode();
    }
}

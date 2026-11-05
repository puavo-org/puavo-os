//! Runs external commands.

use std::process::Command;

use crate::error::PuavoError;

/// Runs a command and returns an error with its standard error if it fails.
pub fn run(command: &mut Command) -> Result<(), PuavoError> {
    let output = command.output().map_err(PuavoError::IoError)?;

    if output.status.success() {
        return Ok(());
    }

    Err(PuavoError::ShellError(format!(
        "{:?} failed: {}",
        command.get_program(),
        String::from_utf8_lossy(&output.stderr)
    )))
}

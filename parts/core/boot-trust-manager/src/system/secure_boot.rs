//! Writes a Secure Boot variable through the update scripts, which sign the
//! contents and write them.

use std::{path::Path, process::Command};

use log::info;

use crate::error::PuavoError;

#[cfg(not(test))]
const SCRIPT_DIRECTORY: &str = "/usr/lib/puavo-core";
#[cfg(test)]
const SCRIPT_DIRECTORY: &str =
    concat!(env!("CARGO_MANIFEST_DIR"), "/tests/scripts");

/// Replaces the contents of a variable with an update timestamped with the
/// given date and signed with the keys in the boot vault.
pub fn update(
    variable: &str,
    boot_vault_mountpoint: &Path,
    contents: &Path,
    stated_date: &str,
) -> Result<(), PuavoError> {
    let command = format!("{SCRIPT_DIRECTORY}/update-secure-boot-{variable}");
    info!("Writing {:?} to the firmware, dated {}", contents, stated_date);

    let output = Command::new(&command)
        .arg(boot_vault_mountpoint)
        .arg(contents)
        .arg(stated_date)
        .output()
        .map_err(PuavoError::IoError)?;

    if !output.status.success() {
        return Err(PuavoError::ShellError(format!(
            "{} refused: {}",
            command,
            String::from_utf8_lossy(&output.stderr)
        )));
    }

    info!("The firmware accepted the {} update", variable);
    Ok(())
}

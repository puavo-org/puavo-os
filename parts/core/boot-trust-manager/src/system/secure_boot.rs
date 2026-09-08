//! Writes a Secure Boot variable through the update scripts, which sign the
//! contents and write them.

use std::{path::Path, process::Command};

use log::info;

use crate::error::PuavoError;

/// Replaces the contents of a variable with an update timestamped with the
/// given date and signed with the keys in the boot vault.
pub fn update(
    variable: &str,
    boot_vault_mountpoint: &Path,
    contents: &Path,
    stated_date: &str,
) -> Result<(), PuavoError> {
    let command = format!("update-secure-boot-{variable}");
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

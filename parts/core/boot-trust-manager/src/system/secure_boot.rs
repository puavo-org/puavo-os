//! Runs the scripts that sign and write Secure Boot variables.

use std::{path::Path, process::Command};

use log::info;

use crate::error::PuavoError;

/// Command that writes the Secure Boot keys of a directory to the firmware.
const ENROLL_KEYS_COMMAND: &str =
    "/usr/lib/puavo-ltsp-install/puavo-setup-secure-boot";

/// Command that builds and signs the database of a directory of keys.
const UPDATE_DATABASE_COMMAND: &str =
    "/usr/lib/puavo-ltsp-install/puavo-update-device-db";

/// Runs a command and returns an error if it fails.
fn run(command: &mut Command) -> Result<(), PuavoError> {
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

    run(Command::new(&command)
        .arg(boot_vault_mountpoint)
        .arg(contents)
        .arg(stated_date))?;

    info!("The firmware accepted the {} update", variable);
    Ok(())
}

/// Builds and signs the Secure Boot database in a directory of keys, from
/// the database of the running image.
pub fn update_database(directory: &Path) -> Result<(), PuavoError> {
    info!("Building the Secure Boot database of {:?}", directory);

    run(Command::new(UPDATE_DATABASE_COMMAND).arg(directory))
}

/// Writes the Secure Boot keys in a directory to the firmware, which must be
/// in Setup Mode.
pub fn enroll_keys(directory: &Path) -> Result<(), PuavoError> {
    info!("Writing the Secure Boot keys in {:?} to the firmware", directory);

    run(Command::new(ENROLL_KEYS_COMMAND).arg(directory))
}

//! Repairs the boot vault with the recovery key through the reset mode of
//! the boot trust manager. The manager asks questions, and the answers
//! choose the repair. A forgotten PIN keeps the device keys and enrolls an
//! unlock without a PIN. A full reset writes the device keys to the
//! firmware and enrolls a reset token, which the next boot replaces.
//! Neither sets a PIN. A PIN comes from the device settings.

use std::fmt;
use std::io::Write;
use std::path::Path;
use std::process::{Command, Output, Stdio};

use log::{debug, warn};

use super::efi_partition::EfiPartition;

const BOOT_TRUST_MANAGER: &str = "puavo-boot-trust-manager";
/// The manager opens the root partition under this name, as for a boot,
/// and leaves it open.
const ROOT_MAPPING: &str = "/dev/mapper/root";
/// The manager starts the line of its error with this.
const MANAGER_ERROR_PREFIX: &str = "error: ";

/// The answers to the questions the manager asks after the key: no full
/// reconfiguration, change the PIN, an empty PIN, and remove the PIN.
const FORGOTTEN_PIN_ANSWERS: &str = "n\ny\n\ny\n";
/// A full reconfiguration, and no PIN change after it.
const FULL_RESET_ANSWERS: &str = "y\nn\n";

const IS_IN_SETUP_MODE: &str = "/usr/lib/puavo-recovery/is-in-setup-mode";
const IS_TPM_CLEARED: &str = "/usr/lib/puavo-recovery/is-tpm-cleared";
const IS_SECURE_BOOT_ENABLED: &str =
    "/usr/lib/puavo-recovery/is-secure-boot-enabled";
const CLEAR_PIN_CHANGE_REQUEST: &str =
    "/usr/lib/puavo-recovery/clear-pin-change-request";

/// The script that asks the firmware to clear the TPM at the next start.
const REQUEST_TPM_CLEAR: &str = "/usr/lib/puavo-ltsp-install/puavo-reset-tpm";
/// Where the Physical Presence Interface takes the request, when the
/// firmware has one.
const TPM_CLEAR_REQUEST: &str = "/sys/class/tpm/tpm0/ppi/request";

/// What the firmware setup has cleared of what a full reset needs cleared.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FirmwareReadiness {
    Ready,
    KeysNotCleared,
    TpmNotCleared,
    NothingCleared,
}

/// The firmware as a full reset needs it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct FirmwareState {
    pub readiness: FirmwareReadiness,
    /// Whether the firmware takes a request to clear the TPM from here.
    pub tpm_clear_requestable: bool,
}

/// Why a repair failed.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum RepairFailure {
    /// The key was not received, or is gone.
    NoKey,
    /// Secure Boot is off, and the enrollment needs it on.
    SecureBootDisabled,
    /// Why the repair failed, often in the words of the boot trust manager.
    Failed(String),
}

/// Reads whether the firmware is ready for a full reset. No key is needed.
pub fn read_firmware_state() -> Result<FirmwareState, RepairFailure> {
    let keys_cleared = run_repair_script(IS_IN_SETUP_MODE)?;
    let tpm_cleared = run_repair_script(IS_TPM_CLEARED)?;
    let readiness = match (keys_cleared, tpm_cleared) {
        (true, true) => FirmwareReadiness::Ready,
        (false, true) => FirmwareReadiness::KeysNotCleared,
        (true, false) => FirmwareReadiness::TpmNotCleared,
        (false, false) => FirmwareReadiness::NothingCleared,
    };
    let tpm_clear_requestable = Path::new(TPM_CLEAR_REQUEST).exists();
    debug!(
        "the firmware is {readiness:?}, clear requestable \
         {tpm_clear_requestable}"
    );
    Ok(FirmwareState { readiness, tpm_clear_requestable })
}

/// Asks the firmware to clear the TPM at the next start.
pub fn request_tpm_clear() -> Result<(), RepairFailure> {
    let status = Command::new(REQUEST_TPM_CLEAR)
        .status()
        .map_err(repair_step_failure("run the TPM clear request"))?;
    if !status.success() {
        return Err(repair_step_failure("request a TPM clear")(status));
    }
    debug!("requested a TPM clear at the next start");
    Ok(())
}

/// Enrolls an unlock without a PIN on the boot vault of the device the
/// recovery started from, for a forgotten PIN. Secure Boot must be on,
/// since the enrollment predicts the next boot from its state.
pub fn repair_forgotten_pin(recovery_key: &[u8]) -> Result<(), RepairFailure> {
    if !run_repair_script(IS_SECURE_BOOT_ENABLED)? {
        return Err(RepairFailure::SecureBootDisabled);
    }
    repair_vault(recovery_key, FORGOTTEN_PIN_ANSWERS)
}

/// Resets the device keys and the boot vault of the device the recovery
/// started from. The firmware must be in Setup Mode and the TPM cleared.
pub fn reset_disk_encryption(recovery_key: &[u8]) -> Result<(), RepairFailure> {
    repair_vault(recovery_key, FULL_RESET_ANSWERS)
}

fn repair_vault(
    recovery_key: &[u8],
    answers: &str,
) -> Result<(), RepairFailure> {
    // A request the device settings left would change the questions.
    if !run_repair_script(CLEAR_PIN_CHANGE_REQUEST)? {
        let reason = "failed to clear the PIN change request";
        warn!("{reason}");
        return Err(RepairFailure::Failed(reason.into()));
    }

    let partition = EfiPartition::mount()
        .map_err(repair_step_failure("mount the EFI partition"))?;
    // The boot trust manager mounts the partition again, which a read only
    // mount of the same partition would refuse.
    partition
        .make_writable()
        .map_err(repair_step_failure("make the partition writable"))?;
    let disk =
        partition.disk().map_err(repair_step_failure("find the disk"))?;

    // An earlier attempt left the root partition open, which would fail
    // this one.
    if Path::new(ROOT_MAPPING).exists() {
        let status = Command::new("cryptsetup")
            .args(["close", ROOT_MAPPING])
            .status()
            .map_err(repair_step_failure("run cryptsetup"))?;
        debug!("closing the root partition of an earlier attempt: {status}");
    }

    let output =
        run_boot_trust_manager(&disk.to_string_lossy(), recovery_key, answers)
            .map_err(repair_step_failure("run the boot trust manager"))?;
    let standard_error = String::from_utf8_lossy(&output.stderr);
    for line in standard_error.lines() {
        debug!("boot trust manager: {line}");
    }
    if output.status.success() {
        debug!("the boot trust manager repaired the vault");
        return Ok(());
    }

    let reason = last_manager_error(&standard_error).unwrap_or_else(|| {
        format!("the boot trust manager ended with {}", output.status)
    });
    warn!("the boot trust manager failed: {reason}");
    Err(RepairFailure::Failed(reason))
}

/// The last error line of the boot trust manager without its start, if it
/// wrote one.
fn last_manager_error(standard_error: &str) -> Option<String> {
    standard_error
        .lines()
        .rev()
        .find_map(|line| line.strip_prefix(MANAGER_ERROR_PREFIX))
        .map(String::from)
}

/// Runs the reset mode of the boot trust manager with the recovery key and
/// the answers on its standard input, so the key never lies in a file or
/// shows in the process list.
fn run_boot_trust_manager(
    disk: &str,
    recovery_key: &[u8],
    answers: &str,
) -> std::io::Result<Output> {
    let mut child = Command::new(BOOT_TRUST_MANAGER)
        .args(["reset", "--device", disk])
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::piped())
        .spawn()?;
    // The input fits in the pipe, so it is written before the output is
    // read.
    if let Some(mut input) = child.stdin.take() {
        input.write_all(recovery_key)?;
        input.write_all(b"\n")?;
        input.write_all(answers.as_bytes())?;
    }
    child.wait_with_output()
}

/// Whether a script of the repair succeeded. A script that does not run is
/// a failure of the repair.
fn run_repair_script(script: &str) -> Result<bool, RepairFailure> {
    let status = Command::new(script)
        .status()
        .map_err(repair_step_failure("run a script of the repair"))?;
    debug!("{script} gave {status}");
    Ok(status.success())
}

/// The failure of a step of the repair, which tells the step and its cause.
fn repair_step_failure<E: fmt::Display>(
    step: &str,
) -> impl Fn(E) -> RepairFailure + '_ {
    move |error| {
        let reason = format!("failed to {step}: {error}");
        warn!("{reason}");
        RepairFailure::Failed(reason)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_error_line_of_the_manager_is_shown_without_its_log() {
        let standard_error = "[2026-11-19T10:00:00Z ERROR boot_trust_manager] \
                              Configuration failed: Unlocking failed\n\
                              error: Unlocking failed\n";
        let reason = last_manager_error(standard_error);
        assert_eq!(reason.as_deref(), Some("Unlocking failed"));
        assert_eq!(last_manager_error("debug output only\n"), None);
    }
}

use efivar::efi::{Variable, VariableFlags, VariableVendor};
use log::{debug, warn};

/// Puavo vendor GUID for custom EFI variables
const PUAVO_VENDOR_GUID: &str = "7cb44677-9bb9-4504-bb8f-923def5fa3b1";

/// EFI variable name for requesting a PIN change from the OS
const PIN_CHANGE_REQUEST_VARIABLE: &str = "PuavoPinChangeRequest";

/// Create a Puavo-namespaced EFI variable.
fn puavo_variable(name: &str) -> Variable {
    Variable::new_with_vendor(
        name,
        VariableVendor::Custom(PUAVO_VENDOR_GUID.parse().unwrap_or_default()),
    )
}

/// Read a boolean flag from a Puavo EFI variable.
///
/// Returns `true` if the variable exists and contains a non-zero value.
fn read_bool_variable(name: &str) -> bool {
    let variable = puavo_variable(name);

    match efivar::system().read(&variable) {
        Ok((data, _)) => {
            // Treat any non-zero value as true
            let set = !data.is_empty() && data.iter().any(|&byte| byte != 0);
            debug!("EFI variable '{}': {:?} -> {}", name, data, set);
            set
        }
        Err(error) => {
            debug!("Failed to read EFI variable '{}': {}", name, error);
            false
        }
    }
}

/// Clear a Puavo EFI variable by writing a zero byte.
///
/// Deleting EFI variables directly often fails with permission errors,
/// so we write a zero byte instead to effectively clear the variable.
fn clear_variable(name: &str) {
    let variable = puavo_variable(name);
    let flags = VariableFlags::NON_VOLATILE
        | VariableFlags::BOOTSERVICE_ACCESS
        | VariableFlags::RUNTIME_ACCESS;

    if let Err(error) = efivar::system().write(&variable, flags, &[0]) {
        warn!("Failed to clear EFI variable '{}': {}", name, error);
    } else {
        debug!("Cleared EFI variable '{}'", name);
    }
}

/// Check if Secure Boot is enabled.
///
/// Returns `true` if Secure Boot is enabled, `false` otherwise or on error.
pub fn is_secure_boot_enabled() -> bool {
    let variable = Variable::new("SecureBoot");

    efivar::system()
        .read(&variable)
        .map(|(value, _)| value.ends_with(&[1]))
        .unwrap_or(false)
}

/// Check if a PIN change has been requested via EFI variable.
///
/// The OS can set this variable to request a PIN change at next boot.
pub fn is_pin_change_requested() -> bool {
    read_bool_variable(PIN_CHANGE_REQUEST_VARIABLE)
}

/// Clear the PIN change request EFI variable.
///
/// Should be called after the PIN change request has been processed.
pub fn clear_pin_change_request() {
    clear_variable(PIN_CHANGE_REQUEST_VARIABLE)
}

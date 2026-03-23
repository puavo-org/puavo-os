use efivar::efi::{Variable, VariableFlags, VariableVendor};
use log::{debug, error, warn};
use std::sync::RwLock;

/// Puavo vendor GUID for custom EFI variables
const PUAVO_VENDOR_GUID: &str = "7cb44677-9bb9-4504-bb8f-923def5fa3b1";

/// EFI variable name for requesting a PIN change from the OS
const PIN_CHANGE_REQUEST_VARIABLE: &str = "PuavoPinChangeRequest";

pub trait EfiProvider: Send + Sync {
    /// Check if Secure Boot is enabled.
    fn is_secure_boot_enabled(&self) -> bool;

    /// Check if a PIN change has been requested via EFI variable.
    fn is_pin_change_requested(&self) -> bool;

    /// Clear the PIN change request EFI variable.
    fn clear_pin_change_request(&self);

    /// Read the recovery bundle from the EFI variable.
    /// Returns `None` if the variable does not exist.
    fn read_recovery_bundle(&self) -> Option<String>;
}

/// Default EFI provider that interacts with real EFI variables.
pub struct SystemEfiProvider;

impl SystemEfiProvider {
    /// Create a Puavo-namespaced EFI variable.
    fn puavo_variable(name: &str) -> Variable {
        Variable::new_with_vendor(
            name,
            VariableVendor::Custom(
                PUAVO_VENDOR_GUID.parse().unwrap_or_default(),
            ),
        )
    }

    /// Read a boolean flag from a Puavo EFI variable.
    fn read_bool_variable(name: &str) -> bool {
        let variable = Self::puavo_variable(name);
        let Ok(manager) = efivar::system() else {
            error!("EFI variables not available");
            return false;
        };

        match manager.read(&variable) {
            Ok((data, _)) => {
                let set =
                    !data.is_empty() && data.iter().any(|&byte| byte != 0);
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
    fn clear_variable(name: &str) {
        let variable = Self::puavo_variable(name);
        let flags = VariableFlags::NON_VOLATILE
            | VariableFlags::BOOTSERVICE_ACCESS
            | VariableFlags::RUNTIME_ACCESS;

        let Ok(mut manager) = efivar::system() else {
            error!("EFI variables not available");
            return;
        };

        if let Err(error) = manager.write(&variable, flags, &[0]) {
            warn!("Failed to clear EFI variable '{}': {}", name, error);
        } else {
            debug!("Cleared EFI variable '{}'", name);
        }
    }
}

/// EFI variable name for the recovery bundle.
const RECOVERY_BUNDLE_VARIABLE: &str = "PuavoRecoveryBundle";

impl EfiProvider for SystemEfiProvider {
    fn is_secure_boot_enabled(&self) -> bool {
        let variable = Variable::new("SecureBoot");

        efivar::system()
            .ok()
            .and_then(|manager| manager.read(&variable).ok())
            .map(|(value, _)| value.ends_with(&[1]))
            .unwrap_or(false)
    }

    fn is_pin_change_requested(&self) -> bool {
        Self::read_bool_variable(PIN_CHANGE_REQUEST_VARIABLE)
    }

    fn clear_pin_change_request(&self) {
        Self::clear_variable(PIN_CHANGE_REQUEST_VARIABLE)
    }

    fn read_recovery_bundle(&self) -> Option<String> {
        let variable =
            Self::puavo_variable(RECOVERY_BUNDLE_VARIABLE);

        efivar::system()
            .ok()
            .and_then(|manager| manager.read(&variable).ok())
            .and_then(|(value, _)| String::from_utf8(value)
                .inspect_err(|error| error!("Recovery bundle is not valid UTF-8: {:?}", error))
                .ok())
    }
}

/// Global EFI provider instance.
static EFI_PROVIDER: RwLock<Option<Box<dyn EfiProvider>>> = RwLock::new(None);

/// Execute an operation with the current EFI provider.
fn with_provider<F, R>(operation: F) -> R
where
    F: FnOnce(&dyn EfiProvider) -> R,
{
    let guard = EFI_PROVIDER.read().unwrap();
    match guard.as_ref() {
        Some(provider) => operation(provider.as_ref()),
        None => operation(&SystemEfiProvider),
    }
}

/// Set a custom EFI provider
pub fn set_provider(provider: Box<dyn EfiProvider>) {
    let mut guard = EFI_PROVIDER.write().unwrap();
    *guard = Some(provider);
}

/// Reset to the default EFI provider.
pub fn reset_provider() {
    let mut guard = EFI_PROVIDER.write().unwrap();
    *guard = None;
}

/// Check if Secure Boot is enabled.
pub fn is_secure_boot_enabled() -> bool {
    with_provider(|provider| provider.is_secure_boot_enabled())
}

/// Check if a PIN change has been requested via EFI variable.
pub fn is_pin_change_requested() -> bool {
    with_provider(|provider| provider.is_pin_change_requested())
}

/// Clear the PIN change request EFI variable.
pub fn clear_pin_change_request() {
    with_provider(|provider| provider.clear_pin_change_request())
}

/// Read the recovery bundle from the EFI variable.
pub fn read_recovery_bundle() -> Option<String> {
    with_provider(|provider| provider.read_recovery_bundle())
}

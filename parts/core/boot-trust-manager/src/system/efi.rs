use efivar::efi::{Variable, VariableFlags, VariableVendor};
use log::{debug, error, warn};
use std::sync::RwLock;
use uuid::Uuid;

use crate::error::PuavoError;

/// Puavo vendor GUID for EFI variables and signature owners.
pub const PUAVO_VENDOR: Uuid =
    Uuid::from_u128(0x7cb44677_9bb9_4504_bb8f_923def5fa3b1);

/// EFI variable name for requesting a PIN change from the OS
const PIN_CHANGE_REQUEST_VARIABLE: &str = "PuavoPinChangeRequest";

/// EFI variable name for controlling whether the device is allowed to perform
/// Secure Boot database updates.
const SECURE_BOOT_UPDATE_VARIABLE: &str = "PuavoSecureBootUpdate";

/// EFI variable name for the recovery bundle.
const RECOVERY_BUNDLE_VARIABLE: &str = "PuavoRecoveryBundle";

/// Reads a UEFI variable of any vendor. An unset variable reads as empty.
pub fn read_variable(vendor: Uuid, name: &str) -> Result<Vec<u8>, PuavoError> {
    let variable =
        Variable::new_with_vendor(name, VariableVendor::Custom(vendor));

    let manager = efivar::system().map_err(|error| {
        PuavoError::NotFound(format!(
            "UEFI variables are not available: {error}"
        ))
    })?;

    match manager.read(&variable) {
        Ok((contents, _)) => Ok(contents),
        Err(efivar::Error::VarNotFound { .. }) => {
            debug!("UEFI variable '{}' is not set, so it is empty", name);
            Ok(Vec::new())
        }
        Err(error) => Err(PuavoError::NotFound(format!(
            "UEFI variable '{name}' could not be read: {error}"
        ))),
    }
}

pub trait EfiProvider: Send + Sync {
    /// Check if Secure Boot is enabled.
    fn is_secure_boot_enabled(&self) -> bool;

    /// Check if a PIN change has been requested via EFI variable.
    fn is_pin_change_requested(&self) -> bool;

    /// Whether this device is permitted to enroll a Secure Boot database.
    fn is_secure_boot_update_allowed(&self) -> bool;

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
        Variable::new_with_vendor(name, VariableVendor::Custom(PUAVO_VENDOR))
    }

    /// Read a boolean flag from a Puavo EFI variable.
    fn read_bool_variable(name: &str) -> bool {
        match read_variable(PUAVO_VENDOR, name) {
            Ok(bytes) => {
                let set =
                    !bytes.is_empty() && bytes.iter().any(|&byte| byte != 0);
                debug!("EFI variable '{}': {:?} -> {}", name, bytes, set);
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

    fn is_secure_boot_update_allowed(&self) -> bool {
        Self::read_bool_variable(SECURE_BOOT_UPDATE_VARIABLE)
    }

    fn clear_pin_change_request(&self) {
        Self::clear_variable(PIN_CHANGE_REQUEST_VARIABLE)
    }

    fn read_recovery_bundle(&self) -> Option<String> {
        let variable = Self::puavo_variable(RECOVERY_BUNDLE_VARIABLE);

        efivar::system()
            .ok()
            .and_then(|manager| manager.read(&variable).ok())
            .and_then(|(value, _)| {
                String::from_utf8(value)
                    .inspect_err(|error| {
                        error!(
                            "Recovery bundle is not valid UTF-8: {:?}",
                            error
                        )
                    })
                    .ok()
            })
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

/// Check if Secure Boot updates are permitted on this device.
pub fn is_secure_boot_update_allowed() -> bool {
    with_provider(|provider| provider.is_secure_boot_update_allowed())
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

#[cfg(test)]
pub mod testing {
    use super::*;
    use std::sync::atomic::AtomicBool;

    /// Configurable EFI provider shared by the library unit tests.
    pub struct FakeEfiProvider {
        pub secure_boot_enabled: bool,
        pub pin_change_requested: bool,
        pub secure_boot_update_allowed: bool,
        pub sbat_raise_requested: AtomicBool,
        pub recovery_bundle: Option<String>,
    }

    impl Default for FakeEfiProvider {
        fn default() -> Self {
            Self {
                secure_boot_enabled: false,
                pin_change_requested: false,
                secure_boot_update_allowed: false,
                sbat_raise_requested: AtomicBool::new(false),
                recovery_bundle: None,
            }
        }
    }

    impl EfiProvider for FakeEfiProvider {
        fn is_secure_boot_enabled(&self) -> bool {
            self.secure_boot_enabled
        }

        fn is_pin_change_requested(&self) -> bool {
            self.pin_change_requested
        }

        fn is_secure_boot_update_allowed(&self) -> bool {
            self.secure_boot_update_allowed
        }

        fn clear_pin_change_request(&self) {}

        fn read_recovery_bundle(&self) -> Option<String> {
            self.recovery_bundle.clone()
        }
    }
}

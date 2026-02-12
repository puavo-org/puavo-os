use log::{debug, info, warn};

use crate::{
    configurators::Configurator,
    devices::boot_vault::{BootVault, BootVaultUnlockMethod},
    display::UserDisplay,
    error::PuavoError,
    utils::{efi, luks_tpm_token_manager::LuksTpmTokenManager},
};

/// Reason for PIN configurator activation
#[derive(Debug, Clone, PartialEq, Eq)]
enum PinChangeReason {
    /// User unlocked with recovery key, may have forgotten PIN
    RecoveryKeyUnlock,
    /// Explicit request via EFI variable from the OS
    EfiVariableRequest,
}

/// Configurator that handles PIN change and reset operations
pub struct PinConfigurator {
    activation_reason: Option<PinChangeReason>,
}

impl PinConfigurator {
    /// Create new PIN configurator instances
    pub fn new() -> Result<Vec<Self>, PuavoError> {
        Ok(vec![Self { activation_reason: None }])
    }

    /// Prompt the user for a new PIN with confirmation.
    ///
    /// Parameters:
    /// - `display`: Display instance for user interaction.
    ///
    /// Returns:
    /// - `Ok(Some(Some(pin)))` if the user successfully set a new PIN.
    /// - `Ok(Some(None))` if the user chose to remove the PIN.
    /// - `Ok(None)` if the user cancelled the operation.
    /// - `Err(error)` if an I/O error occurred.
    fn prompt_for_new_pin(
        &self,
        display: &Box<dyn UserDisplay>,
    ) -> Result<Option<Option<String>>, PuavoError> {
        loop {
            // Ask for confirmation before each attempt (provides exit opportunity)
            let _ = display.clear();
            if !display.ask_yes_no("Change PIN?")? {
                info!("User cancelled PIN change");
                return Ok(None);
            }

            let _ = display.clear();

            // Get new PIN
            let new_pin =
                display.ask_password("Enter new PIN (empty to remove)")?;

            // Handle PIN removal (empty PIN)
            if new_pin.is_empty() {
                if display.ask_yes_no("Remove PIN protection?")? {
                    info!("User confirmed PIN removal");
                    return Ok(Some(None));
                }
                continue;
            }

            // Confirm new PIN
            let confirmed_pin = display.ask_password("Confirm new PIN")?;

            // Check if PINs match
            if new_pin != confirmed_pin {
                let _ = display.show_message("PINs do not match");
                continue;
            }

            info!("New PIN confirmed successfully");
            return Ok(Some(Some(new_pin)));
        }
    }
}

impl Configurator for PinConfigurator {
    fn activate(
        &self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        // Check for explicit PIN change request via EFI variable
        if efi::is_pin_change_requested() {
            info!("PIN change requested via EFI variable");
            return Ok(true);
        }

        // Check if device was unlocked with recovery key
        if matches!(
            boot_vault.unlock_method(),
            Some(BootVaultUnlockMethod::RecoveryKey)
        ) {
            info!(
                "Boot vault was unlocked with recovery key, PIN change may be needed"
            );
            return Ok(true);
        }

        debug!("No PIN change needed");
        Ok(false)
    }

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
        display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        // Determine the reason for activation
        let reason = if efi::is_pin_change_requested() {
            PinChangeReason::EfiVariableRequest
        } else if matches!(
            boot_vault.unlock_method(),
            Some(BootVaultUnlockMethod::RecoveryKey)
        ) {
            PinChangeReason::RecoveryKeyUnlock
        } else {
            warn!("PIN configurator activated without valid reason");
            return Ok(());
        };

        self.activation_reason = Some(reason.clone());
        info!("PIN change reason: {:?}", reason);

        // Clear EFI variable if that was the trigger
        if reason == PinChangeReason::EfiVariableRequest {
            efi::clear_pin_change_request();
        }

        // Prompt for new PIN
        let new_pin =
            match self.prompt_for_new_pin(display).map_err(|error| {
                PuavoError::PinConfigurationError(error.to_string())
            })? {
                Some(pin) => pin,
                None => {
                    // User cancelled
                    return Ok(());
                }
            };

        // Update the PIN state of boot vault
        boot_vault.set_pin(new_pin);

        // Signal that TPM enrollment is required.
        // This avoids testing tokens, which could cause TPM lockout issues.
        boot_vault.set_enrollment_required(true);

        info!("PIN change staged, enrollment required");
        Ok(())
    }

    fn name(&self) -> &'static str {
        "PIN"
    }
}

use log::{debug, info, warn};
use zeroize::Zeroizing;

use crate::{
    configurators::Configurator,
    devices::boot_vault::{BootVault, BootVaultUnlockMethod},
    display::UserDisplay,
    error::PuavoError,
    utils::{efi, locale, luks_tpm_token_manager::LuksTpmTokenManager},
};

/// Reason for PIN configurator activation
#[derive(Debug, Clone, PartialEq, Eq)]
enum PinChangeReason {
    /// User unlocked with recovery key, may have forgotten PIN
    RecoveryKeyUnlock,
    /// Explicit request via EFI variable from the OS
    EfiVariableRequest,
}

/// Outcome of prompting the user for a new PIN.
enum PinPromptOutcome {
    /// User entered and confirmed a new PIN.
    NewPin(Zeroizing<String>),
    /// User chose to remove the PIN protection.
    Remove,
    /// User cancelled the operation.
    Cancelled,
}

/// Minimum number of characters required for a PIN.
const MIN_PIN_LENGTH: usize = 4;

/// Result of validating a PIN.
enum PinValidation {
    Ok,
    TooShort,
    InvalidCharacters,
}

/// Validate a candidate PIN against the fixed boot keyboard layout.
fn validate_pin(pin: &str) -> PinValidation {
    if pin.chars().count() < MIN_PIN_LENGTH {
        return PinValidation::TooShort;
    }

    if !pin.chars().all(|character| character.is_ascii_alphanumeric()) {
        return PinValidation::InvalidCharacters;
    }

    PinValidation::Ok
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
    /// Errors:
    /// Returns `PuavoError` if reading from the display fails.
    fn prompt_for_new_pin(
        &self,
        display: &dyn UserDisplay,
    ) -> Result<PinPromptOutcome, PuavoError> {
        let strings = locale::strings();
        loop {
            // Ask for confirmation before each attempt (provides exit opportunity)
            let _ = display.clear();
            if !display.ask_yes_no(strings.change_pin_question)? {
                info!("User cancelled PIN change");
                return Ok(PinPromptOutcome::Cancelled);
            }

            let _ = display.clear();

            // Get new PIN
            let new_pin = display.ask_password(strings.enter_new_pin)?;

            // Handle PIN removal (empty PIN)
            if new_pin.is_empty() {
                if display.ask_yes_no(strings.remove_pin_question)? {
                    info!("User confirmed PIN removal");
                    return Ok(PinPromptOutcome::Remove);
                }
                continue;
            }

            // Validate the PIN
            let rejection = match validate_pin(new_pin.as_str()) {
                PinValidation::Ok => None,
                PinValidation::TooShort => Some(strings.pin_too_short),
                PinValidation::InvalidCharacters => {
                    Some(strings.pin_invalid_characters)
                }
            };
            if let Some(message) = rejection {
                let _ = display.show_message(message);
                continue;
            }

            // Confirm new PIN
            let confirmed_pin =
                display.ask_password(strings.confirm_new_pin)?;

            // Check if PINs match
            if new_pin.as_str() != confirmed_pin.as_str() {
                let _ = display.show_message(strings.pins_do_not_match);
                continue;
            }

            info!("New PIN confirmed successfully");
            return Ok(PinPromptOutcome::NewPin(new_pin));
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
        display: &dyn UserDisplay,
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
                PinPromptOutcome::NewPin(pin) => Some(pin),
                PinPromptOutcome::Remove => None,
                PinPromptOutcome::Cancelled => return Ok(()),
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

#[cfg(test)]
mod tests {
    use super::{MIN_PIN_LENGTH, PinValidation, validate_pin};

    #[test]
    fn accepts_ascii_alphanumeric_pin() {
        assert!(matches!(validate_pin("abc123"), PinValidation::Ok));
        assert!(matches!(validate_pin("Secret1"), PinValidation::Ok));
    }

    #[test]
    fn minimum_length_is_accepted() {
        let pin = "a".repeat(MIN_PIN_LENGTH);
        assert!(matches!(validate_pin(&pin), PinValidation::Ok));
    }

    #[test]
    fn rejects_short_pin() {
        assert!(matches!(validate_pin("a1b"), PinValidation::TooShort));
        assert!(matches!(validate_pin(""), PinValidation::TooShort));
    }

    #[test]
    fn rejects_non_alphanumeric_pin() {
        assert!(matches!(
            validate_pin("pass word"),
            PinValidation::InvalidCharacters
        ));
        assert!(matches!(
            validate_pin("pin-code"),
            PinValidation::InvalidCharacters
        ));
    }

    #[test]
    fn rejects_national_characters() {
        assert!(matches!(
            validate_pin("pässwörd"),
            PinValidation::InvalidCharacters
        ));
    }
}

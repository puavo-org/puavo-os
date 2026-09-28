use log::{debug, info, warn};
use zeroize::Zeroizing;

use crate::{
    configurators::{Configurator, enrollment},
    devices::boot_vault::{BootVault, BootVaultUnlockMethod},
    display::UserDisplay,
    error::PuavoError,
    luks::tokens::LuksTpmTokenManager,
    system::{efi, locale, reboot, secure_boot},
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

/// What the user decided about a full reconfiguration.
enum Reconfiguration {
    /// Go ahead, the firmware is in Setup Mode.
    Proceed,
    /// Change nothing.
    Declined,
    /// Restart, so the Secure Boot keys can be cleared in the firmware setup.
    RebootForSetupMode,
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

    /// Asks whether to do a full reconfiguration. When the firmware is not
    /// in Setup Mode, also asks whether to restart.
    fn ask_reconfiguration(
        display: &dyn UserDisplay,
    ) -> Result<Reconfiguration, PuavoError> {
        let strings = locale::strings();

        let _ = display.clear();
        if !display.ask_yes_no(strings.reconfiguration_question)? {
            info!("User declined the reconfiguration");
            return Ok(Reconfiguration::Declined);
        }

        // The Secure Boot keys can only be written in Setup Mode.
        if efi::is_in_setup_mode() {
            return Ok(Reconfiguration::Proceed);
        }

        if display.ask_yes_no(strings.setup_mode_reboot_question)? {
            return Ok(Reconfiguration::RebootForSetupMode);
        }

        Ok(Reconfiguration::Declined)
    }

    /// Writes the Secure Boot keys of this device to the firmware and adds a
    /// temporary enrollment for the next boot. Requests a restart.
    fn reconfigure(boot_vault: &BootVault) -> Result<(), PuavoError> {
        let mountpoint = boot_vault.resources().mountpoint();

        secure_boot::update_database(mountpoint)?;
        secure_boot::enroll_keys(mountpoint)?;
        enrollment::add_reset_enrollment()?;

        // Writing the platform key turns Secure Boot on. The firmware
        // measures the new state only after a restart.
        reboot::request();

        info!("Secure Boot keys of this device written");
        Ok(())
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

        // After a recovery key unlock, offer a full reconfiguration first.
        // The PIN is asked in any case, since the disk is enrolled again.
        let reconfigured = match reason {
            PinChangeReason::EfiVariableRequest => false,
            PinChangeReason::RecoveryKeyUnlock => {
                match Self::ask_reconfiguration(display)? {
                    Reconfiguration::RebootForSetupMode => {
                        info!("Restarting so the keys can be cleared");
                        reboot::request();
                        return Ok(());
                    }
                    Reconfiguration::Declined => false,
                    Reconfiguration::Proceed => {
                        Self::reconfigure(boot_vault).map_err(|error| {
                            PuavoError::PinConfigurationError(error.to_string())
                        })?;
                        true
                    }
                }
            }
        };

        match self.prompt_for_new_pin(display).map_err(|error| {
            PuavoError::PinConfigurationError(error.to_string())
        })? {
            PinPromptOutcome::NewPin(pin) => boot_vault.set_pin(Some(pin)),
            PinPromptOutcome::Remove => boot_vault.set_pin(None),
            // After a reconfiguration the disk must be enrolled again, so
            // cancelling here means no PIN rather than no change.
            PinPromptOutcome::Cancelled if reconfigured => {
                boot_vault.set_pin(None)
            }
            PinPromptOutcome::Cancelled => return Ok(()),
        }

        // Signal that TPM enrollment is required.
        // This avoids testing tokens, which could cause TPM lockout issues.
        boot_vault.set_enrollment_required(true);

        info!("PIN change pending, enrollment required");
        Ok(())
    }

    fn name(&self) -> &'static str {
        "PIN"
    }
}

#[cfg(test)]
mod tests {
    use std::{cell::RefCell, collections::VecDeque};

    use serial_test::serial;

    use super::{
        MIN_PIN_LENGTH, PinConfigurator, PinValidation, Reconfiguration,
        validate_pin,
    };
    use crate::{
        display::UserDisplay,
        error::PuavoError,
        system::efi::{self, testing::FakeEfiProvider},
    };
    use zeroize::Zeroizing;

    /// A display that answers the yes/no questions from a script.
    struct ScriptedDisplay {
        answers: RefCell<VecDeque<bool>>,
    }

    impl ScriptedDisplay {
        fn new(answers: &[bool]) -> Self {
            Self { answers: RefCell::new(answers.iter().copied().collect()) }
        }
    }

    impl UserDisplay for ScriptedDisplay {
        fn ask_password(
            &self,
            _prompt: &str,
        ) -> Result<Zeroizing<String>, PuavoError> {
            unreachable!("these tests only answer questions")
        }

        fn ask_yes_no(&self, _prompt: &str) -> Result<bool, PuavoError> {
            Ok(self
                .answers
                .borrow_mut()
                .pop_front()
                .expect("more questions than the script answers"))
        }

        fn show_message(&self, _text: &str) -> Result<(), PuavoError> {
            Ok(())
        }

        fn clear(&self) -> Result<(), PuavoError> {
            Ok(())
        }
    }

    /// Sets whether the fake firmware is in Setup Mode.
    fn firmware(setup_mode: bool) {
        efi::set_provider(Box::new(FakeEfiProvider {
            setup_mode,
            ..Default::default()
        }));
    }

    /// Returns the decision for the specified answers.
    fn decide(setup_mode: bool, answers: &[bool]) -> Reconfiguration {
        firmware(setup_mode);
        let decision = PinConfigurator::ask_reconfiguration(
            &ScriptedDisplay::new(answers),
        )
        .unwrap();
        efi::reset_provider();

        decision
    }

    #[test]
    #[serial]
    fn reconfiguration_in_setup_mode_goes_ahead() {
        assert!(matches!(decide(true, &[true]), Reconfiguration::Proceed));
    }

    #[test]
    #[serial]
    fn declined_reconfiguration_changes_nothing() {
        assert!(matches!(decide(true, &[false]), Reconfiguration::Declined));
    }

    #[test]
    #[serial]
    fn reconfiguration_outside_setup_mode_offers_a_restart() {
        assert!(matches!(
            decide(false, &[true, true]),
            Reconfiguration::RebootForSetupMode
        ));
    }

    #[test]
    #[serial]
    fn declined_restart_changes_nothing() {
        assert!(matches!(
            decide(false, &[true, false]),
            Reconfiguration::Declined
        ));
    }

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

use crate::configurators::command_line_signer::CommandLineSignerConfigurator;
use crate::configurators::device_secure_boot_keys::DeviceSecureBootKeysConfigurator;
use crate::configurators::enrollment::EnrollmentConfigurator;
use crate::configurators::pin::PinConfigurator;
use crate::configurators::secure_boot_update::{
    ApplySecureBootUpdateConfigurator, PrepareSecureBootUpdateConfigurator,
    SecureBootUpdateContext,
};
use crate::devices::boot_vault::BootVault;
use crate::display::UserDisplay;
use crate::error::PuavoError;
use crate::luks::tokens::LuksTpmTokenManager;

pub mod command_line_signer;
pub mod device_secure_boot_keys;
pub mod enrollment;
pub mod pin;
pub mod secure_boot_update;

/// Build and return all available configurator instances.
/// Configurator becomes available when its configuration file is present.
///
/// Returns:
/// - `Ok(configurators)` containing configurators that are present and loaded.
/// - `Err(error)` if any configurator failed to load due to internal errors.
pub fn configurators() -> Result<Vec<Box<dyn Configurator>>, PuavoError> {
    fn configurators<'a, T: Configurator + 'a>(
        configurators: Vec<T>,
    ) -> impl Iterator<Item = Box<dyn Configurator + 'a>> {
        configurators
            .into_iter()
            .map(|configurator| Box::new(configurator) as Box<dyn Configurator>)
    }

    // Shared between the configurator that prepares an update and the one
    // that applies it.
    let secure_boot_update = SecureBootUpdateContext::default();

    // The device keys are installed first, because an enrollment policy
    // references the device certificate.
    let configurators = configurators(DeviceSecureBootKeysConfigurator::new()?)
        .chain(configurators(PinConfigurator::new()?))
        // A database update is prepared before the enrollments and written
        // to the firmware after them, so a token for the resulting state
        // exists before the firmware enters it.
        .chain(configurators(PrepareSecureBootUpdateConfigurator::new(
            secure_boot_update.clone(),
        )?))
        .chain(configurators(EnrollmentConfigurator::new()?))
        .chain(configurators(ApplySecureBootUpdateConfigurator::new(
            secure_boot_update,
        )))
        .chain(configurators(CommandLineSignerConfigurator::new()?));

    Ok(configurators.collect())
}

/// Trait implemented by all runtime configurators executed by the
/// boot trust manager.
///
/// A configurator is responsible for a self-contained maintenance or
/// provisioning action (e.g. enrolling TPM policies).
/// Configurators are activated when their configuration file is present
/// in the filesystem. The configurators can be dynamically activated by
/// inserting the configuration with a small (signed) trigger file in the
/// EFI partition.
pub trait Configurator {
    /// Determine whether this configurator should run.
    ///
    /// Parameters:
    /// - `boot_vault`: Mounted boot vault.
    /// - `primary_partition`: Manager for the primary encrypted partition.
    ///
    /// Returns:
    /// - `Ok(true)` if the configurator should execute.
    /// - `Ok(false)` to skip execution.
    /// - `Err(error)` if prerequisite checks failed.
    fn activate(
        &self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError>;

    /// Execute the configurator's main logic.
    ///
    /// Parameters:
    /// - `boot_vault`: Mounted boot vault.
    /// - `primary_partition`: Primary partition manager with modification access.
    /// - `display`: Display instance to show progress and messages.
    ///
    /// Errors:
    /// Returns `PuavoError` in case of any internal failure.
    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
        display: &dyn UserDisplay,
    ) -> Result<(), PuavoError>;

    /// Return a friendly name for this configurator.
    fn name(&self) -> &'static str;
}

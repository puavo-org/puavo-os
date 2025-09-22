use crate::configurators::enrollment::EnrollmentConfigurator;
use crate::configurators::recovery::RecoveryConfigurator;
use crate::devices::boot_vault::BootVault;
use crate::display::UserDisplay;
use crate::error::PuavoError;
use crate::utils::luks_tpm_token_manager::LuksTpmTokenManager;

pub mod enrollment;
pub mod recovery;

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

    let configurators = configurators(EnrollmentConfigurator::new()?)
        .chain(configurators(RecoveryConfigurator::new()?));

    Ok(configurators.collect())
}

/// Trait implemented by all runtime configurators executed by the
/// boot trust manager.
///
/// A configurator is responsible for a self‑contained maintenance or
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
        display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError>;

    /// Return a friendly name for this configurator.
    fn name(&self) -> &'static str;

    /// Return the optional filename of the trigger file corresponding
    /// to this configurator. If the filename is returned, it is expected
    /// to be present in the loader extra directory. The trigger file
    /// is removed before configuration.
    fn trigger_filename(&self) -> Option<String> {
        None
    }
}

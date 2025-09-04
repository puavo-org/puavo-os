use crate::configurators::enrollment::EnrollmentConfigurator;
use crate::configurators::recovery::RecoveryConfigurator;
use crate::devices::boot_vault::BootVault;
use crate::error::PuavoError;
use crate::{
    utils::luks_tpm_token_manager::LuksTpmTokenManager,
};

pub mod enrollment;
pub mod recovery;

pub fn configurators() -> Result<Vec<Box<dyn Configurator>>, PuavoError> {
    fn configurator<'a, T: Configurator + 'a>(
        configurator: Option<T>,
    ) -> Option<Box<dyn Configurator + 'a>> {
        configurator.map(|value| Box::new(value) as Box<dyn Configurator>)
    }

    let configurators = vec![
        configurator(EnrollmentConfigurator::new()?),
        configurator(RecoveryConfigurator::new()?),
    ];

    Ok(configurators.into_iter().filter_map(|value| value).collect())
}

pub trait Configurator {
    fn allowed(
        &self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError>;
    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<(), PuavoError>;
}

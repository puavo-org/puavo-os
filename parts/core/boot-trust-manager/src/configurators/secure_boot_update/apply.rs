//! Applies a prepared Secure Boot database update.

use log::{info, warn};

use crate::{
    configurators::{
        Configurator, enrollment::EnrollmentConfigurator,
        secure_boot_update::SecureBootUpdateContext,
    },
    devices::boot_vault::{BootVault, BootVaultResources},
    display::UserDisplay,
    error::PuavoError,
    luks::tokens::LuksTpmTokenManager,
    secure_boot::update::PreparedSecureBootUpdate,
    system::{locale, reboot, secure_boot},
};

/// Writes a prepared Secure Boot database update to the firmware. Runs after
/// the enrollments, so a token for the resulting state exists.
pub struct ApplySecureBootUpdateConfigurator {
    context: SecureBootUpdateContext,
}

impl ApplySecureBootUpdateConfigurator {
    /// Creates the configurator for the update in the shared context.
    pub fn new(context: SecureBootUpdateContext) -> Vec<Self> {
        vec![Self { context }]
    }

    /// Returns the prepared update when an enrollment for its resulting state
    /// was applied, otherwise None. Without such an enrollment the next boot
    /// would require the recovery key.
    fn ready_to_apply(
        &self,
        resources: &BootVaultResources,
    ) -> Result<Option<PreparedSecureBootUpdate>, PuavoError> {
        let Some(prepared) = self.context.prepared() else {
            return Ok(None);
        };

        // The enrollment state records the applied names, and an enrollment
        // for this update has a name derived from it.
        let ending = prepared.update.enrollment_ending();
        let applied = EnrollmentConfigurator::applied_names(resources)?;

        if !applied.iter().any(|name| name.ends_with(&ending)) {
            warn!(
                "Skipping Secure Boot update for {}, because no matching enrollment could be found",
                prepared.update.variable().name()
            );
            return Ok(None);
        }

        Ok(Some(prepared))
    }

    /// Writes the update to the firmware and records the enrolled database.
    /// Returns whether anything was written.
    fn apply(
        &self,
        resources: &BootVaultResources,
    ) -> Result<bool, PuavoError> {
        let Some(prepared) = self.ready_to_apply(resources)? else {
            return Ok(false);
        };
        let update = &prepared.update;
        let name = update.variable().name();

        // The firmware requires a timestamp later than the stored one, so
        // the update carries the build date.
        secure_boot::update(
            name,
            resources.mountpoint(),
            &prepared.pending,
            &update.date().to_string(),
        )?;

        // Recorded so the same database is not enrolled again on the next
        // boot.
        resources.set_enrolled_database(name, &update.enrolled())?;

        Ok(true)
    }
}

impl Configurator for ApplySecureBootUpdateConfigurator {
    fn activate(
        &self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        Ok(self.ready_to_apply(boot_vault.resources())?.is_some())
    }

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
        display: &dyn UserDisplay,
    ) -> Result<(), PuavoError> {
        let _ =
            display.show_message(locale::strings().applying_secure_boot_update);

        if !self.apply(&boot_vault.resources().clone())? {
            return Ok(());
        }

        // The firmware measures the variables at boot, so the PCR reflects
        // the new state only after a reboot.
        info!("A Secure Boot database was enrolled, so the machine restarts");
        reboot::request();
        Ok(())
    }

    fn name(&self) -> &'static str {
        "Secure Boot update"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::configurators::{
        enrollment::testing::write_applied_names,
        secure_boot_update::testing::{
            shipped, shipped_database, stub_update_command, use_test_scripts,
            vault,
        },
    };
    use crate::secure_boot::update::{SecureBootDatabaseUpdate, Variable};
    use std::{fs, path::Path};
    use tempfile::TempDir;

    /// The name of the enrollment generated for this update.
    fn enrollment_for(update: &SecureBootDatabaseUpdate) -> String {
        update.enrollment_name("primary")
    }

    /// An applier whose context holds the update, with the pending contents
    /// written.
    fn applier(
        update: &SecureBootDatabaseUpdate,
        resources: &BootVaultResources,
        runtime: &Path,
    ) -> ApplySecureBootUpdateConfigurator {
        let context = SecureBootUpdateContext::default();
        let pending = update
            .write_pending(
                &resources.secure_boot_certificate_path(),
                &runtime.join("pending"),
            )
            .unwrap();

        context.set_prepared(PreparedSecureBootUpdate {
            update: update.clone(),
            pending,
        });

        ApplySecureBootUpdateConfigurator { context }
    }

    #[test]
    fn update_not_applied_before_enrollments() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let (_vault, resources) = vault();
        let applier = applier(
            &shipped(image.path(), Variable::Db),
            &resources,
            runtime.path(),
        );

        assert!(applier.ready_to_apply(&resources).unwrap().is_none());
    }

    #[test]
    fn update_applied_once_enrolled_for() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let (_vault, resources) = vault();
        let update = shipped(image.path(), Variable::Db);
        let applier = applier(&update, &resources, runtime.path());

        write_applied_names(&resources, &[enrollment_for(&update)]).unwrap();

        assert!(applier.ready_to_apply(&resources).unwrap().is_some());
    }

    #[test]
    fn enrollment_for_another_update_does_not_apply() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let (_vault, resources) = vault();
        let applier = applier(
            &shipped(image.path(), Variable::Db),
            &resources,
            runtime.path(),
        );

        let another = TempDir::new().unwrap();
        fs::write(another.path().join("db.esl"), b"another database").unwrap();
        fs::write(another.path().join("built"), b"20250101000000").unwrap();

        write_applied_names(
            &resources,
            &[enrollment_for(&shipped(another.path(), Variable::Db))],
        )
        .unwrap();

        assert!(applier.ready_to_apply(&resources).unwrap().is_none());
    }

    #[test]
    fn nothing_prepared_is_nothing_to_apply() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let (_vault, resources) = vault();
        let applier = ApplySecureBootUpdateConfigurator {
            context: SecureBootUpdateContext::default(),
        };

        write_applied_names(
            &resources,
            &[enrollment_for(&shipped(image.path(), Variable::Db))],
        )
        .unwrap();

        assert!(applier.ready_to_apply(&resources).unwrap().is_none());
    }

    #[test]
    #[serial_test::serial]
    fn applying_writes_contents_and_records_them() {
        use_test_scripts();
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let record = stub_update_command(runtime.path());
        let (_vault, resources) = vault();
        let update = shipped(image.path(), Variable::Db);
        let applier = applier(&update, &resources, runtime.path());

        write_applied_names(&resources, &[enrollment_for(&update)]).unwrap();

        assert!(applier.apply(&resources).unwrap());

        let asked = fs::read_to_string(record).unwrap();
        assert!(asked.contains("dated 2026-01-01 00:00:00"), "{asked}");

        let recorded = resources.enrolled_database("db").unwrap().unwrap();
        assert_eq!(recorded, update.enrolled());
    }

    #[test]
    #[serial_test::serial]
    fn update_nothing_enrolled_for_not_written() {
        use_test_scripts();
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let record = stub_update_command(runtime.path());
        let (_vault, resources) = vault();
        let applier = applier(
            &shipped(image.path(), Variable::Db),
            &resources,
            runtime.path(),
        );

        assert!(!applier.apply(&resources).unwrap());

        assert!(!record.exists(), "the firmware was given something");
        assert_eq!(resources.enrolled_database("db").unwrap(), None);
    }
}

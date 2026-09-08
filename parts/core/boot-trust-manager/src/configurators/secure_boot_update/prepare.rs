//! Prepares a Secure Boot database update. Preparation decides whether the
//! device has a database to enroll, takes the updates one variable per boot
//! and writes an enrollment whose chain predicts the PCR state after the
//! update.

use std::{
    fs,
    path::{Path, PathBuf},
};

use log::{debug, info, warn};

use crate::{
    configurators::{
        Configurator,
        enrollment::{
            EnrollmentConfigurator, EnrollmentItemConfiguration,
            GENERATED_CONFIGURATION_DIRECTORY,
        },
        secure_boot_update::{DATABASE_DIRECTORY, SecureBootUpdateContext},
    },
    devices::boot_vault::{
        BootVault, BootVaultResources, BootVaultUnlockMethod,
    },
    display::UserDisplay,
    error::PuavoError,
    luks::tokens::LuksTpmTokenManager,
    secure_boot::update::{
        PENDING_DIRECTORY, PreparedSecureBootUpdate, SecureBootDatabaseUpdate,
    },
    system::{efi, locale},
};

/// Prepares one Secure Boot database update. It writes the pending contents
/// of the variable and an enrollment for the resulting state, and does not
/// write to the firmware. One variable is updated per boot, so every state
/// the machine passes through has an enrollment.
pub struct PrepareSecureBootUpdateConfigurator {
    updates: Vec<SecureBootDatabaseUpdate>,
    shipped: Vec<EnrollmentItemConfiguration>,
    context: SecureBootUpdateContext,
    pending_directory: PathBuf,
    generated_enrollment_directory: PathBuf,
}

impl PrepareSecureBootUpdateConfigurator {
    /// Reads the databases installed in the image. Returns no configurator
    /// when there are none. The prepared update is stored in the shared
    /// context for the applying configurator.
    pub fn new(
        context: SecureBootUpdateContext,
    ) -> Result<Vec<Self>, PuavoError> {
        let updates =
            SecureBootDatabaseUpdate::read_all(Path::new(DATABASE_DIRECTORY))?;

        if updates.is_empty() {
            debug!("This image carries no Secure Boot database");
            return Ok(Vec::new());
        }

        Ok(vec![Self {
            updates,
            shipped: EnrollmentConfigurator::read_shipped_configurations()?,
            context,
            pending_directory: PathBuf::from(PENDING_DIRECTORY),
            generated_enrollment_directory: PathBuf::from(
                GENERATED_CONFIGURATION_DIRECTORY,
            ),
        }])
    }

    /// Writes an enrollment for the state after this update, for each
    /// installed enrollment that measures the updated variable.
    fn write_enrollments(
        &self,
        update: &SecureBootDatabaseUpdate,
        pending: &Path,
    ) -> Result<usize, PuavoError> {
        let mut written = 0;

        fs::create_dir_all(&self.generated_enrollment_directory)?;

        for item in &self.shipped {
            let Some(policy) = update.policy_after(&item.policy, pending)
            else {
                debug!(
                    "{} does not measure {}, so no enrollment is written for it",
                    item.name,
                    update.variable().name()
                );
                continue;
            };

            let extra = EnrollmentItemConfiguration {
                name: update.enrollment_name(&item.name),
                version: item.version,
                policy,
            };

            let path = self
                .generated_enrollment_directory
                .join(format!("{}.json", item.name));
            fs::write(
                &path,
                serde_json::to_string_pretty(&extra)
                    .map_err(PuavoError::EnrollmentStateError)?,
            )?;

            info!("Wrote {path:?} for the state after the update");
            written += 1;
        }

        Ok(written)
    }

    /// The update to apply in this boot, which is the first variable whose
    /// database the device has not enrolled.
    fn next_update(
        &self,
        resources: &BootVaultResources,
    ) -> Result<Option<&SecureBootDatabaseUpdate>, PuavoError> {
        for update in &self.updates {
            let enrolled =
                resources.enrolled_database(update.variable().name())?;

            if update.should_enroll(enrolled.as_ref()) {
                return Ok(Some(update));
            }
        }

        Ok(None)
    }

    /// Writes the pending contents and the enrollments and stores the update
    /// in the shared context.
    fn prepare(
        &self,
        resources: &BootVaultResources,
    ) -> Result<(), PuavoError> {
        let Some(update) = self.next_update(resources)? else {
            return Ok(());
        };

        let pending = update.write_pending(
            &resources.secure_boot_certificate_path(),
            &self.pending_directory,
        )?;
        let written = self.write_enrollments(update, &pending)?;

        if written == 0 {
            warn!(
                "No installed enrollment measures {}, so the update will not be applied",
                update.variable().name()
            );
        } else {
            info!(
                "{written} enrollment(s) stand for the state after the {} update",
                update.variable().name()
            );
        }

        self.context.set_prepared(PreparedSecureBootUpdate {
            update: update.clone(),
            pending,
        });

        Ok(())
    }
}

impl Configurator for PrepareSecureBootUpdateConfigurator {
    fn activate(
        &self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        if !efi::is_secure_boot_update_allowed() {
            debug!(
                "This device is not permitted to enroll a Secure Boot database"
            );
            return Ok(false);
        }

        // The enrollments run only after a TPM unlock or a PIN change, and
        // without them nothing binds the resulting state.
        if !boot_vault.is_enrollment_required()
            && !matches!(
                boot_vault.unlock_method(),
                Some(BootVaultUnlockMethod::TpmToken(..))
            )
        {
            info!(
                "Not preparing an update, because the enrollments will not run"
            );
            return Ok(false);
        }

        Ok(self.next_update(boot_vault.resources())?.is_some())
    }

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
        display: &dyn UserDisplay,
    ) -> Result<(), PuavoError> {
        let _ = display
            .show_message(locale::strings().preparing_secure_boot_update);

        self.prepare(&boot_vault.resources().clone())
    }

    fn name(&self) -> &'static str {
        "Secure Boot update preparation"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::configurators::secure_boot_update::testing::{
        shipped, shipped_database, shipped_enrollment, shipped_revocations,
        vault,
    };
    use crate::secure_boot::chain::{Measurement, Source};
    use crate::secure_boot::update::Variable;
    use tempfile::TempDir;

    /// A preparer for the databases in an image directory, with the given
    /// installed enrollments.
    fn preparer(
        image: &TempDir,
        runtime: &TempDir,
        shipped_enrollments: Vec<EnrollmentItemConfiguration>,
    ) -> PrepareSecureBootUpdateConfigurator {
        let mut updates = vec![shipped(image.path(), Variable::Db)];

        if image.path().join("dbx.bin").is_file() {
            updates.push(shipped(image.path(), Variable::Dbx));
        }

        PrepareSecureBootUpdateConfigurator {
            updates,
            shipped: shipped_enrollments,
            context: SecureBootUpdateContext::default(),
            pending_directory: runtime.path().join("pending"),
            generated_enrollment_directory: runtime.path().join("enrollment"),
        }
    }

    /// An installed enrollment that measures both variables.
    fn enrollments() -> Vec<EnrollmentItemConfiguration> {
        vec![shipped_enrollment("primary", &["db", "dbx"])]
    }

    /// The enrollments the preparer wrote.
    fn written_enrollments(
        preparer: &PrepareSecureBootUpdateConfigurator,
    ) -> Vec<EnrollmentItemConfiguration> {
        let Ok(listing) =
            fs::read_dir(&preparer.generated_enrollment_directory)
        else {
            return Vec::new();
        };

        listing
            .filter_map(|entry| entry.ok())
            .map(|entry| fs::read_to_string(entry.path()).unwrap())
            .map(|text| serde_json::from_str(&text).unwrap())
            .collect()
    }

    /// The PCR 7 chain of a written enrollment.
    fn bound_chain(written: &EnrollmentItemConfiguration) -> Vec<Measurement> {
        written.policy.specific_pcrs.as_ref().unwrap()["7:sha256"]
            .as_ref()
            .unwrap()
            .clone()
    }

    /// Records the update as enrolled, as applying it does.
    fn record(
        resources: &BootVaultResources,
        update: &SecureBootDatabaseUpdate,
    ) {
        resources
            .set_enrolled_database(update.variable().name(), &update.enrolled())
            .unwrap();
    }

    #[test]
    fn preparing_writes_coming_contents() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let (_vault, resources) = vault();
        let preparer = preparer(&image, &runtime, enrollments());

        preparer.prepare(&resources).unwrap();

        assert!(preparer.pending_directory.join("db.esl").is_file());
    }

    #[test]
    fn enrollment_stands_for_coming_state() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let (_vault, resources) = vault();
        let preparer = preparer(&image, &runtime, enrollments());

        preparer.prepare(&resources).unwrap();

        let written = written_enrollments(&preparer);
        assert_eq!(written.len(), 1);
        assert_eq!(
            written[0].name,
            shipped(image.path(), Variable::Db).enrollment_name("primary")
        );

        // The database is read from the pending file and the revocation list
        // from the machine, because only one variable is updated per boot.
        let chain = bound_chain(&written[0]);
        assert_eq!(
            chain[0],
            Measurement::Variable {
                name: "db".to_string(),
                value: Source::Path(preparer.pending_directory.join("db.esl")),
            }
        );
        assert_eq!(
            chain[1],
            Measurement::Variable {
                name: "dbx".to_string(),
                value: Source::Device,
            }
        );
    }

    #[test]
    fn one_variable_is_prepared_at_a_time() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        shipped_revocations(image.path());
        let runtime = TempDir::new().unwrap();
        let (_vault, resources) = vault();
        let preparer = preparer(&image, &runtime, enrollments());

        preparer.prepare(&resources).unwrap();

        // The database is updated first, so a new authority is enrolled
        // before the old one is revoked.
        let prepared = preparer.context.prepared().unwrap();
        assert_eq!(prepared.update.variable(), Variable::Db);
        assert!(!preparer.pending_directory.join("dbx.bin").exists());
    }

    #[test]
    fn revocation_list_follows_on_the_next_boot() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        shipped_revocations(image.path());
        let runtime = TempDir::new().unwrap();
        let (_vault, resources) = vault();
        let preparer = preparer(&image, &runtime, enrollments());

        record(&resources, &shipped(image.path(), Variable::Db));
        preparer.prepare(&resources).unwrap();

        let prepared = preparer.context.prepared().unwrap();
        assert_eq!(prepared.update.variable(), Variable::Dbx);

        // The database is enrolled, so it is read from the machine and the
        // revocation list from the pending file.
        let chain = bound_chain(&written_enrollments(&preparer)[0]);
        assert_eq!(
            chain[0],
            Measurement::Variable {
                name: "db".to_string(),
                value: Source::Device,
            }
        );
        assert_eq!(
            chain[1],
            Measurement::Variable {
                name: "dbx".to_string(),
                value: Source::Path(preparer.pending_directory.join("dbx.bin")),
            }
        );
    }

    #[test]
    fn enrollment_not_measuring_variable_gets_no_copy() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let (_vault, resources) = vault();
        let preparer = preparer(
            &image,
            &runtime,
            vec![shipped_enrollment("primary", &["dbx"])],
        );

        preparer.prepare(&resources).unwrap();

        assert!(written_enrollments(&preparer).is_empty());
    }

    #[test]
    fn preparing_records_nothing() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let (_vault, resources) = vault();
        let preparer = preparer(&image, &runtime, enrollments());

        preparer.prepare(&resources).unwrap();

        assert_eq!(resources.enrolled_database("db").unwrap(), None);
    }

    #[test]
    fn nothing_prepared_once_the_device_holds_it_all() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let (_vault, resources) = vault();
        let preparer = preparer(&image, &runtime, enrollments());

        record(&resources, &shipped(image.path(), Variable::Db));

        assert!(preparer.next_update(&resources).unwrap().is_none());
    }
}

//! Updates the Secure Boot databases directly with the keys in a directory,
//! without the enrollments that keep a TPM bound vault unlockable.

use std::path::Path;

use log::info;

use crate::{
    devices::boot_vault::BootVaultResources, error::PuavoError,
    secure_boot::update::SecureBootDatabaseUpdate, system::secure_boot,
};

/// Writes every database in the image directory that the key directory has
/// not recorded as enrolled, db before dbx, and records each one written.
/// The key directory has the layout of a boot vault. Pending contents go to
/// the pending directory. Returns the number of variables written.
pub fn update(
    databases: &Path,
    keys: &Path,
    pending: &Path,
) -> Result<usize, PuavoError> {
    let resources = BootVaultResources::new(keys);
    let mut written = 0;

    // TODO(battery-check): Skip the update on a low battery, as the initrd
    // update does on trixie-boot-trust-manager-battery-check, once merged.

    for update in SecureBootDatabaseUpdate::read_all(databases)? {
        let name = update.variable().name();
        let enrolled = resources.enrolled_database(name)?;

        if !update.should_enroll(enrolled.as_ref()) {
            continue;
        }

        let contents = update.write_pending(
            &resources.secure_boot_certificate_path(),
            pending,
        )?;

        // The firmware requires a timestamp later than the stored one, so
        // the update carries the build date.
        secure_boot::update(
            name,
            resources.mountpoint(),
            &contents,
            &update.date().to_string(),
        )?;

        resources.set_enrolled_database(name, &update.enrolled())?;
        written += 1;
    }

    info!("Wrote {written} Secure Boot variables");
    Ok(written)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::configurators::secure_boot_update::testing::{
        shipped, shipped_database, shipped_revocations, stub_update_command,
        vault,
    };
    use crate::secure_boot::update::Variable;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    #[serial_test::serial]
    fn writes_db_before_dbx_and_records_both() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        shipped_revocations(image.path());
        let runtime = TempDir::new().unwrap();
        let record = stub_update_command(runtime.path());
        let (keys, resources) = vault();

        let written =
            update(image.path(), keys.path(), runtime.path()).unwrap();

        assert_eq!(written, 2);

        let asked = fs::read_to_string(record).unwrap();
        let db = asked.find("db.esl").unwrap();
        let dbx = asked.find("dbx.bin").unwrap();
        assert!(db < dbx, "{asked}");

        for variable in [Variable::Db, Variable::Dbx] {
            let recorded =
                resources.enrolled_database(variable.name()).unwrap();
            assert_eq!(
                recorded,
                Some(shipped(image.path(), variable).enrolled())
            );
        }
    }

    #[test]
    #[serial_test::serial]
    fn enrolled_database_not_written_again() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let record = stub_update_command(runtime.path());
        let (keys, resources) = vault();
        let shipped = shipped(image.path(), Variable::Db);

        resources.set_enrolled_database("db", &shipped.enrolled()).unwrap();

        let written =
            update(image.path(), keys.path(), runtime.path()).unwrap();

        assert_eq!(written, 0);
        assert!(!record.exists(), "the firmware was given something");
    }

    #[test]
    #[serial_test::serial]
    fn newer_database_written() {
        let old = TempDir::new().unwrap();
        shipped_database(old.path(), 20250101000000);
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        let record = stub_update_command(runtime.path());
        let (keys, resources) = vault();

        let enrolled = shipped(old.path(), Variable::Db).enrolled();
        resources.set_enrolled_database("db", &enrolled).unwrap();

        let written =
            update(image.path(), keys.path(), runtime.path()).unwrap();

        assert_eq!(written, 1);

        let asked = fs::read_to_string(record).unwrap();
        assert!(asked.contains("dated 2026-01-01 00:00:00"), "{asked}");
    }

    #[test]
    #[serial_test::serial]
    fn refused_write_not_recorded() {
        let image = TempDir::new().unwrap();
        shipped_database(image.path(), 20260101000000);
        let runtime = TempDir::new().unwrap();
        stub_update_command(runtime.path());
        let (keys, resources) = vault();

        // The stub cannot record, so it fails as a refusing firmware would.
        fs::create_dir(runtime.path().join("asked")).unwrap();

        assert!(update(image.path(), keys.path(), runtime.path()).is_err());
        assert_eq!(resources.enrolled_database("db").unwrap(), None);
    }
}

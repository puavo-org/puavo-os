//! The Secure Boot database installed in an image. Reads it, decides whether
//! it should be enrolled and writes the pending contents of the variable.
//! Does not write to the firmware.

use std::{
    fmt, fs,
    io::ErrorKind,
    path::{Path, PathBuf},
};

use chrono::{NaiveDateTime, Timelike};
use log::{debug, info, warn};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::{
    error::PuavoError,
    luks::tokens::LuksTpmEnrollmentPolicy,
    secure_boot::chain::{Measurement, Source},
    secure_boot::database::{SignatureList, read_certificate_file},
    system::efi,
};

/// Directory of the pending variable contents.
pub const PENDING_DIRECTORY: &str = "/run/puavo/secure-boot-update";

/// File with the build date of the databases.
const STAMP_FILE: &str = "built";

/// Format of the build date.
const STAMP: &str = "%Y%m%d%H%M%S";

/// A Secure Boot variable that a device updates.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Variable {
    Db,
    Dbx,
}

impl Variable {
    /// The UEFI variable name.
    pub fn name(self) -> &'static str {
        match self {
            Variable::Db => "db",
            Variable::Dbx => "dbx",
        }
    }

    /// The file name of the database in an image.
    fn filename(self) -> &'static str {
        match self {
            Variable::Db => "db.esl",
            Variable::Dbx => "dbx.bin",
        }
    }

    /// Returns true when the device certificate is appended to this variable.
    /// Only db authorizes images, so only db carries it.
    fn includes_device_key(self) -> bool {
        matches!(self, Variable::Db)
    }
}

/// The build date of the databases as a variable update timestamp. The
/// firmware rejects an update with a timestamp that is not later than the
/// stored one.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Date(String);

impl Date {
    /// Parses a YYYYMMDDHHMMSS stamp, or returns None when it is not a valid
    /// date. A leap second is written as second 59.
    pub fn parse(stamp: u64) -> Option<Self> {
        let parsed =
            NaiveDateTime::parse_from_str(&format!("{stamp}"), STAMP).ok()?;

        // chrono stores a leap second as 59 plus one billion nanoseconds.
        // EFI_TIME has seconds 0 to 59, so the leap second is written as 59.
        let parsed = parsed.with_nanosecond(0)?;

        Some(Self(parsed.format("%Y-%m-%d %H:%M:%S").to_string()))
    }
}

impl fmt::Display for Date {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.0)
    }
}

/// The database enrolled for one Secure Boot variable. The digest tells
/// whether a database differs, the date whether it is newer.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EnrolledDatabase {
    digest: String,
    built: u64,
}

/// The database installed in an image for one Secure Boot variable and its
/// build date.
#[derive(Debug, Clone)]
pub struct SecureBootDatabaseUpdate {
    variable: Variable,
    path: PathBuf,
    digest: String,
    built: u64,
    date: Date,
}

impl SecureBootDatabaseUpdate {
    /// Reads the databases in an image directory, db before dbx, so a new
    /// authority is enrolled before the old one is revoked.
    pub fn read_all(directory: &Path) -> Result<Vec<Self>, PuavoError> {
        [Variable::Db, Variable::Dbx]
            .into_iter()
            .filter_map(|variable| Self::read(directory, variable).transpose())
            .collect()
    }

    /// Reads the database for one variable from an image directory, or None
    /// when there is none. A database without a build date is an error.
    pub fn read(
        directory: &Path,
        variable: Variable,
    ) -> Result<Option<Self>, PuavoError> {
        let path = directory.join(variable.filename());
        let contents = match fs::read(&path) {
            Ok(contents) => contents,
            Err(error) if error.kind() == ErrorKind::NotFound => {
                return Ok(None);
            }
            Err(error) => return Err(error.into()),
        };

        let stamp_path = directory.join(STAMP_FILE);
        let stamp = fs::read_to_string(&stamp_path).map_err(|_| {
            PuavoError::NotFound(stamp_path.display().to_string())
        })?;
        let stamp = stamp.trim();
        let malformed = || PuavoError::MalformedDate {
            path: stamp_path.display().to_string(),
            stamp: stamp.to_string(),
        };
        let built = stamp.parse::<u64>().map_err(|_| malformed())?;
        let date = Date::parse(built).ok_or_else(malformed)?;

        let digest = hex::encode(Sha256::digest(&contents));
        debug!(
            "This image carries a {} of {} bytes, built {}, as {}",
            variable.name(),
            contents.len(),
            built,
            digest
        );

        Ok(Some(Self { variable, path, digest, built, date }))
    }

    /// The variable this update is for.
    pub fn variable(&self) -> Variable {
        self.variable
    }

    /// The build date in the timestamp format of a variable update.
    pub fn date(&self) -> &Date {
        &self.date
    }

    /// The record of this database as enrolled.
    pub fn enrolled(&self) -> EnrolledDatabase {
        EnrolledDatabase { digest: self.digest.clone(), built: self.built }
    }

    /// Returns true when this database should be enrolled. Identical contents
    /// or an older build date are not.
    pub fn should_enroll(&self, enrolled: Option<&EnrolledDatabase>) -> bool {
        let name = self.variable.name();

        let Some(enrolled) = enrolled else {
            info!("Nothing enrolled for {name} yet");
            return true;
        };

        if self.digest == enrolled.digest {
            debug!("The enrolled {name} is already this one");
            return false;
        }

        if self.built > enrolled.built {
            info!(
                "The {name} in this image is newer, {} against {}",
                self.built, enrolled.built
            );
            return true;
        }

        warn!(
            "The {name} in this image is not newer, {} against {}",
            self.built, enrolled.built
        );
        false
    }

    /// Writes the pending contents of the variable and returns their path.
    pub fn write_pending(
        &self,
        device_certificate: &Path,
        directory: &Path,
    ) -> Result<PathBuf, PuavoError> {
        let mut contents = fs::read(&self.path)?;

        // db authorizes images, so the device certificate is appended.
        if self.variable.includes_device_key() {
            let certificate = read_certificate_file(device_certificate)?;
            contents.extend_from_slice(
                &SignatureList::new(&certificate, efi::PUAVO_VENDOR).bytes(),
            );
        }

        fs::create_dir_all(directory)?;
        let path = directory.join(self.variable.filename());
        fs::write(&path, &contents)?;

        info!(
            "The {} will hold {} bytes, written to {path:?}",
            self.variable.name(),
            contents.len()
        );

        Ok(path)
    }

    /// The name of the enrollment for the state after this update, derived
    /// from the name of the enrollment it is copied from.
    pub fn enrollment_name(&self, base: &str) -> String {
        format!("{base} {}", self.enrollment_ending())
    }

    /// The suffix of every enrollment name for this update. It is unique to
    /// the database contents.
    pub fn enrollment_ending(&self) -> String {
        format!("after Secure Boot update {}", self.digest)
    }

    /// A copy of the policy that reads this variable from the pending
    /// contents instead of the machine, or None when the policy does not
    /// measure it. The other variables are unchanged, since only one is
    /// updated per boot.
    pub fn policy_after(
        &self,
        policy: &LuksTpmEnrollmentPolicy,
        pending: &Path,
    ) -> Option<LuksTpmEnrollmentPolicy> {
        let name = self.variable.name();
        let reads_variable = |measurement: &Measurement| match measurement {
            Measurement::Variable { name: measured, .. } => measured == name,
            _ => false,
        };

        let pcrs = policy.specific_pcrs.as_ref()?;
        if !pcrs.values().flatten().flatten().any(reads_variable) {
            return None;
        }

        let replace_pending = |measurement: &Measurement| {
            if !reads_variable(measurement) {
                return measurement.clone();
            }

            Measurement::Variable {
                name: name.to_string(),
                value: Source::Path(pending.to_path_buf()),
            }
        };

        let restated = pcrs
            .iter()
            .map(|(register, chain)| {
                let chain = chain
                    .as_ref()
                    .map(|chain| chain.iter().map(replace_pending).collect());
                (register.clone(), chain)
            })
            .collect();

        Some(LuksTpmEnrollmentPolicy {
            specific_pcrs: Some(restated),
            ..policy.clone()
        })
    }
}

/// An update whose pending contents have been written, with their path.
#[derive(Debug, Clone)]
pub struct PreparedSecureBootUpdate {
    pub update: SecureBootDatabaseUpdate,
    pub pending: PathBuf,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::secure_boot::chain::Entry;
    use std::collections::BTreeMap;
    use tempfile::TempDir;

    /// A policy in the format of an installed one: it measures both
    /// variables and an authority of the database.
    fn create_policy() -> LuksTpmEnrollmentPolicy {
        let chain = vec![
            Measurement::Variable {
                name: "db".to_string(),
                value: Source::Device,
            },
            Measurement::Variable {
                name: "dbx".to_string(),
                value: Source::Device,
            },
            Measurement::Separator,
            Measurement::Authority {
                database: "db".to_string(),
                entry: Entry::Subject("Puavo Slab*".to_string()),
            },
        ];

        let mut pcrs = BTreeMap::new();
        pcrs.insert("7:sha256".to_string(), Some(chain));

        LuksTpmEnrollmentPolicy {
            specific_pcrs: Some(pcrs),
            public_key_pcrs_expressions: Vec::new(),
            public_key_directory: None,
            public_keys: Vec::new(),
        }
    }

    /// An image directory with a database, a revocation list and the
    /// specified build date.
    fn create_image(built: u64) -> TempDir {
        let image = TempDir::new().unwrap();
        fs::write(image.path().join("db.esl"), b"a database").unwrap();
        fs::write(image.path().join("dbx.bin"), b"a list").unwrap();
        fs::write(image.path().join(STAMP_FILE), built.to_string()).unwrap();

        image
    }

    fn read_update(
        image: &TempDir,
        variable: Variable,
    ) -> SecureBootDatabaseUpdate {
        SecureBootDatabaseUpdate::read(image.path(), variable).unwrap().unwrap()
    }

    /// The pending path of a variable, without writing it.
    fn pending(variable: Variable) -> PathBuf {
        PathBuf::from(PENDING_DIRECTORY).join(variable.filename())
    }

    #[test]
    fn updated_variable_read_from_pending_contents() {
        let image = create_image(20260909090909);
        let update = read_update(&image, Variable::Db);
        let pending = pending(Variable::Db);

        let after = update.policy_after(&create_policy(), &pending).unwrap();
        let chain = after.specific_pcrs.unwrap();

        assert_eq!(
            chain["7:sha256"].as_ref().unwrap()[0],
            Measurement::Variable {
                name: "db".to_string(),
                value: Source::Path(pending),
            }
        );
    }

    #[test]
    fn variable_not_being_written_still_read_from_machine() {
        let image = create_image(20260909090909);
        let update = read_update(&image, Variable::Db);

        let after = update
            .policy_after(&create_policy(), &pending(Variable::Db))
            .unwrap();
        let chain = after.specific_pcrs.unwrap();

        assert_eq!(
            chain["7:sha256"].as_ref().unwrap()[1],
            Measurement::Variable {
                name: "dbx".to_string(),
                value: Source::Device,
            }
        );
    }

    #[test]
    fn rest_of_chain_unchanged() {
        let image = create_image(20260909090909);
        let update = read_update(&image, Variable::Db);
        let before = create_policy();

        let after =
            update.policy_after(&before, &pending(Variable::Db)).unwrap();

        assert_eq!(
            before.specific_pcrs.unwrap()["7:sha256"].as_ref().unwrap()[3],
            after.specific_pcrs.unwrap()["7:sha256"].as_ref().unwrap()[3]
        );
    }

    #[test]
    fn policy_not_measuring_variable_gives_nothing() {
        let image = create_image(20260909090909);
        let update = read_update(&image, Variable::Dbx);
        let mut pcrs = BTreeMap::new();
        pcrs.insert(
            "7:sha256".to_string(),
            Some(vec![Measurement::Variable {
                name: "db".to_string(),
                value: Source::Device,
            }]),
        );
        let policy = LuksTpmEnrollmentPolicy {
            specific_pcrs: Some(pcrs),
            ..create_policy()
        };

        assert!(
            update.policy_after(&policy, &pending(Variable::Dbx)).is_none()
        );
    }

    #[test]
    fn policy_survives_write_and_read_back() {
        let image = create_image(20260909090909);
        let update = read_update(&image, Variable::Db);
        let after = update
            .policy_after(&create_policy(), &pending(Variable::Db))
            .unwrap();

        let written = serde_json::to_string(&after).unwrap();
        let parsed: LuksTpmEnrollmentPolicy =
            serde_json::from_str(&written).unwrap();

        assert_eq!(parsed.specific_pcrs, after.specific_pcrs);
    }

    #[test]
    fn date_stated_as_update_carries_it() {
        assert_eq!(
            Date::parse(20260909090909).map(|date| date.to_string()),
            Some("2026-09-09 09:09:09".to_string())
        );
    }

    #[test]
    fn stamp_that_is_no_date_states_none() {
        for stamp in [
            9,
            2026,
            202609090909091,
            20261309090909,
            20260932090909,
            20260909250909,
            20260909096009,
        ] {
            assert!(
                Date::parse(stamp).is_none(),
                "{stamp} was taken as a date"
            );
        }
    }

    #[test]
    fn leap_second_stamp_states_second_59() {
        assert_eq!(
            Date::parse(20260909090960).unwrap().to_string(),
            "2026-09-09 09:09:59"
        );
    }

    #[test]
    fn image_shipping_nothing_offers_nothing() {
        let image = TempDir::new().unwrap();

        assert!(
            SecureBootDatabaseUpdate::read(image.path(), Variable::Db)
                .unwrap()
                .is_none()
        );
    }

    #[test]
    fn database_with_no_date_is_refused() {
        let image = TempDir::new().unwrap();
        fs::write(image.path().join("db.esl"), b"a database").unwrap();

        assert!(
            SecureBootDatabaseUpdate::read(image.path(), Variable::Db).is_err()
        );
    }

    #[test]
    fn database_dated_by_no_date_is_refused() {
        let image = TempDir::new().unwrap();
        fs::write(image.path().join("db.esl"), b"a database").unwrap();
        fs::write(image.path().join(STAMP_FILE), b"today").unwrap();

        assert!(
            SecureBootDatabaseUpdate::read(image.path(), Variable::Db).is_err()
        );
    }

    #[test]
    fn database_is_read_before_revocations() {
        let image = create_image(20260909090909);

        let variables: Vec<Variable> =
            SecureBootDatabaseUpdate::read_all(image.path())
                .unwrap()
                .iter()
                .map(|update| update.variable())
                .collect();

        assert_eq!(variables, [Variable::Db, Variable::Dbx]);
    }

    #[test]
    fn revocation_list_carries_no_device_key() {
        assert!(!Variable::Dbx.includes_device_key());
        assert!(Variable::Db.includes_device_key());
    }

    /// An enrolled database record.
    fn create_record(digest: &str, built: u64) -> EnrolledDatabase {
        EnrolledDatabase { digest: digest.to_string(), built }
    }

    #[test]
    fn database_nothing_enrolled_for_is_enrolled() {
        let image = create_image(20260909090909);

        assert!(read_update(&image, Variable::Db).should_enroll(None));
    }

    #[test]
    fn identical_database_not_enrolled_again() {
        let image = create_image(20260909090909);
        let update = read_update(&image, Variable::Db);

        // Identical contents with an older date are the same database.
        let recorded = create_record(&update.digest, 20250909090909);

        assert!(!update.should_enroll(Some(&recorded)));
    }

    #[test]
    fn newer_database_enrolled() {
        let image = create_image(20260909090909);
        let update = read_update(&image, Variable::Db);

        let older = create_record("other", 20250909090909);

        assert!(update.should_enroll(Some(&older)));
    }

    #[test]
    fn older_database_not_enrolled() {
        let image = create_image(20260909090909);
        let update = read_update(&image, Variable::Db);

        let newer = create_record("other", 20270909090909);

        assert!(!update.should_enroll(Some(&newer)));
    }

    #[test]
    fn applied_update_not_enrolled_again() {
        let image = create_image(20260909090909);
        let update = read_update(&image, Variable::Db);

        assert!(!update.should_enroll(Some(&update.enrolled())));
    }
}

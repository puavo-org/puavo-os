use std::{
    fs,
    path::{Path, PathBuf},
    process::Command,
};

use log::{debug, info};

use crate::{
    configurators::Configurator,
    devices::boot_vault::{BootVault, BootVaultResources},
    display::UserDisplay,
    error::PuavoError,
    utils::{locale, luks_tpm_token_manager::LuksTpmTokenManager},
};

/// Directory where Secure Boot database update subdirectories are placed.
///
/// Each variable has its own subdirectory:
/// - `db/<version>.esl`
/// - `dbx/<version>.bin`
const UPDATE_BASE_DIRECTORY: &str = "/etc/puavo";

/// Secure Boot variable that this configurator may update.
#[derive(Debug, Clone, PartialEq, Eq)]
enum SecureBootVariable {
    Db,
    Dbx,
}

impl SecureBootVariable {
    /// UEFI variable name and subdirectory name.
    fn variable_name(&self) -> &'static str {
        match self {
            SecureBootVariable::Db => "db",
            SecureBootVariable::Dbx => "dbx",
        }
    }

    /// Expected file extension for this variable's update file.
    fn file_extension(&self) -> &'static str {
        match self {
            SecureBootVariable::Db => "esl",
            SecureBootVariable::Dbx => "bin",
        }
    }
}

/// A single update discovered on the filesystem.
struct DiscoveredUpdate {
    variable: SecureBootVariable,
    version: u32,
    path: PathBuf,
}

/// Extract the version number from a filename matching `<version>.<extension>`.
///
/// Returns `None` when the filename does not match the expected pattern or the
/// version cannot be parsed as an integer.
fn parse_version_from_filename(filename: &str, extension: &str) -> Option<u32> {
    let version_string = filename.strip_suffix(&format!(".{}", extension))?;
    version_string.parse::<u32>().ok()
}

/// Scan the variable's subdirectory for a file matching `<version>.<extension>`.
///
/// Returns at most one update per variable.
/// If multiple files match, the one with the highest version is returned.
fn discover_update(
    directory: &Path,
    variable: &SecureBootVariable,
) -> Option<DiscoveredUpdate> {
    let subdirectory = directory.join(variable.variable_name());
    let extension = variable.file_extension();

    let mut candidates: Vec<(PathBuf, u32)> = fs::read_dir(&subdirectory)
        .ok()?
        .filter_map(|entry| entry.ok())
        .filter_map(|entry| {
            let path = entry.path();
            let filename = path.file_name()?.to_str()?;
            let version = parse_version_from_filename(filename, extension)?;
            Some((path, version))
        })
        .collect();

    candidates.sort_by_key(|(_, version)| *version);

    candidates.pop().map(|(path, version)| DiscoveredUpdate {
        variable: variable.clone(),
        version,
        path,
    })
}

/// Trait abstracting the shell commands needed for Secure Boot variable updates.
pub trait SecureBootShell {
    /// Update the db variable using the device keys from the boot vault and
    /// the supplied EFI signature list.
    fn update_db(
        &self,
        boot_vault_mountpoint: &Path,
        efi_signature_list: &Path,
    ) -> Result<(), PuavoError>;

    /// Update the dbx variable using the device keys from the boot vault and
    /// the supplied revocation list.
    fn update_dbx(
        &self,
        boot_vault_mountpoint: &Path,
        revocation_list: &Path,
    ) -> Result<(), PuavoError>;
}

pub struct SystemSecureBootShell;

impl SecureBootShell for SystemSecureBootShell {
    fn update_db(
        &self,
        boot_vault_mountpoint: &Path,
        efi_signature_list: &Path,
    ) -> Result<(), PuavoError> {
        info!("Updating Secure Boot db from {:?}", efi_signature_list,);

        let output = Command::new("update-secure-boot-db")
            .arg(boot_vault_mountpoint)
            .arg(efi_signature_list)
            .output()
            .map_err(PuavoError::IoError)?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(PuavoError::ShellError(format!(
                "Secure Boot db update failed: {}",
                stderr,
            )));
        }

        info!("Successfully updated Secure Boot db");
        Ok(())
    }

    fn update_dbx(
        &self,
        boot_vault_mountpoint: &Path,
        revocation_list: &Path,
    ) -> Result<(), PuavoError> {
        info!("Updating Secure Boot dbx from {:?}", revocation_list,);

        let output = Command::new("update-secure-boot-dbx")
            .arg(boot_vault_mountpoint)
            .arg(revocation_list)
            .output()
            .map_err(PuavoError::IoError)?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(PuavoError::ShellError(format!(
                "Secure Boot dbx update failed: {}",
                stderr,
            )));
        }

        info!("Successfully updated Secure Boot dbx");
        Ok(())
    }
}

/// Configurator that detects and applies Secure Boot database (DB and DBX) updates.
pub struct SecureBootDatabaseConfigurator<S: SecureBootShell> {
    pending: Vec<DiscoveredUpdate>,
    shell: S,
}

impl<S: SecureBootShell> SecureBootDatabaseConfigurator<S> {
    /// Construct instance with the specified shell implementation.
    pub fn new(shell: S) -> Result<Vec<Self>, PuavoError> {
        let update_base_directory = Path::new(UPDATE_BASE_DIRECTORY);

        if !update_base_directory.is_dir() {
            debug!(
                "Secure Boot update directory '{}' does not exist, skipping",
                UPDATE_BASE_DIRECTORY,
            );
            return Ok(Vec::new());
        }

        let mut discovered: Vec<DiscoveredUpdate> = Vec::new();

        for variable in &[SecureBootVariable::Db, SecureBootVariable::Dbx] {
            if let Some(update) =
                discover_update(update_base_directory, variable)
            {
                debug!(
                    "Discovered {} update version {} at {:?}",
                    update.variable.variable_name(),
                    update.version,
                    update.path,
                );
                discovered.push(update);
            }
        }

        if discovered.is_empty() {
            return Ok(Vec::new());
        }

        Ok(vec![Self { pending: discovered, shell }])
    }

    /// Check whether any pending update has a version newer than what is
    /// recorded in the boot vault.
    fn should_activate(
        &self,
        resources: &BootVaultResources,
    ) -> Result<bool, PuavoError> {
        let db_version = resources.db_version()?;
        let dbx_version = resources.dbx_version()?;

        info!(
            "Secure Boot database versions: db={}, dbx={}",
            db_version, dbx_version,
        );

        let activate = self.pending.iter().any(|update| {
            let current = match update.variable {
                SecureBootVariable::Db => db_version,
                SecureBootVariable::Dbx => dbx_version,
            };
            update.version > current
        });

        Ok(activate)
    }

    /// Apply all pending updates whose version exceeds the installed version
    /// recorded in the boot vault.
    fn apply_updates(
        &self,
        resources: &BootVaultResources,
    ) -> Result<(), PuavoError> {
        let mountpoint = resources.mountpoint();
        let db_version = resources.db_version()?;
        let dbx_version = resources.dbx_version()?;

        for update in &self.pending {
            let current = match update.variable {
                SecureBootVariable::Db => db_version,
                SecureBootVariable::Dbx => dbx_version,
            };

            if update.version <= current {
                continue;
            }

            info!(
                "Applying {} update version {}",
                update.variable.variable_name(),
                update.version,
            );

            match update.variable {
                SecureBootVariable::Db => {
                    self.shell.update_db(mountpoint, &update.path)?;
                    resources.set_db_version(update.version)?;
                }
                SecureBootVariable::Dbx => {
                    self.shell.update_dbx(mountpoint, &update.path)?;
                    resources.set_dbx_version(update.version)?;
                }
            }

            info!(
                "Secure Boot {} updated to version {}",
                update.variable.variable_name(),
                update.version,
            );
        }

        Ok(())
    }
}

impl<S: SecureBootShell> Configurator for SecureBootDatabaseConfigurator<S> {
    fn activate(
        &self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        self.should_activate(boot_vault.resources())
    }

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
        display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        let _ = display.show_message(locale::strings().updating_secure_boot);
        self.apply_updates(&boot_vault.resources().clone())
    }

    fn name(&self) -> &'static str {
        "SecureBootDatabase"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;
    use tempfile::TempDir;

    struct MockSecureBootShell {
        update_db_calls: RefCell<Vec<(String, String)>>,
        update_dbx_calls: RefCell<Vec<(String, String)>>,
    }

    impl MockSecureBootShell {
        fn new() -> Self {
            Self {
                update_db_calls: RefCell::new(Vec::new()),
                update_dbx_calls: RefCell::new(Vec::new()),
            }
        }
    }

    impl SecureBootShell for MockSecureBootShell {
        fn update_db(
            &self,
            boot_vault_mountpoint: &Path,
            efi_signature_list: &Path,
        ) -> Result<(), PuavoError> {
            self.update_db_calls.borrow_mut().push((
                boot_vault_mountpoint.display().to_string(),
                efi_signature_list.display().to_string(),
            ));
            Ok(())
        }

        fn update_dbx(
            &self,
            boot_vault_mountpoint: &Path,
            revocation_list: &Path,
        ) -> Result<(), PuavoError> {
            self.update_dbx_calls.borrow_mut().push((
                boot_vault_mountpoint.display().to_string(),
                revocation_list.display().to_string(),
            ));
            Ok(())
        }
    }

    fn write_update_file(directory: &Path, filename: &str) -> PathBuf {
        let path = directory.join(filename);
        fs::write(&path, b"test-data").unwrap();
        path
    }

    fn make_vault() -> (TempDir, BootVaultResources) {
        let directory = TempDir::new().unwrap();
        let resources = BootVaultResources::new(directory.path());
        (directory, resources)
    }

    /// Build a configurator directly from known pending updates.
    fn make_configurator(
        pending: Vec<DiscoveredUpdate>,
    ) -> SecureBootDatabaseConfigurator<MockSecureBootShell> {
        SecureBootDatabaseConfigurator {
            pending,
            shell: MockSecureBootShell::new(),
        }
    }

    #[test]
    fn test_parse_version_from_filename() {
        assert_eq!(parse_version_from_filename("3.esl", "esl"), Some(3));
        assert_eq!(parse_version_from_filename("42.bin", "bin"), Some(42));
        assert_eq!(parse_version_from_filename("abc.esl", "esl"), None);
        assert_eq!(parse_version_from_filename("3.bin", "esl"), None);
        assert_eq!(parse_version_from_filename("unrelated.txt", "esl"), None);
    }

    #[test]
    fn test_discover_finds_db_and_dbx_updates() {
        let directory = TempDir::new().unwrap();
        fs::create_dir(directory.path().join("db")).unwrap();
        fs::create_dir(directory.path().join("dbx")).unwrap();
        write_update_file(&directory.path().join("db"), "3.esl");
        write_update_file(&directory.path().join("dbx"), "7.bin");

        let db =
            discover_update(directory.path(), &SecureBootVariable::Db).unwrap();
        assert_eq!(db.version, 3);
        assert_eq!(db.variable, SecureBootVariable::Db);

        let dbx = discover_update(directory.path(), &SecureBootVariable::Dbx)
            .unwrap();
        assert_eq!(dbx.version, 7);
        assert_eq!(dbx.variable, SecureBootVariable::Dbx);
    }

    #[test]
    fn test_discover_picks_highest_version() {
        let directory = TempDir::new().unwrap();
        let db_directory = directory.path().join("db");
        fs::create_dir(&db_directory).unwrap();
        write_update_file(&db_directory, "1.esl");
        write_update_file(&db_directory, "5.esl");
        write_update_file(&db_directory, "3.esl");

        let update = discover_update(directory.path(), &SecureBootVariable::Db);
        assert_eq!(update.unwrap().version, 5);
    }

    #[test]
    fn test_discover_returns_none_when_no_valid_files() {
        let directory = TempDir::new().unwrap();
        let db_directory = directory.path().join("db");
        fs::create_dir(&db_directory).unwrap();

        // Wrong extension
        write_update_file(&db_directory, "1.bin");
        assert!(
            discover_update(directory.path(), &SecureBootVariable::Db)
                .is_none()
        );

        // Non-numeric version
        write_update_file(&db_directory, "abc.esl");
        assert!(
            discover_update(directory.path(), &SecureBootVariable::Db)
                .is_none()
        );

        // Missing subdirectory
        let empty = TempDir::new().unwrap();
        assert!(
            discover_update(empty.path(), &SecureBootVariable::Db).is_none()
        );
    }

    #[test]
    fn test_should_activate_only_when_update_is_newer() {
        let (_vault_dir, resources) = make_vault();
        resources.set_db_version(5).unwrap();

        let make = |version| {
            make_configurator(vec![DiscoveredUpdate {
                variable: SecureBootVariable::Db,
                version,
                path: PathBuf::from("/updates/db/x.esl"),
            }])
        };

        assert!(make(6).should_activate(&resources).unwrap());
        assert!(!make(5).should_activate(&resources).unwrap());
        assert!(!make(3).should_activate(&resources).unwrap());
    }

    #[test]
    fn test_should_activate_mixed_updates_one_newer() {
        let (_vault_dir, resources) = make_vault();
        resources.set_db_version(5).unwrap();
        resources.set_dbx_version(1).unwrap();

        let configurator = make_configurator(vec![
            DiscoveredUpdate {
                variable: SecureBootVariable::Db,
                version: 5,
                path: PathBuf::from("/updates/db/5.esl"),
            },
            DiscoveredUpdate {
                variable: SecureBootVariable::Dbx,
                version: 2,
                path: PathBuf::from("/updates/dbx/2.bin"),
            },
        ]);

        assert!(configurator.should_activate(&resources).unwrap());
    }

    #[test]
    fn test_apply_updates_calls_correct_shell_and_records_versions() {
        let (_vault_dir, resources) = make_vault();
        let db_path = PathBuf::from("/updates/db/2.esl");
        let dbx_path = PathBuf::from("/updates/dbx/3.bin");

        let configurator = make_configurator(vec![
            DiscoveredUpdate {
                variable: SecureBootVariable::Db,
                version: 2,
                path: db_path.clone(),
            },
            DiscoveredUpdate {
                variable: SecureBootVariable::Dbx,
                version: 3,
                path: dbx_path.clone(),
            },
        ]);

        configurator.apply_updates(&resources).unwrap();

        let mountpoint = resources.mountpoint().display().to_string();

        let db_calls = configurator.shell.update_db_calls.borrow();
        assert_eq!(db_calls.len(), 1);
        assert_eq!(db_calls[0].0, mountpoint);
        assert_eq!(db_calls[0].1, db_path.display().to_string());

        let dbx_calls = configurator.shell.update_dbx_calls.borrow();
        assert_eq!(dbx_calls.len(), 1);
        assert_eq!(dbx_calls[0].0, mountpoint);
        assert_eq!(dbx_calls[0].1, dbx_path.display().to_string());

        assert_eq!(resources.db_version().unwrap(), 2);
        assert_eq!(resources.dbx_version().unwrap(), 3);
    }

    #[test]
    fn test_apply_updates_skips_outdated_updates() {
        let (_vault_dir, resources) = make_vault();
        resources.set_db_version(5).unwrap();

        let configurator = make_configurator(vec![
            DiscoveredUpdate {
                variable: SecureBootVariable::Db,
                version: 5,
                path: PathBuf::from("/updates/db/5.esl"),
            },
            DiscoveredUpdate {
                variable: SecureBootVariable::Dbx,
                version: 1,
                path: PathBuf::from("/updates/dbx/1.bin"),
            },
        ]);

        configurator.apply_updates(&resources).unwrap();

        assert_eq!(configurator.shell.update_db_calls.borrow().len(), 0);
        assert_eq!(configurator.shell.update_dbx_calls.borrow().len(), 1);

        assert_eq!(resources.db_version().unwrap(), 5);
        assert_eq!(resources.dbx_version().unwrap(), 1);
    }
}

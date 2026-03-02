use std::{
    fs,
    path::{Path, PathBuf},
    process::Command,
};

use log::{debug, info};

use crate::{
    configurators::Configurator,
    devices::boot_vault::BootVault,
    display::UserDisplay,
    error::PuavoError,
    utils::luks_tpm_token_manager::LuksTpmTokenManager,
};

/// Directory where Secure Boot database update files are placed.
///
/// Expected filenames:
/// - `db-<version>.esl`  (EFI signature list that replaces the db variable)
/// - `dbx-<version>.bin` (Revocation list to append to the dbx variable)
///
/// Only one file per variable should be present at a time.
const UPDATE_DIRECTORY: &str = "/etc/puavo/secure-boot-updates";

/// Secure Boot variable that this configurator may update.
#[derive(Debug, Clone, PartialEq, Eq)]
enum SecureBootVariable {
    Db,
    Dbx,
}

impl SecureBootVariable {
    /// UEFI variable name used by efi-updatevar.
    fn variable_name(&self) -> &'static str {
        match self {
            SecureBootVariable::Db => "db",
            SecureBootVariable::Dbx => "dbx",
        }
    }

    /// Filename prefix used to discover update files.
    fn file_prefix(&self) -> &'static str {
        match self {
            SecureBootVariable::Db => "db-",
            SecureBootVariable::Dbx => "dbx-",
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

/// Extract the version number from a filename matching `<prefix><version>.<extension>`.
///
/// Returns `None` when the filename does not match the expected pattern or the
/// version cannot be parsed as an integer.
fn parse_version_from_filename(
    filename: &str,
    prefix: &str,
    extension: &str,
) -> Option<u32> {
    let without_prefix = filename.strip_prefix(prefix)?;
    let version_string = without_prefix.strip_suffix(&format!(".{}", extension))?;
    version_string.parse::<u32>().ok()
}

/// Scan the update directory for a file matching `<prefix><version>.<extension>`.
///
/// Returns at most one update per variable.
/// If multiple files match, the one with the latest version is returned.
fn discover_update(
    directory: &Path,
    variable: &SecureBootVariable,
) -> Option<DiscoveredUpdate> {
    let prefix = variable.file_prefix();
    let extension = variable.file_extension();

    let mut candidates: Vec<(PathBuf, u32)> = fs::read_dir(directory)
        .ok()?
        .filter_map(|entry| entry.ok())
        .filter_map(|entry| {
            let path = entry.path();
            let filename = path.file_name()?.to_str()?;
            let version = parse_version_from_filename(filename, prefix, extension)?;
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
trait SecureBootShell {
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

struct SystemSecureBootShell;

impl SecureBootShell for SystemSecureBootShell {
    fn update_db(
        &self,
        boot_vault_mountpoint: &Path,
        efi_signature_list: &Path,
    ) -> Result<(), PuavoError> {
        info!(
            "Updating Secure Boot db from {:?}",
            efi_signature_list,
        );

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
        info!(
            "Updating Secure Boot dbx from {:?}",
            revocation_list,
        );

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
pub struct SecureBootDatabaseConfigurator {
    pending: Vec<DiscoveredUpdate>,
    shell: Box<dyn SecureBootShell>,
}

impl SecureBootDatabaseConfigurator {
    /// Construct instances using the real shell and the default update directory.
    pub fn new() -> Result<Vec<Self>, PuavoError> {
        Self::with_shell(Box::new(SystemSecureBootShell))
    }

    /// Construct instance with the specified shell implementation.
    fn with_shell(
        shell: Box<dyn SecureBootShell>,
    ) -> Result<Vec<Self>, PuavoError> {
        let update_directory = Path::new(UPDATE_DIRECTORY);

        if !update_directory.is_dir() {
            debug!(
                "Secure Boot update directory '{}' does not exist, skipping",
                UPDATE_DIRECTORY,
            );
            return Ok(Vec::new());
        }

        let mut discovered: Vec<DiscoveredUpdate> = Vec::new();

        for variable in &[SecureBootVariable::Db, SecureBootVariable::Dbx] {
            if let Some(update) = discover_update(update_directory, variable) {
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
}

impl Configurator for SecureBootDatabaseConfigurator {
    fn activate(
        &self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
    ) -> Result<bool, PuavoError> {
        let resources = boot_vault.resources();
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

    fn configure(
        &mut self,
        boot_vault: &mut BootVault,
        _primary_partition: &mut LuksTpmTokenManager,
        display: &Box<dyn UserDisplay>,
    ) -> Result<(), PuavoError> {
        let resources = boot_vault.resources().clone();
        let mountpoint = resources.mountpoint();

        let db_version = resources.db_version()?;
        let dbx_version = resources.dbx_version()?;

        let _ = display.show_message("Updating Secure Boot...");

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

    fn name(&self) -> &'static str {
        "SecureBootDatabase"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::devices::boot_vault::BootVaultResources;
    use std::cell::RefCell;
    use tempfile::TempDir;

    #[allow(dead_code)]
    struct MockSecureBootShell {
        update_db_calls:
            RefCell<Vec<(String, String)>>,
        update_dbx_calls:
            RefCell<Vec<(String, String)>>,
    }

    impl MockSecureBootShell {
        #[allow(dead_code)]
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

    #[test]
    fn test_variable_names() {
        assert_eq!(SecureBootVariable::Db.variable_name(), "db");
        assert_eq!(SecureBootVariable::Dbx.variable_name(), "dbx");
    }

    #[test]
    fn test_file_prefix_and_extension() {
        assert_eq!(SecureBootVariable::Db.file_prefix(), "db-");
        assert_eq!(SecureBootVariable::Db.file_extension(), "esl");
        assert_eq!(SecureBootVariable::Dbx.file_prefix(), "dbx-");
        assert_eq!(SecureBootVariable::Dbx.file_extension(), "bin");
    }

    #[test]
    fn test_parse_version_from_filename() {
        assert_eq!(parse_version_from_filename("db-3.esl", "db-", "esl"), Some(3));
        assert_eq!(parse_version_from_filename("dbx-42.bin", "dbx-", "bin"), Some(42));
        assert_eq!(parse_version_from_filename("db-abc.esl", "db-", "esl"), None);
        assert_eq!(parse_version_from_filename("db-3.bin", "db-", "esl"), None);
        assert_eq!(parse_version_from_filename("dbx-3.esl", "db-", "esl"), None);
        assert_eq!(parse_version_from_filename("unrelated.txt", "db-", "esl"), None);
    }

    #[test]
    fn test_installed_version_defaults_to_zero() {
        let (_directory, resources) = make_vault();
        assert_eq!(resources.db_version().unwrap(), 0);
        assert_eq!(resources.dbx_version().unwrap(), 0);
    }

    #[test]
    fn test_version_round_trip() {
        let (_directory, resources) = make_vault();
        resources.set_dbx_version(42).unwrap();
        assert_eq!(resources.dbx_version().unwrap(), 42);
    }

    #[test]
    fn test_db_and_dbx_versions_are_independent() {
        let (_directory, resources) = make_vault();
        resources.set_db_version(10).unwrap();
        resources.set_dbx_version(20).unwrap();

        assert_eq!(resources.db_version().unwrap(), 10);
        assert_eq!(resources.dbx_version().unwrap(), 20);
    }

    #[test]
    fn test_discover_db_update() {
        let directory = TempDir::new().unwrap();
        write_update_file(directory.path(), "db-3.esl");

        let update =
            discover_update(directory.path(), &SecureBootVariable::Db);
        assert!(update.is_some());
        let update = update.unwrap();
        assert_eq!(update.version, 3);
        assert_eq!(update.variable, SecureBootVariable::Db);
    }

    #[test]
    fn test_discover_dbx_update() {
        let directory = TempDir::new().unwrap();
        write_update_file(directory.path(), "dbx-7.bin");

        let update =
            discover_update(directory.path(), &SecureBootVariable::Dbx);
        assert!(update.is_some());
        let update = update.unwrap();
        assert_eq!(update.version, 7);
        assert_eq!(update.variable, SecureBootVariable::Dbx);
    }

    #[test]
    fn test_discover_picks_highest_version() {
        let directory = TempDir::new().unwrap();
        write_update_file(directory.path(), "db-1.esl");
        write_update_file(directory.path(), "db-5.esl");
        write_update_file(directory.path(), "db-3.esl");

        let update =
            discover_update(directory.path(), &SecureBootVariable::Db);
        assert!(update.is_some());
        assert_eq!(update.unwrap().version, 5);
    }

    #[test]
    fn test_discover_ignores_wrong_extension() {
        let directory = TempDir::new().unwrap();
        write_update_file(directory.path(), "db-1.bin");

        let update =
            discover_update(directory.path(), &SecureBootVariable::Db);
        assert!(update.is_none());
    }

    #[test]
    fn test_discover_ignores_wrong_prefix() {
        let directory = TempDir::new().unwrap();
        write_update_file(directory.path(), "dbx-1.esl");

        let update =
            discover_update(directory.path(), &SecureBootVariable::Db);
        assert!(update.is_none());
    }

    #[test]
    fn test_discover_ignores_non_numeric_version() {
        let directory = TempDir::new().unwrap();
        write_update_file(directory.path(), "db-abc.esl");

        let update =
            discover_update(directory.path(), &SecureBootVariable::Db);
        assert!(update.is_none());
    }

    #[test]
    fn test_discover_returns_none_for_empty_directory() {
        let directory = TempDir::new().unwrap();

        let update =
            discover_update(directory.path(), &SecureBootVariable::Db);
        assert!(update.is_none());
    }

    #[test]
    fn test_discover_returns_none_for_missing_directory() {
        let update = discover_update(
            Path::new("/nonexistent"),
            &SecureBootVariable::Db,
        );
        assert!(update.is_none());
    }
}

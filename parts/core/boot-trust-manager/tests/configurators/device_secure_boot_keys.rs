use std::{
    fs, io,
    os::unix::fs::PermissionsExt,
    path::{Path, PathBuf},
};

use serial_test::serial;
use tempfile::TempDir;

use puavo_boot_trust_manager::{
    configurators::device_secure_boot_keys::install_keys,
    devices::boot_vault::BootVaultResources,
};

const PRIVATE_KEY_FILENAME: &str = "secure-boot.priv";
const CERTIFICATE_FILENAME: &str = "secure-boot.pem";

const FAKE_PRIVATE_KEY: &[u8] = b"---fake-private-key---\n";
const FAKE_CERTIFICATE: &[u8] = b"---fake-certificate---\n";

/// Self contained test fixture combining a fake boot vault directory
/// and a fresh destination directory for installed keys.
struct Fixture {
    vault: TempDir,
    destination_parent: TempDir,
}

impl Fixture {
    fn new(write_private_key: bool, write_certificate: bool) -> Self {
        let vault = TempDir::new()
            .expect("Failed to create the vault fixture directory");
        if write_private_key {
            fs::write(
                vault.path().join(PRIVATE_KEY_FILENAME),
                FAKE_PRIVATE_KEY,
            )
            .expect(
                "Failed to write the fake private key into the vault fixture",
            );
        }
        if write_certificate {
            fs::write(
                vault.path().join(CERTIFICATE_FILENAME),
                FAKE_CERTIFICATE,
            )
            .expect(
                "Failed to write the fake certificate into the vault fixture",
            );
        }
        Self {
            vault,
            destination_parent: TempDir::new()
                .expect("Failed to create the destination parent directory"),
        }
    }

    fn populated() -> Self {
        Self::new(true, true)
    }

    fn resources(&self) -> BootVaultResources {
        BootVaultResources::new(self.vault.path())
    }

    fn destination(&self) -> PathBuf {
        self.destination_parent.path().join("secure-boot-keys")
    }
}

fn mode_bits(path: &Path) -> u32 {
    fs::metadata(path)
        .expect("Failed to read metadata for the installed path")
        .permissions()
        .mode()
        & 0o7777
}

#[test]
#[serial]
fn installs_keys_with_expected_modes() {
    let fixture = Fixture::populated();
    let destination = fixture.destination();

    install_keys(&fixture.resources(), &destination).expect(
        "install_keys should succeed when both key files exist in the vault",
    );

    assert_eq!(mode_bits(&destination), 0o700);

    let private_key = destination.join(PRIVATE_KEY_FILENAME);
    let certificate = destination.join(CERTIFICATE_FILENAME);

    assert_eq!(
        fs::read(&private_key)
            .expect("Failed to read the installed private key"),
        FAKE_PRIVATE_KEY,
    );
    assert_eq!(
        fs::read(&certificate)
            .expect("Failed to read the installed certificate"),
        FAKE_CERTIFICATE,
    );
    assert_eq!(mode_bits(&private_key), 0o600);
    assert_eq!(mode_bits(&certificate), 0o644);
}

#[test]
#[serial]
fn tightens_existing_destination_directory_mode() {
    let fixture = Fixture::populated();
    let destination = fixture.destination();
    fs::create_dir(&destination)
        .expect("Failed to pre create the destination directory");
    fs::set_permissions(&destination, fs::Permissions::from_mode(0o755))
        .expect("Failed to set a permissive mode on the destination directory");

    install_keys(&fixture.resources(), &destination).expect(
        "install_keys should succeed when the destination directory already exists",
    );

    assert_eq!(mode_bits(&destination), 0o700);
}

#[test]
#[serial]
fn installs_keys_with_expected_modes_even_when_previous_files_have_wrong_mode()
{
    let fixture = Fixture::populated();
    let destination = fixture.destination();
    fs::create_dir(&destination)
        .expect("Failed to pre create the destination directory");

    let stale_private_key = destination.join(PRIVATE_KEY_FILENAME);
    fs::write(&stale_private_key, b"stale")
        .expect("Failed to write a stale private key file");
    fs::set_permissions(&stale_private_key, fs::Permissions::from_mode(0o666))
        .expect("Failed to set a permissive mode on the stale private key");

    install_keys(&fixture.resources(), &destination).expect(
        "install_keys should succeed when a stale destination file is present",
    );

    assert_eq!(mode_bits(&stale_private_key), 0o600);
}

#[test]
#[serial]
fn fails_when_private_key_is_missing_in_the_vault() {
    let fixture = Fixture::new(false, true);
    let error = install_keys(&fixture.resources(), &fixture.destination())
        .expect_err(
            "install_keys should fail when the private key is missing in the vault",
        );
    assert_eq!(error.kind(), io::ErrorKind::NotFound);
}

#[test]
#[serial]
fn fails_when_certificate_is_missing_in_the_vault() {
    let fixture = Fixture::new(true, false);
    let error = install_keys(&fixture.resources(), &fixture.destination())
        .expect_err(
            "install_keys should fail when the certificate is missing in the vault",
        );
    assert_eq!(error.kind(), io::ErrorKind::NotFound);
}

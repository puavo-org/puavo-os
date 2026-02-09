use std::fs;
use std::process::{Command, Stdio};

use crate::common::{TEST_ROOT, script};

pub const RECOVERY_KEY: &str = "test-key-12345";

#[allow(dead_code)]
pub struct TestImages {
    pub directory: String,
    pub vault: String,
    pub primary: String,
}

impl TestImages {
    fn new(directory: &str) -> Self {
        Self {
            directory: directory.to_string(),
            vault: format!("{}/vault.img", directory),
            primary: format!("{}/primary.img", directory),
        }
    }
}

fn base_directory() -> String {
    format!("{}/base", TEST_ROOT)
}

/// Ensure base images exist, creating them if needed.
fn ensure_base_images() {
    let base_vault = format!("{}/vault.img", base_directory());
    if fs::metadata(&base_vault).is_ok() {
        return;
    }

    fs::create_dir_all(base_directory())
        .expect("Failed to create base directory");

    let status = Command::new(script("luks.sh"))
        .arg(base_directory())
        .arg(RECOVERY_KEY)
        .status()
        .expect("Failed to execute setup script");
    assert!(status.success(), "LUKS base image setup failed");
}

/// Create test images by copying from base images.
pub fn setup(test_name: &str) -> TestImages {
    reset();
    ensure_base_images();

    let directory = format!("{}/{}", TEST_ROOT, test_name);
    let _ = fs::remove_dir_all(&directory);
    fs::create_dir_all(&directory).expect("Failed to create test directory");

    fs::copy(
        format!("{}/vault.img", base_directory()),
        format!("{}/vault.img", directory),
    )
    .expect("Failed to copy vault image");
    fs::copy(
        format!("{}/primary.img", base_directory()),
        format!("{}/primary.img", directory),
    )
    .expect("Failed to copy primary image");

    TestImages::new(directory.as_str())
}

/// Close any open test LUKS devices and detach loop devices.
pub fn reset() {
    println!("Resetting LUKS state...");

    fn quiet(command: &mut Command) -> &mut Command {
        command.stdout(Stdio::null()).stderr(Stdio::null())
    }

    let _ = quiet(&mut Command::new("umount"))
        .arg("/run/puavo/boot-vault")
        .status();
    let _ = quiet(&mut Command::new("cryptsetup"))
        .args(["close", "puavo-boot-vault"])
        .status();
    let _ = quiet(&mut Command::new("cryptsetup"))
        .args(["close", "vault"])
        .status();
    let _ = quiet(&mut Command::new("losetup")).arg("-D").status();
}

/// Remove the entire test root directory.
pub fn clean_all() {
    reset();
    println!("Removing the test root directory...");
    let _ = fs::remove_dir_all(TEST_ROOT);
}

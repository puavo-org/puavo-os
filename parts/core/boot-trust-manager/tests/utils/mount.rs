use std::fs;
use std::process::Command;

use serial_test::serial;
use tempfile::TempDir;

use puavo_boot_trust_manager::utils::mount::{MountGuard, unmount};

/// Helper to perform a bind mount
fn bind_mount(source: &std::path::Path, target: &std::path::Path) {
    let status = Command::new("mount")
        .arg("--bind")
        .arg(source)
        .arg(target)
        .status()
        .expect("Failed to execute mount command");
    assert!(status.success(), "Mount command failed");
}

/// Helper to check if a path is mounted
fn is_mounted(path: &std::path::Path) -> bool {
    Command::new("mountpoint")
        .arg("-q")
        .arg(path)
        .status()
        .expect("Failed to execute mountpoint command")
        .success()
}

#[test]
#[serial]
fn mount_guard_unmounts_on_drop() {
    let source = TempDir::new().unwrap();
    let target = TempDir::new().unwrap();

    bind_mount(source.path(), target.path());
    assert!(is_mounted(target.path()));

    {
        let _ = MountGuard::new(target.path());
    }

    std::thread::sleep(std::time::Duration::from_millis(100));
    assert!(!is_mounted(target.path()));
}

#[test]
#[serial]
fn mount_guard_explicit_unmount() {
    let source = TempDir::new().unwrap();
    let target = TempDir::new().unwrap();

    bind_mount(source.path(), target.path());

    let guard = MountGuard::new(target.path());
    guard.unmount().expect("Unmount should succeed");

    std::thread::sleep(std::time::Duration::from_millis(100));
    assert!(!is_mounted(target.path()));
}

#[test]
#[serial]
fn unmount_nonexistent_fails() {
    let temp = TempDir::new().unwrap();
    let result = unmount(&temp.path().to_path_buf());
    assert!(result.is_err());
}

#[test]
#[serial]
fn mount_guard_lazy_unmount_on_busy() {
    let source = TempDir::new().unwrap();
    let target = TempDir::new().unwrap();

    fs::write(source.path().join("test.txt"), "content").unwrap();
    bind_mount(source.path(), target.path());

    let _file = fs::File::open(target.path().join("test.txt")).unwrap();
    let guard = MountGuard::new(target.path());

    // Lazy unmount should succeed even with open file
    assert!(guard.unmount().is_ok());
}

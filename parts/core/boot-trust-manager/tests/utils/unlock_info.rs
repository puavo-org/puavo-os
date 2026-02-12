use serial_test::serial;
use tempfile::TempDir;

use puavo_boot_trust_manager::utils::unlock_info::{
    UNLOCK_INFO_PATH, save_to_efi,
};

#[test]
#[serial]
fn unlock_info_json_encoding_and_fields() {
    // Collect unlock info and save to "EFI"
    let temporary_directory = TempDir::new().unwrap();
    std::fs::create_dir_all(temporary_directory.path().join("EFI/puavo"))
        .unwrap();

    save_to_efi(temporary_directory.path());

    let info_file = temporary_directory.path().join(UNLOCK_INFO_PATH);
    assert!(info_file.exists(), "Should create unlock info file");

    // Verify saved file is valid JSON
    let saved_content = std::fs::read_to_string(&info_file).unwrap();
    let value: serde_json::Value = serde_json::from_str(&saved_content)
        .expect("Saved file should be valid JSON");

    // Verify the fields exist
    assert!(value["firmware"].is_object());
    assert!(value["kernel_commandline"].is_string());
}

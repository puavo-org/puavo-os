use std::fs;
use std::path::Path;
use std::process::Command;

use boot_trust_manager::error::PuavoError;
use boot_trust_manager::luks::ciphers::{LuksArea, refuse_null_cipher};
use libcryptsetup_rs::CryptInit;
use libcryptsetup_rs::consts::vals::EncryptionFormat;

use crate::common::{TEST_ROOT, script};

/// Creates an image of the luks-cipher.sh kind and checks its ciphers the
/// way the manager does after loading the header.
fn check(kind: &str) -> Result<(), PuavoError> {
    fs::create_dir_all(TEST_ROOT).expect("Failed to create the test root");
    let image = Path::new(TEST_ROOT).join(format!("{kind}.img"));

    let status = Command::new(script("luks-cipher.sh"))
        .arg(&image)
        .arg(kind)
        .status()
        .expect("Failed to run luks-cipher.sh");
    assert!(status.success(), "Failed to create {image:?}");

    let mut device = CryptInit::init(&image).expect("Failed to open the image");
    device
        .context_handle()
        .load::<()>(Some(EncryptionFormat::Luks2), None)
        .expect("Failed to load the header");
    let result = refuse_null_cipher(&mut device);

    fs::remove_file(&image).expect("Failed to remove the image");
    result
}

#[test]
fn an_encrypted_device_is_accepted() {
    assert!(check("encrypted").is_ok());
}

#[test]
fn null_cipher_data_is_refused() {
    let result = check("null-data");
    assert!(matches!(result, Err(PuavoError::NullCipher(LuksArea::Data))));
}

#[test]
fn a_null_cipher_keyslot_is_refused() {
    let result = check("null-keyslot");
    assert!(matches!(
        result,
        Err(PuavoError::NullCipher(LuksArea::Keyslot(0)))
    ));
}

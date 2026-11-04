use std::fmt;

use libcryptsetup_rs::consts::vals::{EncryptionFormat, KeyslotInfo};
use libcryptsetup_rs::{CryptDevice, CryptKeyslotHandle, c_uint};
use log::debug;

use crate::error::PuavoError;

// The cipher name cryptsetup uses for no encryption, with or without a mode,
// for example "cipher_null-ecb".
const NULL_CIPHER: &str = "cipher_null";

/// A part of a LUKS2 device that is encrypted with its own cipher.
#[derive(Debug, PartialEq)]
pub enum LuksArea {
    Data,
    Keyslot(c_uint),
}

impl fmt::Display for LuksArea {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            LuksArea::Data => write!(formatter, "the data"),
            LuksArea::Keyslot(keyslot) => {
                write!(formatter, "keyslot {keyslot}")
            }
        }
    }
}

/// Refuses a LUKS2 device whose data or any keyslot area is not encrypted.
/// Returns an error upon finding a null cipher or failing to read the header.
pub fn refuse_null_cipher(device: &mut CryptDevice) -> Result<(), PuavoError> {
    let data_cipher = device.status_handle().get_cipher()?;
    debug!("LUKS data cipher: {data_cipher}");
    if data_cipher.starts_with(NULL_CIPHER) {
        return Err(PuavoError::NullCipher(LuksArea::Data));
    }

    for keyslot in find_used_keyslots(device)? {
        let mut keyslots = device.keyslot_handle();
        let (cipher, _) = keyslots.get_encryption(Some(keyslot))?;
        debug!("LUKS keyslot {keyslot} cipher: {cipher}");
        if cipher.starts_with(NULL_CIPHER) {
            return Err(PuavoError::NullCipher(LuksArea::Keyslot(keyslot)));
        }
    }

    Ok(())
}

/// Returns the keyslots of the device that hold a key.
fn find_used_keyslots(
    device: &mut CryptDevice,
) -> Result<Vec<c_uint>, PuavoError> {
    let count = CryptKeyslotHandle::max_keyslots(EncryptionFormat::Luks2)?;

    (0..count)
        .filter_map(|keyslot| match device.keyslot_handle().status(keyslot) {
            Ok(KeyslotInfo::Invalid | KeyslotInfo::Inactive) => None,
            Ok(_) => Some(Ok(keyslot)),
            Err(error) => Some(Err(error.into())),
        })
        .collect()
}

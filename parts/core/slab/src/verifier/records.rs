//! Implements recording of authorities and images by measuring them using TPM.

use crate::tpm::{self, CommandError, CommandResult, Extension};
use alloc::vec::Vec;
use uefi::proto::tcg::EventType;
use uefi::proto::tcg::v2::{HashLogExtendEventFlags, Tcg};
use uefi::{CStr16, Guid, Status, cstr16, guid};

const AUTHORITY_NAME: &CStr16 = cstr16!("SlabAuthority");
const AUTHORITY_OWNER: Guid = guid!("af20bc5d-65ab-4c7c-80b4-b4efbf5ba588");
const CERTIFICATE_NAME: &CStr16 = cstr16!("SlabCertificate");

const FLAT_IMAGE_EVENT_ID: u32 = 0x514B_F1A7;

// TCG PC Client Platform Firmware Profile specification, revision 1.06:
//
// typedef struct UEFI_VARIABLE_DATA {
//     UEFI_GUID VariableName;
//     UINT64 UnicodeNameLength;
//     UINT64 VariableDataLength;
//     CHAR16 UnicodeName[];
//     INT8 VariableData[]; // Driver or platform-specific data
// } UEFI_VARIABLE_DATA;
//
// UEFI specification, EFI_SIGNATURE_DATA:
//
// typedef struct _EFI_SIGNATURE_DATA {
//     EFI_GUID SignatureOwner;
//     UINT8 SignatureData[...];
// } EFI_SIGNATURE_DATA;
//
// typedef struct UEFI_IMAGE_LOAD_EVENT {
//     EFI_PHYSICAL_ADDRESS ImageLocationInMemory; // PE/COFF image
//     UINT64 ImageLengthInMemory;
//     UINT64 ImageLinkTimeAddress;
//     UINT64 LengthOfDevicePath;
//     BYTE DevicePath[LengthOfDevicePath];
//                // See UEFI spec Section EFI Device Path Protocol
//                // for the encodings for DevicePath.
// } UEFI_IMAGE_LOAD_EVENT;

/// Records the authority that approved an image in PCR 7, the same way the
/// firmware records its own Secure Boot keys.
pub fn authority(tcg: &mut Tcg, identity: &[u8]) -> CommandResult<()> {
    // Package event data using UEFI_VARIABLE_DATA for event of type
    // EV_EFI_VARIABLE_AUTHORITY.
    let record = encode_variable_data(AUTHORITY_NAME, identity);

    // TCG PC Client Platform Firmware Profile specification, revision 1.06:
    // Description of EV_EFI_VARIABLE_AUTHORITY:
    // Used for PCR[7] only
    // ...
    // The event field MUST contain a
    // UEFI_VARIABLE_DATA structure where the
    // VariableData field contains the
    // EFI_SIGNATURE_DATA value from the
    // EFI_SIGNATURE_LIST used to validate the
    // loaded image.
    //
    // We are not conforming to the specification here, because we are passing
    // a GUID inside UEFI_VARIABLE_DATA rather than EFI_SIGNATURE_DATA.
    // Please note that other bootloaders, such as shim, similarly measure
    // non-conformant data as EV_EFI_VARIABLE_AUTHORITY (e.g. SbatLevel).

    tpm::extend(
        tcg,
        Extension {
            pcr: tpm::PCR_7,
            event_type: EventType::EFI_VARIABLE_AUTHORITY,
            logged: &record,
            hashed: &record,
            flags: HashLogExtendEventFlags::empty(),
        },
    )
}

/// Records the certificate with which an authority approved an image in
/// PCR 14. The event log gets the same bytes, so a verifier can check the
/// certificate against the PCR.
pub fn certificate(
    tcg: &mut Tcg,
    identity: &[u8],
    certificate: &[u8],
) -> CommandResult<()> {
    let record = encode_certificate_record(identity, certificate);

    // EV_EFI_VARIABLE_AUTHORITY is meant for PCR 7, but event log tools show
    // its EFI_SIGNATURE_DATA as an owner and a certificate in any PCR.
    tpm::extend(
        tcg,
        Extension {
            pcr: tpm::PCR_14,
            event_type: EventType::EFI_VARIABLE_AUTHORITY,
            logged: &record,
            hashed: &record,
            flags: HashLogExtendEventFlags::empty(),
        },
    )
}

/// Returns a UEFI_VARIABLE_DATA holding an EFI_SIGNATURE_DATA with the
/// authority identity as the owner.
fn encode_certificate_record(identity: &[u8], certificate: &[u8]) -> Vec<u8> {
    let mut signature = Vec::new();
    signature.extend_from_slice(identity);
    signature.extend_from_slice(certificate);
    encode_variable_data(CERTIFICATE_NAME, &signature)
}

/// Returns a UEFI_VARIABLE_DATA with the specified name and data.
fn encode_variable_data(name: &CStr16, data: &[u8]) -> Vec<u8> {
    let name = name.as_slice();
    let mut record = Vec::new();
    record.extend_from_slice(AUTHORITY_OWNER.to_bytes().as_slice());
    record.extend_from_slice(&(name.len() as u64).to_le_bytes());
    record.extend_from_slice(&(data.len() as u64).to_le_bytes());
    // Convert from CStr16 characters to u16 characters.
    for character in name {
        record.extend_from_slice(&u16::from(*character).to_le_bytes());
    }
    record.extend_from_slice(data);
    record
}

/// Records an image that is about to run in PCR 4, the same way the firmware
/// records the images it loads. PCR 4 gets the image hash, and the event log
/// gets the image location, size and device path.
pub fn image(
    tcg: &mut Tcg,
    image: &[u8],
    link_time_address: u64,
    device_path: &[u8],
) -> CommandResult<()> {
    // Package event data as UEFI_IMAGE_LOAD_EVENT.
    let mut record = Vec::new();
    record.extend_from_slice(&(image.as_ptr() as u64).to_le_bytes());
    record.extend_from_slice(&(image.len() as u64).to_le_bytes());
    record.extend_from_slice(&link_time_address.to_le_bytes());
    record.extend_from_slice(&(device_path.len() as u64).to_le_bytes());
    record.extend_from_slice(device_path);

    let request = Extension {
        pcr: tpm::PCR_4,
        event_type: EventType::EFI_BOOT_SERVICES_APPLICATION,
        logged: &record,
        hashed: image,
        flags: HashLogExtendEventFlags::PE_COFF_IMAGE,
    };
    match tpm::extend(tcg, request) {
        Err(CommandError::Transport(Status::UNSUPPORTED)) => {}
        result => return result,
    }

    // Some older firmware cannot hash a PE image.
    // Hash the raw bytes instead of stopping the boot.
    verification!("the firmware failed to hash a PE image, hashing its bytes");
    flat_image(tcg, &record, image)
}

/// Records a flat hash over the specified image.
fn flat_image(
    tcg: &mut Tcg,
    image_load_event: &[u8],
    image: &[u8],
) -> CommandResult<()> {
    let mut record = Vec::new();
    record.extend_from_slice(&FLAT_IMAGE_EVENT_ID.to_le_bytes());
    record.extend_from_slice(&(image_load_event.len() as u32).to_le_bytes());
    record.extend_from_slice(image_load_event);

    tpm::extend(
        tcg,
        Extension {
            pcr: tpm::PCR_4,
            event_type: EventType::EVENT_TAG,
            logged: &record,
            hashed: image,
            flags: HashLogExtendEventFlags::empty(),
        },
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    const IDENTITY: [u8; 16] =
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    const CERTIFICATE: &[u8] = b"certificate in DER form";

    /// The fixed part of UEFI_VARIABLE_DATA before the name: the vendor GUID
    /// and the two lengths.
    const HEADER_LENGTH: usize = 16 + 8 + 8;

    #[test]
    fn certificate_record_starts_with_owner_and_variable_name() {
        let record = encode_certificate_record(&IDENTITY, CERTIFICATE);
        let name = encode_utf16_le("SlabCertificate");

        assert_eq!(record[..16], AUTHORITY_OWNER.to_bytes());
        assert_eq!(read_u64(&record, 16), name.len() as u64 / 2);
        assert_eq!(record[HEADER_LENGTH..HEADER_LENGTH + name.len()], name);
    }

    #[test]
    fn certificate_record_holds_identity_and_certificate_as_signature_data() {
        let record = encode_certificate_record(&IDENTITY, CERTIFICATE);
        let data =
            &record[HEADER_LENGTH + encode_utf16_le("SlabCertificate").len()..];

        assert_eq!(read_u64(&record, 24), data.len() as u64);
        assert_eq!(data[..16], IDENTITY);
        assert_eq!(&data[16..], CERTIFICATE);
    }

    #[test]
    fn authority_record_holds_owner_variable_name_and_identity() {
        let record = encode_variable_data(AUTHORITY_NAME, &IDENTITY);
        let name = encode_utf16_le("SlabAuthority");

        assert_eq!(record[..16], AUTHORITY_OWNER.to_bytes());
        assert_eq!(read_u64(&record, 16), name.len() as u64 / 2);
        assert_eq!(read_u64(&record, 24), IDENTITY.len() as u64);
        assert_eq!(record[HEADER_LENGTH..HEADER_LENGTH + name.len()], name);
        assert_eq!(record[HEADER_LENGTH + name.len()..], IDENTITY);
    }

    /// Returns the text as little endian UTF-16 bytes, without a terminator.
    fn encode_utf16_le(text: &str) -> Vec<u8> {
        text.encode_utf16().flat_map(u16::to_le_bytes).collect()
    }

    /// Reads a little endian u64 at the offset.
    fn read_u64(bytes: &[u8], offset: usize) -> u64 {
        u64::from_le_bytes(bytes[offset..offset + 8].try_into().unwrap())
    }
}

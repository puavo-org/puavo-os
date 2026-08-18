//! Implements recording of authorities and images by measuring them using TPM.

use crate::tpm::{self, CommandResult, Extension};
use alloc::vec::Vec;
use uefi::proto::tcg::EventType;
use uefi::proto::tcg::v2::{HashLogExtendEventFlags, Tcg};
use uefi::{CStr16, Guid, cstr16, guid};

const AUTHORITY_NAME: &CStr16 = cstr16!("SlabAuthority");
const AUTHORITY_OWNER: Guid = guid!("af20bc5d-65ab-4c7c-80b4-b4efbf5ba588");

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
// typedef struct UEFI_IMAGE_LOAD_EVENT {
//     EFI_PHYSICAL_ADDRESS ImageLocationInMemory; // PE/COFF image
//     UINT64 ImageLengthInMemory;
//     UINT64 ImageLinkTimeAddress;
//     UINT64 LengthOfDevicePath;
//     BYTE DevicePath[LengthOfDevicePath];
//                // See UEFI spec Section EFI Device Path Protocol
//                // for the encodings for DevicePath.
// } UEFI_IMAGE_LOAD_EVENT;

/// Records who allowed an image to run, the way the machine records the same
/// thing about the keys it holds itself.
pub fn authority(tcg: &mut Tcg, identity: &[u8]) -> CommandResult<()> {
    // Package event data using UEFI_VARIABLE_DATA for event of type
    // EV_EFI_VARIABLE_AUTHORITY.
    let mut record = Vec::new();
    record.extend_from_slice(AUTHORITY_OWNER.to_bytes().as_slice());
    let name = AUTHORITY_NAME.as_slice();
    record.extend_from_slice(&(name.len() as u64).to_le_bytes());
    record.extend_from_slice(&(identity.len() as u64).to_le_bytes());
    // Convert from CStr16 characters to u16 characters.
    for character in name {
        record.extend_from_slice(&u16::from(*character).to_le_bytes());
    }
    record.extend_from_slice(identity);

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

/// Records an image the machine is about to run, where the machine keeps the
/// images it loads itself. What lands in PCR 4 is the hash of the program, and
/// the record beside it says which image it was and where it came from.
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

    tpm::extend(
        tcg,
        Extension {
            pcr: tpm::PCR_4,
            event_type: EventType::EFI_BOOT_SERVICES_APPLICATION,
            logged: &record,
            hashed: image,
            flags: HashLogExtendEventFlags::PE_COFF_IMAGE,
        },
    )
}

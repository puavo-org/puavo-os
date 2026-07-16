//! Image verification protocol for the next stage.
//! Using the verification function, the next stage can apply the
//! revocation list to the images it loads.
//! Signatures are not checked here, because the next stage is
//! expected to chainload, which loads it through the firmware and
//! triggers the Secure Boot signature check.

use crate::pe;
use crate::revocations::{self, VERSION_SECTION_NAME};
use core::ffi::c_void;
use uefi::{boot, guid, Guid, Status};

/// The protocol identity the next stage looks up.
const PROTOCOL_GUID: Guid = guid!("605dab50-e046-4300-abb6-3dd810dd8b23");

#[repr(C)]
struct Protocol {
    verify: extern "sysv64" fn(buffer: *const c_void, size: u32) -> Status,
    hash: extern "sysv64" fn(
        data: *const c_void,
        data_size: u32,
        pe_context: *mut c_void,
        sha256_digest: *mut u8,
        sha1_digest: *mut u8,
    ) -> Status,
    context: extern "sysv64" fn(
        data: *const c_void,
        data_size: u32,
        pe_context: *mut c_void,
    ) -> Status,
}

static PROTOCOL: Protocol = Protocol { verify, hash, context };

/// Installs the protocol on a new handle.
pub fn install() -> bool {
    let interface = &PROTOCOL as *const Protocol as *const c_void;
    // SAFETY: The static protocol table stays valid as long as
    // this bootloader is loaded in memory. The next stage, which
    // the firmware authenticates, is expected to be conformant
    // and leave this bootloader in place.
    unsafe {
        boot::install_protocol_interface(None, &PROTOCOL_GUID, interface)
    }
    .is_ok()
}

/// Applies the revocation list to one image. An image that declares a
/// component identity must meet its list minimum. An image that declares
/// none is allowed, because a signed image cannot fake its identity without
/// breaking its signature, and images outside the scheme, such as other
/// operating systems, must keep booting.
extern "sysv64" fn verify(buffer: *const c_void, size: u32) -> Status {
    if buffer.is_null() {
        return Status::INVALID_PARAMETER;
    }
    // SAFETY: We trust the caller, because the firmware already
    // authenticated it, and we construct a bounded slice.
    let image = unsafe {
        core::slice::from_raw_parts(buffer as *const u8, size as usize)
    };

    let Some(section) = pe::read_section(image, VERSION_SECTION_NAME) else {
        debug!("image declares no version, allowing");
        return Status::SUCCESS;
    };
    let Some((name, version)) = revocations::parse_identity(section) else {
        error!("image identity malformed, refusing");
        return Status::SECURITY_VIOLATION;
    };
    match revocations::minimum_version(name) {
        Some(minimum) if version < minimum => {
            security_violation!(
                "image version {version} below minimum {minimum}, refusing"
            );
            Status::SECURITY_VIOLATION
        }
        _ => {
            debug!("image version {version} allowed");
            Status::SUCCESS
        }
    }
}

/// Not provided, callers bring their own hashing.
extern "sysv64" fn hash(
    _data: *const c_void,
    _data_size: u32,
    _pe_context: *mut c_void,
    _sha256_digest: *mut u8,
    _sha1_digest: *mut u8,
) -> Status {
    Status::UNSUPPORTED
}

/// Not provided, callers bring their own PE parsing.
extern "sysv64" fn context(
    _data: *const c_void,
    _data_size: u32,
    _pe_context: *mut c_void,
) -> Status {
    Status::UNSUPPORTED
}

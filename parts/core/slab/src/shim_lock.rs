//! Image verification protocol for the next stage. It checks images against
//! Secure Boot and the revocation list.
//!
//! The signature check is delegated to the firmware verifier. Some callers
//! rely on this check as their only defense.

use crate::pe;
use crate::revocations::{self, VERSION_SECTION_NAME};
use core::ffi::c_void;
use core::ptr::NonNull;
use core::sync::atomic::{AtomicPtr, Ordering};
use uefi::boot::{self, OpenProtocolAttributes, OpenProtocolParams};
use uefi::proto::unsafe_protocol;
use uefi::runtime::{self, VariableVendor};
use uefi::{Guid, Status, cstr16, guid};

/// The protocol identity the next stage looks up.
const PROTOCOL_GUID: Guid = guid!("605dab50-e046-4300-abb6-3dd810dd8b23");

/// The installed shim lock interface. The UEFI crate can only call this
/// protocol, not install it, so it is defined here.
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

/// The firmware Secure Boot verifier. The UEFI crate does not provide it. The
/// device path is optional.
type FileAuthentication = unsafe extern "efiapi" fn(
    this: *const Security2,
    device_path: Option<NonNull<c_void>>,
    file_buffer: *const c_void,
    file_size: usize,
    boot_policy: u8,
) -> Status;

#[repr(C)]
#[unsafe_protocol("94ab2f58-1438-4ef1-9152-18941a3a0e68")]
struct Security2 {
    file_authentication: FileAuthentication,
}

/// The firmware verifier, captured once at startup and read later. The wrapper
/// keeps out null pointers and can be stored safely in a shared global.
struct Verifier {
    instance: AtomicPtr<Security2>,
    authentication: AtomicPtr<c_void>,
}

impl Verifier {
    const fn empty() -> Self {
        Self {
            instance: AtomicPtr::new(core::ptr::null_mut()),
            authentication: AtomicPtr::new(core::ptr::null_mut()),
        }
    }

    fn store(
        &self,
        instance: NonNull<Security2>,
        authentication: FileAuthentication,
    ) {
        self.authentication
            .store(authentication as *mut c_void, Ordering::Relaxed);
        self.instance.store(instance.as_ptr(), Ordering::Relaxed);
    }

    fn load(&self) -> Option<(NonNull<Security2>, FileAuthentication)> {
        let instance = NonNull::new(self.instance.load(Ordering::Relaxed))?;
        let address =
            NonNull::new(self.authentication.load(Ordering::Relaxed))?;
        // SAFETY: this address was saved from a real verification function, so
        // turning it back into one is valid.
        let authentication: FileAuthentication =
            unsafe { core::mem::transmute(address.as_ptr()) };
        Some((instance, authentication))
    }
}

static VERIFIER: Verifier = Verifier::empty();

/// Captures the firmware Secure Boot verifier, then installs the protocol.
/// Returns whether the protocol was installed.
pub fn initialize() -> bool {
    capture_firmware_verifier();
    install()
}

/// Installs this protocol on a new handle.
fn install() -> bool {
    let interface = &PROTOCOL as *const Protocol as *const c_void;
    // SAFETY: The static protocol table stays valid as long as this bootloader
    // is loaded in memory. The next stage, which the firmware authenticates, is
    // expected to be conformant and leave this bootloader in place.
    unsafe { boot::install_protocol_interface(None, &PROTOCOL_GUID, interface) }
        .is_ok()
}

/// Later stages might replace the verification implementation with their own.
/// This function records the firmware Secure Boot verifier so the verification
/// function can enforce signatures on images that later stages load.
fn capture_firmware_verifier() {
    let Ok(handle) = boot::get_handle_for_protocol::<Security2>() else {
        debug!("no firmware Secure Boot verifier present");
        return;
    };
    let open_parameters = OpenProtocolParams {
        handle,
        agent: boot::image_handle(),
        controller: None,
    };
    // SAFETY: We snapshot the function and instance address, which are
    // expected to remain valid for the rest of the boot.
    let opened = unsafe {
        boot::open_protocol::<Security2>(
            open_parameters,
            OpenProtocolAttributes::GetProtocol,
        )
    };
    let Ok(security2) = opened else {
        debug!("failed to open the firmware Secure Boot verifier");
        return;
    };
    let Some(firmware) = security2.get() else {
        debug!("firmware Secure Boot verifier interface is null");
        return;
    };
    // Save the firmware verifier and its instance address. Closing the handle
    // below does not free them, because the firmware keeps this verifier for
    // the whole boot. The verifier is saved now, before a later stage can
    // replace it.
    VERIFIER.store(NonNull::from(firmware), firmware.file_authentication);
    debug!("captured firmware Secure Boot verifier");
}

/// Whether the firmware reports Secure Boot as enabled.
fn secure_boot_enabled() -> bool {
    let mut value = [0u8; 1];
    runtime::get_variable(
        cstr16!("SecureBoot"),
        &VariableVendor::GLOBAL_VARIABLE,
        &mut value,
    )
    .map(|(data, _)| data.first() == Some(&1))
    .unwrap_or(false)
}

/// Performs Secure Boot verification on the specified image.
/// Returns success when the firmware trusts it or Secure Boot is off.
fn firmware_authenticates(buffer: *const c_void, size: u32) -> Status {
    // Attempt to fetch the captured firmware verifier.
    // It might not be available depending on Secure Boot capabilities,
    // allow it only if Secure Boot is not enabled.
    let Some((security2, authenticate)) = VERIFIER.load() else {
        return if secure_boot_enabled() {
            Status::SECURITY_VIOLATION
        } else {
            Status::SUCCESS
        };
    };
    // SAFETY: The captured verifier stays valid for the whole boot and only
    // reads the buffer. No device path means unknown origin, which the
    // firmware denies rather than trusts.
    unsafe { authenticate(security2.as_ptr(), None, buffer, size as usize, 0) }
}

/// Performs Secure Boot verification and applies the revocation list to the
/// specified image. An image that declares a component identity must meet its
/// list minimum. An image that declares none is allowed past the revocation
/// step, because a signed image cannot fake its identity, and images outside
/// the scheme, such as other operating systems, must keep booting.
extern "sysv64" fn verify(buffer: *const c_void, size: u32) -> Status {
    let status = firmware_authenticates(buffer, size);
    if status != Status::SUCCESS {
        security_violation!(
            "image failed Secure Boot verification ({status:?}), refusing"
        );
        return status;
    }

    // The firmware rejects a null image, but with Secure Boot off it is never
    // called, so guard the image before reading it as a slice below.
    if buffer.is_null() {
        error!("image buffer was a null pointer, refusing");
        return Status::INVALID_PARAMETER;
    }

    // SAFETY: the image is not null and the caller gives its length in bytes.
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

//! Image verification protocol for the next stage. It checks images against
//! Secure Boot and the revocation list.
//!
//! The signature check is first delegated to the optional built-in verifier
//! and then to the firmware verifier.

use crate::pe;
use crate::revocations::{self, VERSION_SECTION_NAME};
use core::ffi::c_void;
use core::ptr::NonNull;
use core::sync::atomic::{AtomicPtr, Ordering};
use uefi::boot::{
    self, OpenProtocolAttributes, OpenProtocolParams, SearchType,
};
#[cfg(feature = "verifier")]
use uefi::proto::device_path::DevicePath;
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
struct FirmwareVerifier {
    instance: AtomicPtr<Security2>,
    authentication: AtomicPtr<c_void>,
}

impl FirmwareVerifier {
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

static FIRMWARE_VERIFIER: FirmwareVerifier = FirmwareVerifier::empty();

/// Whether this protocol is already there, which means an earlier instance of
/// this bootloader is the one deciding and has done to the machine everything
/// that comes with it.
pub fn installed_already() -> bool {
    boot::locate_handle_buffer(SearchType::ByProtocol(&PROTOCOL_GUID)).is_ok()
}

/// Captures the firmware Secure Boot verifier, then installs the protocol.
/// Returns whether the protocol was installed.
pub fn initialize() -> bool {
    capture_firmware_verifier();
    decide_from_now_on();
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
    FIRMWARE_VERIFIER
        .store(NonNull::from(firmware), firmware.file_authentication);
    debug!("captured firmware Secure Boot verifier");
}

/// Installs the built-in Secure Boot verifier in place of the firmware provided one.
#[cfg(feature = "verifier")]
fn decide_from_now_on() {
    let Some((interface, _)) = FIRMWARE_VERIFIER.load() else {
        error!("no verifier to stand in for, the machine keeps deciding");
        return;
    };
    // SAFETY: The interface belongs to the firmware, which keeps it for the
    // whole boot, and only the one function it holds is written.
    unsafe {
        (*interface.as_ptr()).file_authentication = decide_for_firmware;
    }
    debug!("verifier has been installed");
    crate::verifier::describe();
}

#[cfg(not(feature = "verifier"))]
fn decide_from_now_on() {}

/// The answer given to the firmware when it is about to load an image.
#[cfg(feature = "verifier")]
unsafe extern "efiapi" fn decide_for_firmware(
    _this: *const Security2,
    device_path: Option<NonNull<c_void>>,
    file_buffer: *const c_void,
    file_size: usize,
    _boot_policy: u8,
) -> Status {
    if file_buffer.is_null() || file_size == 0 {
        security_violation!("an image with no contents, refusing");
        return Status::SECURITY_VIOLATION;
    }
    let Ok(size) = u32::try_from(file_size) else {
        security_violation!("image of {file_size} bytes too large, refusing");
        return Status::SECURITY_VIOLATION;
    };

    // SAFETY: The device path, when there is one, is the one the firmware is
    // about to load from, and it stays valid for the length of this call.
    let path = device_path
        .map(|path| unsafe { DevicePath::from_ffi_ptr(path.as_ptr().cast()) })
        .map(DevicePath::as_bytes)
        .unwrap_or_default();

    decide(file_buffer, size, path)
}

/// Whether the keys carried here accept the image, which is also where such an
/// image gets into the machine's account of the boot.
#[cfg(feature = "verifier")]
fn built_in_keys_accept(image: &[u8], device_path: &[u8]) -> bool {
    crate::verifier::trusts(image, device_path)
}

/// When the built-in verifier is disabled, we only trust the firmware.
#[cfg(not(feature = "verifier"))]
fn built_in_keys_accept(_image: &[u8], _device_path: &[u8]) -> bool {
    false
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
fn firmware_authenticates(
    buffer: *const c_void,
    size: u32,
    device_path: &[u8],
) -> Status {
    // Attempt to fetch the captured firmware verifier.
    // It might not be available depending on Secure Boot capabilities,
    // allow it only if Secure Boot is not enabled.
    let Some((security2, authenticate)) = FIRMWARE_VERIFIER.load() else {
        return if secure_boot_enabled() {
            Status::SECURITY_VIOLATION
        } else {
            Status::SUCCESS
        };
    };

    let origin = if device_path.is_empty() {
        None
    } else {
        NonNull::new(device_path.as_ptr().cast_mut().cast())
    };

    // SAFETY: The captured verifier stays valid for the whole boot and only
    // reads the buffer and the device path, both of which outlive the call.
    unsafe {
        authenticate(security2.as_ptr(), origin, buffer, size as usize, 0)
    }
}

/// Whether anything answered for here accepts the image: the keys built in, and
/// then the machine.
///
/// A machine that accepts an image also records it, both the image and the key
/// that let it through, so both are recorded for an image accepted here.
fn signature_accepted(
    buffer: *const c_void,
    size: u32,
    device_path: &[u8],
) -> Status {
    // The built in keys are asked first, because they answer for what we sign,
    // and asking the machine about an image it was never given the key for
    // costs a full search of its key store before it says no.
    if !buffer.is_null() {
        // SAFETY: the image is not null and the caller gives its length.
        let image = unsafe {
            core::slice::from_raw_parts(buffer as *const u8, size as usize)
        };
        if built_in_keys_accept(image, device_path) {
            verification!("accepted by a key built in here");
            return Status::SUCCESS;
        }
    }

    let status = firmware_authenticates(buffer, size, device_path);
    if status == Status::SUCCESS {
        verification!("accepted by the machine");
    }
    status
}

/// The answer to a caller asking through this protocol, which is the same
/// answer the firmware is given.
extern "sysv64" fn verify(buffer: *const c_void, size: u32) -> Status {
    // A caller asking through the protocol says nothing about where the image
    // came from, so there is no device path to record.
    decide(buffer, size, &[])
}

/// The one answer given about an image, whoever asks for it. The device path
/// says where the image came from, for callers that know.
fn decide(buffer: *const c_void, size: u32, device_path: &[u8]) -> Status {
    debug!("deciding about an image of {size} bytes");

    let status = signature_accepted(buffer, size, device_path);
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

    if !version_allowed(image) {
        return Status::SECURITY_VIOLATION;
    }

    Status::SUCCESS
}

/// Whether the image meets the revocation list minimum. An image that declares
/// no version is allowed past this, because a signed image cannot fake its
/// identity, and images outside the scheme, such as other operating systems,
/// must keep booting. A component the list does not name has no floor.
fn version_allowed(image: &[u8]) -> bool {
    let Some(section) = pe::read_section(image, VERSION_SECTION_NAME) else {
        verification!("image declares no version, allowing");
        return true;
    };
    let Some((name, version)) = revocations::parse_identity(section) else {
        error!("image identity malformed, refusing");
        return false;
    };
    match revocations::minimum_version(name) {
        Some(minimum) if version < minimum => {
            security_violation!(
                "image version {version} below minimum {minimum}, refusing"
            );
            false
        }
        _ => {
            verification!("image version {version} allowed");
            true
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

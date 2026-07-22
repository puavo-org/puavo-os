//! Loading and handing off to the next stage. Slab reads the next stage,
//! checks its version against the revocation list, then loads and starts
//! the exact bytes it checked.

use crate::pe;
use crate::revocations::{self, VERSION_SECTION_NAME};
use alloc::vec::Vec;
use core::mem::MaybeUninit;
use uefi::boot::{self, LoadImageSource};
use uefi::fs::{FileSystem, Path};
use uefi::proto::device_path::build::media::FilePath;
use uefi::proto::device_path::build::DevicePathBuilder;
use uefi::proto::loaded_image::LoadedImage;
use uefi::{cstr16, CStr16, Handle, Status};
use uefi_raw::protocol::loaded_image::LoadedImageProtocol;

/// The next stage slab hands control to.
const NEXT_STAGE_PATH: &CStr16 = cstr16!("\\EFI\\puavo\\grub\\grubx64.efi");
/// Bytes reserved for building the next stage device path.
const DEVICE_PATH_BUFFER_SIZE: usize = 128;

/// Reads the next stage from the partition slab was loaded from.
/// Returns `None` when it is absent or unreadable.
pub fn read() -> Option<Vec<u8>> {
    let file_system = boot::get_image_file_system(boot::image_handle()).ok()?;
    let mut file_system = FileSystem::new(file_system);
    file_system.read(Path::new(NEXT_STAGE_PATH)).ok()
}

/// Returns whether the next stage meets the revocation list minimum.
/// A stage that declares no version is refused.
/// A component the list does not name has no floor.
pub fn is_allowed(image: &[u8]) -> bool {
    let Some(section) = pe::read_section(image, VERSION_SECTION_NAME) else {
        security_violation!("next stage declares no version, refusing");
        return false;
    };
    let Some((name, version)) = revocations::parse_identity(section) else {
        error!("next stage identity malformed, refusing");
        return false;
    };
    match revocations::minimum_version(name) {
        Some(minimum) if version < minimum => {
            security_violation!(
                "next stage version {version} below minimum {minimum}, refusing"
            );
            false
        }
        _ => {
            debug!("next stage version {version} allowed");
            true
        }
    }
}

/// Loads the exact buffer slab checked, so the bytes cannot change between the
/// check and the load, and starts it.
pub fn start(image: &[u8]) -> Result<(), Status> {
    let mut path_buffer = [MaybeUninit::uninit(); DEVICE_PATH_BUFFER_SIZE];
    let file_path = DevicePathBuilder::with_buf(&mut path_buffer)
        .push(&FilePath {
            path_name: NEXT_STAGE_PATH,
        })
        .ok()
        .and_then(|builder| builder.finalize().ok());

    // The next stage runs from this buffer, the file path only
    // lets it learn the directory it was loaded from.
    let handle = boot::load_image(
        boot::image_handle(),
        LoadImageSource::FromBuffer {
            buffer: image,
            file_path,
        },
    )
    .map_err(|error| error.status())?;

    // Point the next stage at the device slab was loaded from.
    set_device(handle);

    // Hand control to the next stage.
    boot::start_image(handle).map_err(|error| error.status())
}

/// Points the next stage at the device slab was loaded from. Firmware leaves
/// the device unset for a buffer load, so without this the next stage cannot
/// find where it was loaded from. This is the one place slab writes a firmware
/// structure directly.
fn set_device(handle: Handle) {
    let device =
        boot::open_protocol_exclusive::<LoadedImage>(boot::image_handle())
            .ok()
            .and_then(|slab| slab.device());
    let Some(device) = device else {
        debug!("slab has no device handle, next stage may not find its files");
        return;
    };

    let Ok(loaded) = boot::open_protocol_exclusive::<LoadedImage>(handle) else {
        debug!("cannot open the next stage image to set its device");
        return;
    };

    // SAFETY: Unfortunately, in order to access the fields of
    // LoadedImageProtocol, we have to cast using pointers.
    // LoadedImage and LoadedImageProtocol have identical
    // structure due to repr(transparent).
    let raw = &*loaded as *const LoadedImage as *mut LoadedImageProtocol;
    unsafe {
        (*raw).device_handle = device.as_ptr();
    }
}

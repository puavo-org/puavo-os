//! Loading and handing off to the next stage. Slab reads the next stage,
//! checks its version against the revocation list, then loads and starts
//! the exact bytes it checked.

use crate::pe;
use crate::revocations::{self, VERSION_SECTION_NAME};
use alloc::vec::Vec;
use core::mem::MaybeUninit;
use core::ptr;
use uefi::boot::{
    self, LoadImageSource, OpenProtocolAttributes, OpenProtocolParams,
};
use uefi::fs::{FileSystem, Path};
use uefi::proto::device_path::build::DevicePathBuilder;
use uefi::proto::device_path::build::media::FilePath;
use uefi::proto::loaded_image::LoadedImage;
use uefi::proto::network::IpAddress;
use uefi::proto::network::pxe::{self, DhcpV4Packet};
use uefi::{CStr8, CStr16, Handle, Status, cstr8, cstr16};
use uefi_raw::Boolean;
use uefi_raw::protocol::loaded_image::LoadedImageProtocol;
use uefi_raw::protocol::network::pxe::{
    PxeBaseCodeProtocol, PxeBaseCodeTftpOpcode,
};

/// The next stage slab hands control to.
const NEXT_STAGE_PATH: &CStr16 = cstr16!("\\EFI\\puavo\\grub\\grubx64.efi");
/// The path of the next stage on the server.
const NEXT_STAGE_SERVER_PATH: &CStr8 = cstr8!("EFI/puavo/grub/grubx64.efi");
/// Bytes reserved for building the next stage device path.
const DEVICE_PATH_BUFFER_SIZE: usize = 128;
/// Largest next stage slab accepts, since the server decides the size.
const NEXT_STAGE_SIZE_LIMIT: usize = 64 * 1024 * 1024;
/// Block size asked for when reading from a server. Servers commonly answer
/// the size of a file only to a client that also asks for a block size.
const NEXT_STAGE_BLOCK_SIZE: usize = 1468;

/// Reads the next stage from partition or network.
/// Returns `None` when it is absent or unreadable.
pub fn read() -> Option<Vec<u8>> {
    match device() {
        Some(device) if is_network(device) => read_from_server(device),
        _ => read_from_partition(),
    }
}

/// Reads the next stage from the partition.
fn read_from_partition() -> Option<Vec<u8>> {
    let file_system = boot::get_image_file_system(boot::image_handle()).ok()?;
    let mut file_system = FileSystem::new(file_system);
    file_system.read(Path::new(NEXT_STAGE_PATH)).ok()
}

/// Reads the next stage from the server.
fn read_from_server(device: Handle) -> Option<Vec<u8>> {
    let mut base = open_network_protocol(device)?;
    let server = server_address(&base)?;

    // If the server does not answer how large the next stage file is,
    // allocate largest allowed buffer for it.
    let size = match file_size(&mut base, &server) {
        Ok(size) => usize::try_from(size).ok()?,
        Err(status) => {
            error!(
                "next stage size unavailable ({status:?}), allocating largest allowed buffer"
            );
            NEXT_STAGE_SIZE_LIMIT
        }
    };
    if size > NEXT_STAGE_SIZE_LIMIT {
        error!("next stage of {size} bytes is too large, refusing");
        return None;
    }

    // Attempt allocating the buffer for receiving the next stage.
    let mut image = Vec::new();
    if image.try_reserve_exact(size).is_err() {
        error!("failed to reserve {size} bytes for the next stage");
        return None;
    }
    image.resize(size, 0);

    let read = base
        .tftp_read_file(&server, NEXT_STAGE_SERVER_PATH, Some(&mut image))
        .inspect_err(|error| error!("next stage unreadable: {error:?}"))
        .ok()?;
    image.truncate(usize::try_from(read).ok()?);

    debug!("read {read} bytes of next stage from the server");
    Some(image)
}

/// Asks the server how large the next stage is.
fn file_size(
    base: &mut pxe::BaseCode,
    server: &IpAddress,
) -> Result<u64, Status> {
    let mut size = 0;
    let block_size = NEXT_STAGE_BLOCK_SIZE;

    let protocol: *mut PxeBaseCodeProtocol = ptr::from_mut(base).cast();

    // SAFETY: The pointer comes from a borrow that outlives the call, the
    // path is static, and the rest borrow locals of this function. The
    // firmware writes only through the size.
    let status = unsafe {
        let mtftp = (*protocol).mtftp;
        mtftp(
            protocol,
            PxeBaseCodeTftpOpcode::TFTP_GET_FILE_SIZE,
            // No buffer, the size is all this asks for.
            ptr::null_mut(),
            // Overwriting concerns writing a file.
            Boolean::FALSE,
            &mut size,
            &block_size,
            (server as *const IpAddress).cast(),
            NEXT_STAGE_SERVER_PATH.as_ptr().cast(),
            // Multicast settings, which a plain read does not need.
            ptr::null(),
            // The buffer is skipped by leaving it out, not by this.
            Boolean::FALSE,
        )
    };

    if status.is_success() { Ok(size) } else { Err(status) }
}

/// Returns whether the handle reaches the network.
fn is_network(device: Handle) -> bool {
    open_network_protocol(device).is_some()
}

/// Opens the network protocol without taking it from the firmware, which
/// keeps using it while slab reads.
fn open_network_protocol(
    device: Handle,
) -> Option<boot::ScopedProtocol<pxe::BaseCode>> {
    let parameters = OpenProtocolParams {
        handle: device,
        agent: boot::image_handle(),
        controller: None,
    };

    // SAFETY: Nothing is taken from the firmware, which keeps using the
    // interface, and the interface stays usable for as long as the caller
    // keeps what this returns.
    unsafe {
        boot::open_protocol::<pxe::BaseCode>(
            parameters,
            OpenProtocolAttributes::GetProtocol,
        )
    }
    .ok()
}

/// Returns the device slab was loaded from.
fn device() -> Option<Handle> {
    boot::open_protocol_exclusive::<LoadedImage>(boot::image_handle())
        .ok()
        .and_then(|slab| slab.device())
}

/// Returns the address of the server that served this bootloader.
fn server_address(base: &pxe::BaseCode) -> Option<IpAddress> {
    let mode = base.mode();
    if !mode.dhcp_ack_received() {
        error!("no address configuration from the network, refusing");
        return None;
    }

    let acknowledgement: &DhcpV4Packet = mode.dhcp_ack().as_ref();
    Some(IpAddress::new_v4(acknowledgement.bootp_si_addr))
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
        .push(&FilePath { path_name: NEXT_STAGE_PATH })
        .ok()
        .and_then(|builder| builder.finalize().ok());

    // The next stage runs from this buffer, the file path only
    // lets it learn the directory it was loaded from.
    let handle = boot::load_image(
        boot::image_handle(),
        LoadImageSource::FromBuffer { buffer: image, file_path },
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
    let Some(device) = device() else {
        debug!("slab has no device handle, next stage may not find its files");
        return;
    };

    let opened = boot::open_protocol_exclusive::<LoadedImage>(handle);
    let Ok(mut loaded) = opened else {
        debug!("cannot open the next stage image to set its device");
        return;
    };
    let Some(loaded) = loaded.get_mut() else {
        debug!("next stage image interface is null");
        return;
    };

    // SAFETY: Unfortunately, in order to access the fields of
    // LoadedImageProtocol, we have to cast using pointers.
    // LoadedImage and LoadedImageProtocol have identical
    // structure due to repr(transparent).
    let raw = loaded as *mut LoadedImage as *mut LoadedImageProtocol;
    unsafe {
        (*raw).device_handle = device.as_ptr();
    }
}

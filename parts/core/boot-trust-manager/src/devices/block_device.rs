use std::ffi::CString;
use std::io;
use std::os::unix::ffi::OsStrExt;
use std::ptr;

use nix::libc::mount;
use udev::{Device, Enumerator};

/// Thin wrapper around a `udev::Device` that implements `BlockDevice` helpers.
pub struct GenericBlockDevice(Device);

impl GenericBlockDevice {
    /// Create a new `GenericBlockDevice` from a `udev::Device`.
    ///
    /// Parameters:
    /// - `device`: The underlying `udev::Device` representing a block device.
    pub fn new(device: Device) -> Self {
        Self(device)
    }
}

impl BlockDevice for GenericBlockDevice {
    fn block_device(&self) -> Device {
        self.0.clone()
    }
}

/// Common operations for block devices discoverable via udev.
pub trait BlockDevice {
    /// Return the underlying `udev::Device` for this block device.
    fn block_device(&self) -> Device;

    /// Enumerate child block devices of this device using udev.
    ///
    /// Returns:
    /// - `Ok(Vec<Device>)` containing child devices (e.g., partitions).
    ///
    /// Errors:
    /// - Propagates errors from udev enumeration.
    fn child_block_devices(&self) -> io::Result<Vec<Device>> {
        let block_device = self.block_device();

        let mut enumerator = Enumerator::new()?;
        enumerator.match_subsystem("block")?;

        let parent_device_path = block_device.devpath().to_os_string();
        let child_block_devices = enumerator
            .scan_devices()?
            .filter(|device| {
                device.parent().map(|parent| parent.devpath().to_os_string())
                    == Some(parent_device_path.clone())
            })
            .collect();

        Ok(child_block_devices)
    }

    /// Mount this block device at `mountpoint` using the specified filesystem type.
    ///
    /// Parameters:
    /// - `mountpoint`: Target directory path where the filesystem will be mounted.
    /// - `filesystem_type`: Filesystem type (e.g. "vfat", "ext4").
    ///
    /// Errors:
    /// - Returns an error if the device node cannot be resolved via udev.
    /// - Returns the OS error from the underlying `mount` system call on failure.
    fn mount(&self, mountpoint: &str, filesystem_type: &str) -> io::Result<()> {
        let device = self.block_device();
        let device_path_bytes = device
            .devnode()
            .ok_or(io::Error::new(
                io::ErrorKind::NotFound,
                "Device node not found",
            ))?
            .as_os_str()
            .as_bytes();

        let device_path = CString::new(device_path_bytes).unwrap();
        let mountpoint = CString::new(mountpoint).unwrap();
        let filesystem_type = CString::new(filesystem_type).unwrap();

        let result = unsafe {
            mount(
                device_path.as_ptr(),
                mountpoint.as_ptr(),
                filesystem_type.as_ptr(),
                0,
                ptr::null(),
            )
        };

        if result == 0 { Ok(()) } else { Err(std::io::Error::last_os_error()) }
    }
}

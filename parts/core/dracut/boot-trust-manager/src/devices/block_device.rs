use std::ffi::CString;
use std::io;
use std::os::unix::ffi::OsStrExt;
use std::ptr;

use nix::libc::mount;
use udev::{Device, Enumerator};

pub struct GenericBlockDevice(Device);

impl GenericBlockDevice {
    pub fn new(device: Device) -> Self {
        Self(device)
    }
}

impl BlockDevice for GenericBlockDevice {
    fn block_device(&self) -> Device {
        self.0.clone()
    }
}

pub trait BlockDevice {
    fn block_device(&self) -> Device;

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

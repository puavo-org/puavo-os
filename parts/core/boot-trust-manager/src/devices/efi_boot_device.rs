use std::process::Command;

use log::debug;
use udev::Device;

use crate::{
    devices::block_device::BlockDevice, error::PuavoError,
    utils::udev::device_from_device_node_path,
};

/// Represents the EFI boot device for the current boot.
///
/// Wraps the underlying `udev::Device` corresponding to the disk that
/// provided the EFI partition used to boot this system.
/// Provides helpers for resolving EFI loader related information.
pub struct EFIBootDevice(Device);

impl EFIBootDevice {
    /// Return the block device corresponding to the currently booted EFI disk.
    ///
    /// Errors:
    /// - `PuavoError::IoError` if invoking the helper command fails to run.
    /// - `PuavoError::NoEFIBootDisk` if the helper can not determine
    ///   the EFI boot disk.
    /// - `PuavoError::IoError` in case of udev errors.
    pub fn current() -> Result<EFIBootDevice, PuavoError> {
        debug!("Locating the current EFI boot device");

        let output = Command::new("puavo-current-efi-boot-disk").output()?;

        if !output.status.success() {
            let error_message =
                String::from_utf8_lossy(&output.stderr).to_string();
            return Err(PuavoError::NoEFIBootDisk(error_message));
        }

        let boot_device_path =
            String::from_utf8_lossy(&output.stdout).trim().to_string();
        debug!("EFI boot device path: {}", boot_device_path);
        let boot_device = device_from_device_node_path(&boot_device_path)
            .map_err(PuavoError::IoError)?;
        Ok(EFIBootDevice(boot_device))
    }

    /// Create an instance from a specific device node path.
    ///
    /// Parameters:
    /// - `device_node_path`: Path to the device node (e.g., "/dev/sda").
    ///
    /// Errors:
    /// - `PuavoError::IoError` if the device cannot be found or accessed.
    pub fn from_device_node_path(
        device_node_path: String,
    ) -> Result<EFIBootDevice, PuavoError> {
        debug!("Creating EFI boot device from path: {}", device_node_path);
        let boot_device = device_from_device_node_path(device_node_path)
            .map_err(PuavoError::IoError)?;
        Ok(EFIBootDevice(boot_device))
    }
}

impl BlockDevice for EFIBootDevice {
    fn block_device(&self) -> Device {
        self.0.clone()
    }
}

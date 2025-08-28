use std::process::Command;

use log::debug;
use udev::Device;

use crate::{
    devices::block_device::BlockDevice, error::PuavoError,
    utils::udev::device_from_device_node_path,
};

pub struct EFIBootDevice(Device);

impl EFIBootDevice {
    pub fn current() -> Result<EFIBootDevice, PuavoError> {
        debug!("Locating the current EFI boot device");

        let output = Command::new("puavo-current-efi-boot-disk")
            .output()
            .map_err(|error| PuavoError::IoError(error))?;

        if !output.status.success() {
            let error_message =
                String::from_utf8_lossy(&output.stderr).to_string();
            return Err(PuavoError::ShellError(error_message));
        }

        let boot_device_path =
            String::from_utf8_lossy(&output.stdout).trim().to_string();
        debug!("EFI boot device path: {}", boot_device_path);
        let boot_device = device_from_device_node_path(&boot_device_path)
            .map_err(|error| PuavoError::IoError(error))?;
        Ok(EFIBootDevice(boot_device))
    }
}

impl BlockDevice for EFIBootDevice {
    fn block_device(&self) -> Device {
        self.0.clone()
    }
}

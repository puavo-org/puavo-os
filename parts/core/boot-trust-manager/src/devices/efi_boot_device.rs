use std::{
    fs,
    path::{Path, PathBuf},
    process::Command,
};

use log::debug;
use udev::Device;

use crate::{
    devices::block_device::BlockDevice, error::PuavoError,
    utils::udev::device_from_device_node_path,
};

pub const EFI_VARIABLE_FILESYSTEM_PATH: &str = "/sys/firmware/efi/efivars";

pub struct EFIBootDevice(Device);

impl EFIBootDevice {
    pub fn current() -> Result<EFIBootDevice, PuavoError> {
        debug!("Locating the current EFI boot device");

        let output = Command::new("puavo-current-efi-boot-disk").output()?;

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

    pub fn loader_path(mountpoint: &PathBuf) -> Result<PathBuf, PuavoError> {
        let efi_variables_directory = Self::mount_efi_variable_filesystem()?;
        let optional_loader_variable = efi_variables_directory
            .read_dir()?
            .into_iter()
            .filter_map(|entry_result| entry_result.ok())
            .filter(|entry| {
                entry
                    .file_name()
                    .to_string_lossy()
                    .starts_with("LoaderImageIdentifier-")
            })
            .next();

        let loader_variable_path = optional_loader_variable
            .ok_or(PuavoError::NotFound("EFI variables".to_string()))?
            .path();

        debug!("EFI loader variable path: {:?}", loader_variable_path);

        let loader_bytes = fs::read(&loader_variable_path)?;
        let filtered_loader_bytes: Vec<u8> = loader_bytes
            .into_iter()
            .skip(4) // Skip the 4-byte attribute header
            .filter(|byte| *byte != 0 && !byte.is_ascii_whitespace())
            .collect();

        let loader_relative_path =
            String::from_utf8_lossy(&filtered_loader_bytes)
                .replace('\\', "/") // Fix path separators
                .trim_start_matches('/') // To relative path
                .to_string();

        let loader_absolute_path = mountpoint.join(loader_relative_path);
        debug!("EFI loader path candidate: {}", loader_absolute_path.display());

        // Verify the path exists
        loader_absolute_path.try_exists()?;

        Ok(loader_absolute_path)
    }

    pub fn loader_extra_directory_path(
        loader_path: &PathBuf,
    ) -> Result<PathBuf, PuavoError> {
        let extra_directory = PathBuf::from(
            loader_path.to_string_lossy().to_string() + ".extra.d",
        );
        extra_directory.try_exists()?;
        Ok(extra_directory)
    }

    fn mount_efi_variable_filesystem() -> Result<PathBuf, PuavoError> {
        let efi_variables_directory = Path::new(EFI_VARIABLE_FILESYSTEM_PATH);

        if efi_variables_directory.exists() {
            return Ok(efi_variables_directory.to_path_buf());
        }

        debug!(
            "Mounting EFI variable filesystem at {}",
            efi_variables_directory.display()
        );
        let output = Command::new("mount")
            .args(["-t", "efivarfs", "efivarfs", EFI_VARIABLE_FILESYSTEM_PATH])
            .output()?;

        if !output.status.success() {
            let error_message =
                String::from_utf8_lossy(&output.stderr).to_string();
            debug!(
                "Failed to mount EFI variable filesystem: {}",
                error_message
            );
            return Err(PuavoError::ShellError(error_message));
        }

        efi_variables_directory.try_exists()?;
        Ok(efi_variables_directory.to_path_buf())
    }
}

impl BlockDevice for EFIBootDevice {
    fn block_device(&self) -> Device {
        self.0.clone()
    }
}

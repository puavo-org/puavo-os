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

/// Path where the EFI variable filesystem (efivarfs) should be mounted.
pub const EFI_VARIABLE_FILESYSTEM_PATH: &str = "/sys/firmware/efi/efivars";

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
    ///                               the EFI boot disk.
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
            .map_err(|error| PuavoError::IoError(error))?;
        Ok(EFIBootDevice(boot_device))
    }

    /// Determine the full path to the EFI loader binary in the mounted EFI partition.
    ///
    /// Reads the `LoaderImageIdentifier-*` EFI variable to find the
    /// relative path to the loader, normalizes path separators, and joins it
    /// to the specified mountpoint.
    ///
    /// Parameters:
    /// - `mountpoint`: Path where the EFI partition is mounted.
    ///
    /// Errors:
    /// - `PuavoError::ShellError` if mounting the EFI variable filesystem fails.
    /// - `PuavoError::IoError` if filesystem access fails.
    /// - `PuavoError::NotFound` if the loader variable cannot be located.
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

    /// Verifies and returns the path to the EFI loader's ".extra.d" directory.
    ///
    /// Parameters:
    /// - `loader_path`: Absolute path to the loader binary.
    ///
    /// Errors:
    /// - Propagates `try_exists` IO errors.
    pub fn loader_extra_directory_path(
        loader_path: &PathBuf,
    ) -> Result<PathBuf, PuavoError> {
        let extra_directory = PathBuf::from(
            loader_path.to_string_lossy().to_string() + ".extra.d",
        );
        extra_directory.try_exists()?;
        Ok(extra_directory)
    }

    /// Ensure the EFI variable filesystem is mounted and return its path.
    ///
    /// Errors:
    /// - `PuavoError::ShellError` if the `mount` command fails.
    /// - `PuavoError::IoError` if path checks fail.
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

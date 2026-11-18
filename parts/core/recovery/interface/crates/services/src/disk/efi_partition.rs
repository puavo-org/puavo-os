//! The files the installer leaves on the EFI partition of the device. It is
//! found on the disks by its recovery bundle, so the recovery may start from
//! another disk, such as a USB stick.

use std::fs::{self, File};
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};
use std::process::Command;

use log::{debug, warn};
use serde::Deserialize;

/// Each block device by name, a partition as a directory of its disk.
const BLOCK_DEVICES: &str = "/sys/class/block";
const DEVICE_DIRECTORY: &str = "/dev";
/// What udev found of each block device, by its device number.
const UDEV_DEVICES: &str = "/run/udev/data";
const PARTITION_TYPE_PROPERTY: &str = "E:ID_PART_ENTRY_TYPE=";
const EFI_PARTITION_TYPE: &str = "c12a7328-f81f-11d2-ba4b-00a0c93ec93b";
const SECTOR_LENGTH: u64 = 512;
const BYTES_IN_GIGABYTE: u64 = 1000 * 1000 * 1000;
const MOUNTPOINT: &str = "/run/puavo-recovery/efi";
/// Where each EFI partition is looked into for a bundle.
const PROBE_MOUNTPOINT: &str = "/run/puavo-recovery/probe";
const READ_ONLY_OPTIONS: &str = "ro,nodev,nosuid,noexec";
const MOUNTS: &str = "/proc/self/mounts";

const BUNDLE: &str = "EFI/puavo/recovery.json";
const VAULT: &str = "EFI/puavo/vault.img";
const SAVED_REQUEST: &str = "EFI/puavo/recovery-request.json";
const MAX_SAVED_REQUEST_LENGTH: u64 = 16 * 1024;
const TEMPORARY_EXTENSION: &str = "tmp";
const MAX_BUNDLE_LENGTH: u64 = 8 * 1024;
const GRUB_ENVIRONMENT: &str = "EFI/puavo/grub/grubenv";
/// GRUB keeps its environment in a block of this size.
const MAX_GRUB_ENVIRONMENT_LENGTH: u64 = 1024;
const LOCALE_NAME: &str = "lang";

/// An EFI partition that holds a recovery bundle, as found on the disks.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DevicePartition {
    /// The partition, such as /dev/nvme0n1p1.
    pub device: PathBuf,
    /// The serial number the bundle names.
    pub serial_number: String,
    /// The disk of the partition, such as nvme0n1, with its model and size
    /// when the kernel tells them.
    pub disk: String,
}

/// The fields of the bundle that tell the device to the person.
#[derive(Deserialize)]
struct BundleLabel {
    serial_number: String,
}

/// The EFI partition of the device, mounted read only until a change is
/// needed.
pub struct EfiPartition {
    mountpoint: PathBuf,
    device: PathBuf,
}

impl EfiPartition {
    /// Mounts a partition as the EFI partition of the device, in place of
    /// one mounted earlier.
    pub fn mount_device(device: &Path) -> io::Result<Self> {
        let mountpoint = Path::new(MOUNTPOINT);
        if find_mounted_device(mountpoint)?.is_some() {
            unmount(mountpoint)?;
        }
        mount_read_only(device, mountpoint)?;
        debug!("mounted the EFI partition {}", device.display());
        Ok(EfiPartition {
            mountpoint: mountpoint.to_path_buf(),
            device: device.to_path_buf(),
        })
    }

    /// The EFI partition of the device, once it is mounted.
    pub fn mount() -> io::Result<Self> {
        let mountpoint = PathBuf::from(MOUNTPOINT);
        let device = find_mounted_device(&mountpoint)?.ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::NotFound,
                "no EFI partition of the device is mounted",
            )
        })?;
        Ok(EfiPartition { mountpoint, device })
    }

    /// Mounts the partition again for writing.
    pub fn make_writable(&self) -> io::Result<()> {
        // A partition of the tests is a writable directory.
        if cfg!(test) {
            return Ok(());
        }
        let status = Command::new("mount")
            .args(["--options", "remount,rw"])
            .arg(&self.mountpoint)
            .status()?;
        if !status.success() {
            return Err(io::Error::other("failed to mount for writing"));
        }
        Ok(())
    }

    /// A partition of the tests in a directory.
    #[cfg(test)]
    pub fn in_directory(directory: &Path) -> Self {
        EfiPartition {
            mountpoint: directory.to_path_buf(),
            device: PathBuf::new(),
        }
    }

    /// The disk that holds the partition, such as /dev/nvme0n1.
    pub fn disk(&self) -> io::Result<PathBuf> {
        let name = disk_name_of(&self.device)?;
        Ok(Path::new(DEVICE_DIRECTORY).join(name))
    }

    /// The saved request, if there is one.
    pub fn read_saved_request(&self) -> io::Result<Option<Vec<u8>>> {
        self.read_optional_file(SAVED_REQUEST, MAX_SAVED_REQUEST_LENGTH)
    }

    /// Saves a request, so it continues after the device was turned off.
    /// A new file replaces the old one only when it is complete, and it is
    /// on the disk when this returns.
    pub fn write_saved_request(&self, contents: &[u8]) -> io::Result<()> {
        self.make_writable()?;
        let path = self.mountpoint.join(SAVED_REQUEST);
        let temporary = path.with_extension(TEMPORARY_EXTENSION);
        let mut file = File::create(&temporary)?;
        file.write_all(contents)?;
        file.sync_all()?;
        fs::rename(&temporary, &path)?;
        // FAT keeps the size of a file in its directory entry, which only a
        // sync of the file under its new name writes.
        File::open(&path)?.sync_all()?;
        sync_directory(&path)?;
        debug!("saved the request");
        Ok(())
    }

    /// Removes the saved request, and a half written one that a power cut
    /// left behind. Each is overwritten with zeros first, since FAT leaves
    /// the bytes of a removed file in its free clusters.
    pub fn remove_saved_request(&self) -> io::Result<()> {
        self.make_writable()?;
        let path = self.mountpoint.join(SAVED_REQUEST);
        for file in [path.with_extension(TEMPORARY_EXTENSION), path.clone()] {
            match overwrite_with_zeros(&file)
                .and_then(|()| fs::remove_file(&file))
            {
                Err(error) if error.kind() != io::ErrorKind::NotFound => {
                    return Err(error);
                }
                _ => {}
            }
        }
        debug!("removed the saved request");
        sync_directory(&path)
    }

    /// The image of the boot vault.
    pub fn vault(&self) -> PathBuf {
        self.mountpoint.join(VAULT)
    }

    /// The recovery bundle, byte for byte as the installer wrote it.
    pub fn read_bundle(&self) -> io::Result<Vec<u8>> {
        self.read_file(BUNDLE, MAX_BUNDLE_LENGTH)
    }

    /// The locale the device was installed with, such as fi_FI.UTF-8,
    /// if its GRUB environment names one.
    pub fn read_locale(&self) -> io::Result<Option<String>> {
        let environment = self.read_optional_file(
            GRUB_ENVIRONMENT,
            MAX_GRUB_ENVIRONMENT_LENGTH,
        )?;
        Ok(environment.and_then(|bytes| {
            find_grub_variable(&String::from_utf8_lossy(&bytes), LOCALE_NAME)
        }))
    }

    fn read_optional_file(
        &self,
        name: &str,
        max_length: u64,
    ) -> io::Result<Option<Vec<u8>>> {
        match self.read_file(name, max_length) {
            Ok(bytes) => Ok(Some(bytes)),
            Err(error) if error.kind() == io::ErrorKind::NotFound => Ok(None),
            Err(error) => Err(error),
        }
    }

    fn read_file(&self, name: &str, max_length: u64) -> io::Result<Vec<u8>> {
        let mut bytes = Vec::new();
        File::open(self.mountpoint.join(name))?
            .take(max_length + 1)
            .read_to_end(&mut bytes)?;
        if bytes.len() as u64 > max_length {
            return Err(io::Error::other(format!("{name} is too long")));
        }
        Ok(bytes)
    }
}

/// The EFI partitions on the disks that hold a recovery bundle, in the
/// order of their names.
pub fn find_device_partitions() -> io::Result<Vec<DevicePartition>> {
    let mut devices: Vec<PathBuf> = fs::read_dir(BLOCK_DEVICES)?
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .filter(|path| is_efi_partition(path))
        .filter_map(|path| {
            Some(Path::new(DEVICE_DIRECTORY).join(path.file_name()?))
        })
        .collect();
    devices.sort();

    let mut partitions = Vec::new();
    for device in devices {
        match read_device_partition(&device) {
            Ok(Some(partition)) => partitions.push(partition),
            Ok(None) => debug!("no bundle on {}", device.display()),
            Err(error) => {
                warn!("failed to look into {}: {error}", device.display())
            }
        }
    }
    Ok(partitions)
}

/// The partition with the serial number its bundle names, if it holds a
/// bundle.
fn read_device_partition(device: &Path) -> io::Result<Option<DevicePartition>> {
    let mountpoint = Path::new(PROBE_MOUNTPOINT);
    mount_read_only(device, mountpoint)?;
    let partition = EfiPartition {
        mountpoint: mountpoint.to_path_buf(),
        device: device.to_path_buf(),
    };
    let bundle = partition.read_optional_file(BUNDLE, MAX_BUNDLE_LENGTH);
    unmount(mountpoint)?;

    let Some(bundle) = bundle? else {
        return Ok(None);
    };
    let label: BundleLabel = serde_json::from_slice(&bundle)
        .map_err(|error| io::Error::other(format!("bundle: {error}")))?;
    Ok(Some(DevicePartition {
        device: device.to_path_buf(),
        serial_number: label.serial_number,
        disk: describe_disk(&disk_name_of(device)?),
    }))
}

/// Whether a block device is a partition of the EFI partition type, as
/// udev read it from the partition table.
fn is_efi_partition(path: &Path) -> bool {
    let Ok(number) = fs::read_to_string(path.join("dev")) else {
        return false;
    };
    let properties =
        Path::new(UDEV_DEVICES).join(format!("b{}", number.trim()));
    fs::read_to_string(properties).is_ok_and(|properties| {
        properties.lines().any(|line| {
            line.strip_prefix(PARTITION_TYPE_PROPERTY).is_some_and(|kind| {
                kind.eq_ignore_ascii_case(EFI_PARTITION_TYPE)
            })
        })
    })
}

/// The name of the disk of a partition, such as nvme0n1 for
/// /dev/nvme0n1p1.
fn disk_name_of(partition: &Path) -> io::Result<String> {
    let name = partition
        .file_name()
        .ok_or_else(|| io::Error::other("partition without a name"))?;
    let device = fs::canonicalize(Path::new(BLOCK_DEVICES).join(name))?;
    device
        .parent()
        .and_then(Path::file_name)
        .map(|disk| disk.to_string_lossy().into_owned())
        .ok_or_else(|| io::Error::other("partition without a disk"))
}

/// A disk as a person tells it, such as "SAMSUNG MZVL2512, 512 GB,
/// nvme0n1".
fn describe_disk(name: &str) -> String {
    let directory = Path::new(BLOCK_DEVICES).join(name);
    let model = fs::read_to_string(directory.join("device/model"))
        .map(|model| model.trim().to_string())
        .unwrap_or_default();
    let gigabytes = fs::read_to_string(directory.join("size"))
        .ok()
        .and_then(|sectors| sectors.trim().parse::<u64>().ok())
        .map(|sectors| sectors * SECTOR_LENGTH / BYTES_IN_GIGABYTE)
        .unwrap_or_default();

    let mut parts = Vec::new();
    if !model.is_empty() {
        parts.push(model);
    }
    if gigabytes > 0 {
        parts.push(format!("{gigabytes} GB"));
    }
    parts.push(name.to_string());
    parts.join(", ")
}

fn mount_read_only(device: &Path, mountpoint: &Path) -> io::Result<()> {
    fs::create_dir_all(mountpoint)?;
    let status = Command::new("mount")
        .args(["--types", "vfat", "--options", READ_ONLY_OPTIONS])
        .arg(device)
        .arg(mountpoint)
        .status()?;
    if !status.success() {
        return Err(io::Error::other(format!(
            "failed to mount {}",
            device.display()
        )));
    }
    Ok(())
}

fn unmount(mountpoint: &Path) -> io::Result<()> {
    let status = Command::new("umount").arg(mountpoint).status()?;
    if !status.success() {
        return Err(io::Error::other(format!(
            "failed to unmount {}",
            mountpoint.display()
        )));
    }
    Ok(())
}

/// The value of a name in a GRUB environment, such as lang=fi_FI.UTF-8.
fn find_grub_variable(environment: &str, name: &str) -> Option<String> {
    environment
        .lines()
        .filter(|line| !line.starts_with('#'))
        .filter_map(|line| line.split_once('='))
        .find(|(key, _)| *key == name)
        .map(|(_, value)| value.to_string())
}

/// The device mounted at a mountpoint, if one is.
fn find_mounted_device(mountpoint: &Path) -> io::Result<Option<PathBuf>> {
    let mounts = fs::read_to_string(MOUNTS)?;
    Ok(mounts.lines().find_map(|line| {
        let mut fields = line.split(' ');
        let device = fields.next()?;
        let mounted = fields.next()?;
        (Path::new(mounted) == mountpoint).then(|| PathBuf::from(device))
    }))
}

/// Overwrites a file with zeros of its length and writes them to the disk.
/// FAT writes them over the same clusters.
fn overwrite_with_zeros(path: &Path) -> io::Result<()> {
    let length = fs::metadata(path)?.len();
    let mut file = fs::OpenOptions::new().write(true).open(path)?;
    file.write_all(&vec![0; length as usize])?;
    file.sync_all()
}

/// Writes the directory of a file to the disk, so a rename or a removal
/// in it survives a power cut.
fn sync_directory(path: &Path) -> io::Result<()> {
    match path.parent() {
        Some(directory) => File::open(directory)?.sync_all(),
        None => Ok(()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_grub_environment_gives_the_value_of_a_name() {
        let environment =
            "# GRUB Environment Block\nlang=fi_FI.UTF-8\n#########";
        let value = find_grub_variable(environment, LOCALE_NAME);
        assert_eq!(value.as_deref(), Some("fi_FI.UTF-8"));
        assert_eq!(find_grub_variable(environment, "other"), None);
    }
}

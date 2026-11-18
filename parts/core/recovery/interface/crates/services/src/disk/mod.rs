//! The disk of the device as the recovery sees it: the files the installer
//! leaves on the EFI partition, and the boot vault.

mod efi_partition;
mod vault_repair;

pub use efi_partition::{
    find_device_partitions, DevicePartition, EfiPartition,
};
pub use vault_repair::{
    read_firmware_state, repair_forgotten_pin, request_tpm_clear,
    reset_disk_encryption, FirmwareReadiness, FirmwareState, RepairFailure,
};

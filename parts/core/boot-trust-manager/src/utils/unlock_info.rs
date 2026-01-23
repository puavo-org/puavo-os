use std::{fs, path::Path, process::Command};

use log::{info, warn};
use serde::Serialize;

/// Maximum size for the PCR log data
const MAX_PCR_LOG_SIZE: usize = 1024 * 1024;

/// Path to kernel command line
const COMMAND_LINE_PATH: &str = "/proc/cmdline";

/// Base path for DMI information
const DMI_PATH: &str = "/sys/class/dmi/id";

/// Location where the unlock information file is stored
const UNLOCK_INFO_PATH: &str = "EFI/puavo/unlock-info.json";

/// Firmware information collected from DMI
#[derive(Serialize)]
pub struct FirmwareInfo {
    /// BIOS vendor name
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bios_vendor: Option<String>,
    /// BIOS version string
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bios_version: Option<String>,
    /// BIOS release date
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bios_date: Option<String>,
    /// BIOS release
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bios_release: Option<String>,
    /// System vendor
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sys_vendor: Option<String>,
    /// Product name
    #[serde(skip_serializing_if = "Option::is_none")]
    pub product_name: Option<String>,
    /// Product version
    #[serde(skip_serializing_if = "Option::is_none")]
    pub product_version: Option<String>,
}

impl FirmwareInfo {
    pub fn collect() -> Self {
        Self {
            bios_vendor: read_dmi_field("bios_vendor"),
            bios_version: read_dmi_field("bios_version"),
            bios_date: read_dmi_field("bios_date"),
            bios_release: read_dmi_field("bios_release"),
            sys_vendor: read_dmi_field("sys_vendor"),
            product_name: read_dmi_field("product_name"),
            product_version: read_dmi_field("product_version"),
        }
    }
}

/// Complete unlock information saved after successful unlock
#[derive(Serialize)]
pub struct UnlockInfo {
    /// Firmware and BIOS information
    pub firmware: FirmwareInfo,
    /// Kernel command line
    #[serde(skip_serializing_if = "Option::is_none")]
    pub kernel_command_line: Option<String>,
    /// PCR event log
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pcr_log: Option<String>,
}

impl UnlockInfo {
    /// Collect all unlock information.
    pub fn collect() -> Self {
        Self {
            firmware: FirmwareInfo::collect(),
            kernel_command_line: read_kernel_command_line(),
            pcr_log: read_pcr_log(),
        }
    }
}

/// Read a DMI field from sysfs
fn read_dmi_field(field: &str) -> Option<String> {
    let path = Path::new(DMI_PATH).join(field);
    fs::read_to_string(&path)
        .ok()
        .map(|string| string.trim().to_string())
        .filter(|string| !string.is_empty())
}

/// Read the kernel command line
fn read_kernel_command_line() -> Option<String> {
    fs::read_to_string(COMMAND_LINE_PATH)
        .ok()
        .map(|string| string.trim().to_string())
        .filter(|string| !string.is_empty())
}

/// Read the PCR event log using systemd-pcrlock
fn read_pcr_log() -> Option<String> {
    let output = Command::new("/usr/lib/systemd/systemd-pcrlock")
        .arg("cel")
        .output()
        .ok()?;

    if !output.status.success() {
        warn!(
            "systemd-pcrlock exited with status {}: {}",
            output.status,
            String::from_utf8_lossy(&output.stderr)
        );
        return None;
    }

    let log_data = if output.stdout.len() > MAX_PCR_LOG_SIZE {
        warn!(
            "PCR log size ({} bytes) exceeds maximum ({} bytes), truncating",
            output.stdout.len(),
            MAX_PCR_LOG_SIZE
        );
        &output.stdout[..MAX_PCR_LOG_SIZE]
    } else {
        &output.stdout[..]
    };

    String::from_utf8(log_data.to_vec()).ok()
}

/// Save unlock information to the EFI partition.
///
/// # Arguments
/// * `efi_mount_path` - Path where the EFI partition is mounted
pub fn save_to_efi(efi_mount_path: &Path) {
    let info = UnlockInfo::collect();

    let json = match serde_json::to_string(&info) {
        Ok(json) => json,
        Err(error) => {
            warn!("Failed to serialize unlock info: {}", error);
            return;
        }
    };

    let info_path = efi_mount_path.join(UNLOCK_INFO_PATH);
    if let Err(error) = fs::write(&info_path, &json) {
        warn!("Failed to write unlock info to {:?}: {}", info_path, error);
        return;
    }

    info!("Saved unlock info to {:?}", info_path);
}

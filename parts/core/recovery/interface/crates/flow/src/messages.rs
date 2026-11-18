//! What moves the flow on, and the work it asks for.

use std::path::PathBuf;
use std::time::Duration;

use recovery_services::disk::{DevicePartition, FirmwareState, RepairFailure};
use recovery_services::network::{NetworkFailure, Passphrase, WirelessNetwork};
use recovery_services::recovery_service::{
    KeyStatus, RecoveryCode, RecoveryFailure,
};

use crate::Problem;

/// What a service reported. Scans, connection attempts and requests carry
/// the number the flow gave them, so a late report of an earlier one is
/// dropped when the person left the view and came back to it.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Report {
    Scanned {
        network_number: u32,
        result: Result<Vec<WirelessNetwork>, NetworkFailure>,
    },
    Connected {
        network_number: u32,
        result: Result<(), NetworkFailure>,
    },
    RescanDue,
    ConnectionChecked {
        connected: bool,
    },
    Resumed {
        request_number: u32,
        /// The status of a saved request when one continues.
        result: Result<Option<KeyStatus>, RecoveryFailure>,
    },
    Joined {
        request_number: u32,
        result: Result<KeyStatus, RecoveryFailure>,
    },
    Checked {
        request_number: u32,
        result: Result<KeyStatus, RecoveryFailure>,
    },
    Cancelled {
        request_number: u32,
        result: Result<(), RecoveryFailure>,
    },
    Repaired {
        result: Result<(), RepairFailure>,
    },
    /// The EFI partitions on the disks that hold a recovery bundle.
    DevicePartitionsFound {
        partitions: Vec<DevicePartition>,
    },
    /// The problem a saved request was made for, if one was found, and the
    /// locale the device was installed with, such as fi_FI.UTF-8.
    SavedRequestChecked {
        problem: Option<Problem>,
        locale: Option<String>,
    },
    FirmwareChecked {
        result: Result<FirmwareState, RepairFailure>,
    },
    TpmClearRequested {
        result: Result<(), RepairFailure>,
    },
}

/// Work the flow asks the services to do.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Effect {
    FindDevicePartitions,
    /// Takes a partition as the EFI partition of the device, and looks for
    /// a saved request on it.
    UseDevicePartition {
        device: PathBuf,
    },
    CheckConnection,
    Scan {
        network_number: u32,
    },
    ScanLater,
    Connect {
        network_number: u32,
        access_point_address: String,
        passphrase: Option<Passphrase>,
    },
    ResumeRequest {
        request_number: u32,
        problem: Problem,
    },
    JoinQueue {
        request_number: u32,
        problem: Problem,
        code: RecoveryCode,
    },
    CheckLater {
        request_number: u32,
        delay: Duration,
    },
    CancelRequest {
        request_number: u32,
    },
    EndRequest {
        request_number: u32,
    },
    Repair {
        request_number: u32,
        problem: Problem,
    },
    CheckFirmware,
    OpenFirmwareSetup,
    RequestTpmClear,
    Restart,
}

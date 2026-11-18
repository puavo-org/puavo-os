//! What the person sees.

use recovery_services::disk::{
    DevicePartition, FirmwareReadiness, RepairFailure,
};
use recovery_services::network::{NetworkFailure, WirelessNetwork};
use recovery_services::recovery_service::{QueuePlace, RecoveryFailure};

/// What the person needs fixed.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Problem {
    /// The disk encryption is set up again from the start: the device keys,
    /// the TPM and the PIN.
    FullReset,
    /// Only the PIN is set again.
    ForgottenPin,
    CommandLine,
}

/// One step on the way to a fixed device.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Phase {
    PrepareFirmware,
    ConnectNetwork,
    EnterCode,
    Repair,
    ResetCommandLine,
}

impl Problem {
    /// The phases that fix the problem, in order.
    pub fn phases(self) -> &'static [Phase] {
        match self {
            Problem::FullReset => &[
                Phase::PrepareFirmware,
                Phase::ConnectNetwork,
                Phase::EnterCode,
                Phase::Repair,
            ],
            Problem::ForgottenPin => {
                &[Phase::ConnectNetwork, Phase::EnterCode, Phase::Repair]
            }
            Problem::CommandLine => &[Phase::ResetCommandLine],
        }
    }

    /// A name that stays the same across versions, such as full-reset.
    pub fn name(self) -> &'static str {
        match self {
            Problem::FullReset => "full-reset",
            Problem::ForgottenPin => "forgotten-pin",
            Problem::CommandLine => "command-line",
        }
    }

    /// Whether a phase before the index connects the network, so the
    /// person may choose another network there.
    pub fn connects_before(self, phase_index: usize) -> bool {
        self.phases()
            .iter()
            .position(|phase| *phase == Phase::ConnectNetwork)
            .is_some_and(|network_phase| network_phase < phase_index)
    }

    /// The problem a name stands for.
    pub fn from_name(name: &str) -> Option<Problem> {
        [Problem::FullReset, Problem::ForgottenPin, Problem::CommandLine]
            .into_iter()
            .find(|problem| problem.name() == name)
    }
}

/// Why a notice is shown.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Notice {
    /// No disk holds the EFI partition of a device.
    NoDevicePartition,
    NotAvailable,
    EnterpriseNotSupported,
    ScanFailed,
    ConnectFailed(NetworkFailure),
    RecoveryFailed(RecoveryFailure),
    RepairFailed(RepairFailure),
    Finished,
}

/// Something a view offers the person to do.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Action {
    OpenFirmwareSetup,
    /// Offered where the firmware takes the request and the TPM needs it.
    RequestTpmClear,
    Back,
}

/// Why a typed code was refused.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CodeRefusal {
    /// It is not eight characters of the alphabet of the codes.
    Malformed,
    /// The service took no recovery of this device with it.
    NotAccepted,
    /// The recovery of the code is done or its opening has passed.
    Ended,
    /// Another join of the code waits in the queue.
    InUse,
    /// The join failed for another reason, such as no answer.
    Failed(RecoveryFailure),
}

/// What the person sees. While requesting, the device contacts the
/// recovery service. In the code view, the person types the code an owner
/// got for the device.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum View {
    /// The flow looks for the EFI partition of the device on the disks.
    FindingDevice,
    /// Several disks hold the EFI partition of a device.
    ChoosePartition {
        partitions: Vec<DevicePartition>,
    },
    /// The flow looks for a request saved before the device was off.
    FindingSavedRequest,
    Start,
    /// The phases of the chosen problem.
    Phases,
    CheckingFirmware,
    /// The firmware setup must clear something before the reset.
    FirmwareSetup {
        readiness: FirmwareReadiness,
        actions: Vec<Action>,
    },
    CheckingConnection,
    Networks {
        networks: Vec<WirelessNetwork>,
        scanning: bool,
    },
    Passphrase {
        network: WirelessNetwork,
    },
    Connecting {
        network_name: String,
    },
    Requesting,
    EnterCode {
        serial_number: String,
        refusal: Option<CodeRefusal>,
    },
    WaitingForKey {
        queue: Option<QueuePlace>,
    },
    /// The saved request ended and another join uses its code, so the
    /// device tries the code again by itself.
    WaitingForCode,
    Repairing,
    Notice(Notice),
}

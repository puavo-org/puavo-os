//! The recovery flow: which view the person sees, how what the person does
//! and what the services report move it on, and which work it asks the
//! services to do. Each problem is a fixed list of phases.
//!
//! ```text
//!   Start ──choose──> Phases ──continue──> the current phase
//!     ^                 ^                        │
//!     └──────back───────┴──done, failed, back────┘
//! ```

mod messages;
#[cfg(test)]
mod tests;
mod view;

use std::time::Duration;

use recovery_services::disk::{
    DevicePartition, FirmwareReadiness, FirmwareState, RepairFailure,
};
use recovery_services::network::{Passphrase, Security, WirelessNetwork};
use recovery_services::recovery_service::{
    KeyProgress, KeyStatus, RecoveryCode, RecoveryFailure,
};

pub use messages::{Effect, Report};
pub use view::{Action, CodeRefusal, Notice, Phase, Problem, View};

/// Empty scans after which the flow stops scanning on its own, so a device
/// without a radio does not scan forever. The person can still scan again.
const AUTOMATIC_RESCANS: u32 = 5;

/// Checks in a row that may find the recovery service unreachable before
/// the flow gives up, so a short break in the network does not end the
/// request.
const UNREACHABLE_CHECKS: u32 = 6;

/// The state of a recovery.
pub struct Flow {
    view: View,
    problem: Option<Problem>,
    current_phase: usize,
    /// The number of the latest scan or connection attempt.
    network_number: u32,
    automatic_rescans: u32,
    /// The number of the latest request. Reports of earlier ones are
    /// dropped.
    request_number: u32,
    check_interval: Duration,
    unreachable_checks: u32,
    /// The serial number of the device, which the code view shows.
    serial_number: String,
}

impl Default for Flow {
    fn default() -> Self {
        Self::new()
    }
}

impl Flow {
    pub fn new() -> Self {
        Flow {
            view: View::Start,
            problem: None,
            current_phase: 0,
            network_number: 0,
            automatic_rescans: 0,
            request_number: 0,
            check_interval: Duration::ZERO,
            unreachable_checks: 0,
            serial_number: String::new(),
        }
    }

    /// Looks for the EFI partition of the device and a saved request on it
    /// before anything is offered.
    pub fn start(&mut self) -> Effect {
        self.view = View::FindingDevice;
        Effect::FindDevicePartitions
    }

    pub fn view(&self) -> &View {
        &self.view
    }

    /// The chosen problem and the index of its current phase.
    pub fn progress(&self) -> Option<(Problem, usize)> {
        self.problem.map(|problem| (problem, self.current_phase))
    }

    /// Chooses what to fix on the start view.
    pub fn choose_problem(&mut self, problem: Problem) {
        if self.view == View::Start {
            self.show_phases_of(problem);
        }
    }

    /// Takes the partition at a place in the list as the EFI partition of
    /// the device.
    pub fn choose_partition(&mut self, index: usize) -> Option<Effect> {
        let View::ChoosePartition { partitions } = &self.view else {
            return None;
        };
        let partition = partitions.get(index)?.clone();
        Some(self.use_partition(partition))
    }

    /// Chooses another network from the phases, once the network phase is
    /// done. The phases go on from the network phase again.
    pub fn change_network(&mut self) -> Option<Effect> {
        let (problem, current_phase) = self.progress()?;
        if self.view != View::Phases || !problem.connects_before(current_phase)
        {
            return None;
        }
        self.current_phase = problem
            .phases()
            .iter()
            .position(|phase| *phase == Phase::ConnectNetwork)?;
        self.automatic_rescans = 0;
        self.scan_networks()
    }

    /// Goes on from the view: starts the next phase, scans again after a
    /// failed connection, and at the end restarts. Elsewhere it returns to
    /// the phases.
    pub fn proceed_from_view(&mut self) -> Option<Effect> {
        match self.view {
            View::Phases => self.start_phase(),
            // The start view offers the restart and the power off.
            View::Notice(Notice::NoDevicePartition) => {
                self.view = View::Start;
                None
            }
            View::Notice(
                Notice::ConnectFailed(_) | Notice::EnterpriseNotSupported,
            ) => self.scan_networks(),
            // The repairs take effect only in the next boot.
            View::Notice(Notice::Finished) => Some(Effect::Restart),
            _ => self.return_to_phases(),
        }
    }

    /// Goes back one step. Leaving the queue cancels the request, and after
    /// the cancel the same code joins again.
    pub fn go_back_from_view(&mut self) -> Option<Effect> {
        match self.view {
            View::Phases => {
                self.problem = None;
                self.view = View::Start;
                None
            }
            View::Passphrase { .. } | View::Connecting { .. } => {
                self.scan_networks()
            }
            View::WaitingForKey { .. } | View::WaitingForCode => {
                self.view = View::Requesting;
                Some(Effect::CancelRequest {
                    request_number: self.request_number,
                })
            }
            _ => self.return_to_phases(),
        }
    }

    /// Joins the queue with the code typed in the code view.
    pub fn submit_code(&mut self, text: &str) -> Option<Effect> {
        if !matches!(self.view, View::EnterCode { .. }) {
            return None;
        }
        let problem = self.problem?;
        let Some(code) = RecoveryCode::parse(text) else {
            self.show_code_view(Some(CodeRefusal::Malformed));
            return None;
        };
        self.request_number += 1;
        self.view = View::Requesting;
        Some(Effect::JoinQueue {
            request_number: self.request_number,
            problem,
            code,
        })
    }

    /// Scans for networks again from the network list.
    pub fn rescan(&mut self) -> Option<Effect> {
        if !matches!(self.view, View::Networks { scanning: false, .. }) {
            return None;
        }
        self.automatic_rescans = 0;
        self.scan_networks()
    }

    /// Joins the network at a place in the list, or asks its passphrase.
    pub fn select_network(&mut self, index: usize) -> Option<Effect> {
        let View::Networks { networks, scanning: false } = &self.view else {
            return None;
        };
        let network = networks.get(index)?.clone();
        match network.security {
            Security::Open => self.connect_to(network, None),
            Security::Personal => {
                self.view = View::Passphrase { network };
                None
            }
            Security::Enterprise => {
                self.view = View::Notice(Notice::EnterpriseNotSupported);
                None
            }
        }
    }

    /// Joins the network whose passphrase is asked.
    pub fn submit_passphrase(
        &mut self,
        passphrase: Passphrase,
    ) -> Option<Effect> {
        let View::Passphrase { network } = &self.view else {
            return None;
        };
        let network = network.clone();
        self.connect_to(network, Some(passphrase))
    }

    /// Takes one of the actions the firmware setup view offers.
    pub fn take_action(&mut self, action: Action) -> Option<Effect> {
        let View::FirmwareSetup { actions, .. } = &self.view else {
            return None;
        };
        if !actions.contains(&action) {
            return None;
        }
        match action {
            Action::OpenFirmwareSetup => Some(Effect::OpenFirmwareSetup),
            Action::RequestTpmClear => Some(Effect::RequestTpmClear),
            Action::Back => self.go_back_from_view(),
        }
    }

    /// Moves the flow on after a service reported. A report that no longer
    /// fits the view, such as a scan result after the person went back, is
    /// dropped.
    pub fn receive_report(&mut self, report: Report) -> Option<Effect> {
        match (&self.view, report) {
            (
                View::FindingDevice,
                Report::DevicePartitionsFound { mut partitions },
            ) => {
                if partitions.len() == 1 {
                    return partitions.pop().map(|one| self.use_partition(one));
                }
                self.view = if partitions.is_empty() {
                    View::Notice(Notice::NoDevicePartition)
                } else {
                    View::ChoosePartition { partitions }
                };
                None
            }
            (
                View::FindingSavedRequest,
                Report::SavedRequestChecked { problem, .. },
            ) => {
                self.view = View::Start;
                if let Some(problem) = problem {
                    self.show_phases_of(problem);
                }
                None
            }
            (View::CheckingFirmware, Report::FirmwareChecked { result }) => {
                match result {
                    Ok(state)
                        if state.readiness == FirmwareReadiness::Ready =>
                    {
                        self.finish_phase()
                    }
                    Ok(state) => self.show_firmware_setup(state),
                    Err(failure) => {
                        self.view = View::Notice(Notice::RepairFailed(failure))
                    }
                }
                None
            }
            (
                View::FirmwareSetup { .. },
                Report::TpmClearRequested { result },
            ) => match result {
                // The firmware clears the TPM only at the next start.
                Ok(()) => Some(Effect::Restart),
                Err(failure) => {
                    self.view = View::Notice(Notice::RepairFailed(failure));
                    None
                }
            },
            (
                View::CheckingConnection,
                Report::ConnectionChecked { connected },
            ) => {
                if connected {
                    self.finish_phase();
                    return None;
                }
                self.scan_networks()
            }
            (
                View::Networks { scanning: true, .. },
                Report::Scanned { network_number, result: Ok(networks) },
            ) if network_number == self.network_number => {
                let empty = networks.is_empty();
                self.view = View::Networks { networks, scanning: false };
                // A radio may find networks only some time after it starts.
                if !empty || self.automatic_rescans >= AUTOMATIC_RESCANS {
                    return None;
                }
                self.automatic_rescans += 1;
                Some(Effect::ScanLater)
            }
            (
                View::Networks { scanning: true, .. },
                Report::Scanned { network_number, result: Err(_) },
            ) if network_number == self.network_number => {
                self.view = View::Notice(Notice::ScanFailed);
                None
            }
            (
                View::Networks { networks, scanning: false },
                Report::RescanDue,
            ) if networks.is_empty() => self.scan_networks(),
            (
                View::Connecting { .. },
                Report::Connected { network_number, result },
            ) if network_number == self.network_number => {
                match result {
                    Ok(()) => self.finish_phase(),
                    Err(failure) => {
                        self.view = View::Notice(Notice::ConnectFailed(failure))
                    }
                }
                None
            }
            (View::Requesting, Report::Resumed { request_number, result })
                if request_number == self.request_number =>
            {
                self.receive_resumption(result)
            }
            (View::Requesting, Report::Joined { request_number, result })
                if request_number == self.request_number =>
            {
                match result {
                    Ok(status) => self.receive_status(Ok(status)),
                    Err(failure) => self.refuse_code(failure),
                }
            }
            (
                View::WaitingForKey { .. } | View::WaitingForCode,
                Report::Checked { request_number, result },
            ) if request_number == self.request_number => {
                self.receive_status(result)
            }
            (
                View::Requesting,
                Report::Cancelled { request_number, result },
            ) if request_number == self.request_number => {
                match result {
                    Ok(()) => self.show_code_view(None),
                    Err(failure) => {
                        self.view =
                            View::Notice(Notice::RecoveryFailed(failure));
                    }
                }
                None
            }
            (View::Repairing, Report::Repaired { result }) => {
                self.receive_repair(result)
            }
            _ => None,
        }
    }

    /// Continues a saved request, or asks for the code.
    fn receive_resumption(
        &mut self,
        result: Result<Option<KeyStatus>, RecoveryFailure>,
    ) -> Option<Effect> {
        match result {
            Ok(Some(status)) => self.receive_status(Ok(status)),
            Ok(None) => {
                self.show_code_view(None);
                None
            }
            Err(failure) => self.refuse_code(failure),
        }
    }

    /// Shows why a join or a saved request failed in the code view, so the
    /// person may type the code again or another one. Only a device without
    /// its files or a build without a service ends there.
    fn refuse_code(&mut self, failure: RecoveryFailure) -> Option<Effect> {
        let refusal = match failure {
            RecoveryFailure::NoBundle | RecoveryFailure::NotConfigured => {
                return self.fail_request(failure);
            }
            RecoveryFailure::CodeNotAccepted => CodeRefusal::NotAccepted,
            RecoveryFailure::CodeInUse => CodeRefusal::InUse,
            RecoveryFailure::CodeEnded => CodeRefusal::Ended,
            other => CodeRefusal::Failed(other),
        };
        self.show_code_view(Some(refusal));
        None
    }

    fn receive_status(
        &mut self,
        result: Result<KeyStatus, RecoveryFailure>,
    ) -> Option<Effect> {
        let status = match result {
            Ok(status) => status,
            Err(RecoveryFailure::Unreachable)
                if self.unreachable_checks < UNREACHABLE_CHECKS =>
            {
                self.unreachable_checks += 1;
                return Some(self.check_later());
            }
            Err(failure) => return self.fail_request(failure),
        };

        self.unreachable_checks = 0;
        // The device checks less often the longer the queue.
        self.check_interval = status.check_interval;
        match status.progress {
            KeyProgress::KeyReceived => {
                self.finish_phase();
                return None;
            }
            KeyProgress::WaitingForKey(queue) => {
                self.view = View::WaitingForKey { queue };
            }
            KeyProgress::WaitingForCode => self.view = View::WaitingForCode,
        }
        Some(self.check_later())
    }

    /// Ends the request after a repair.
    fn receive_repair(
        &mut self,
        result: Result<(), RepairFailure>,
    ) -> Option<Effect> {
        match result {
            Ok(()) => {
                self.finish_phase();
                Some(Effect::EndRequest { request_number: self.request_number })
            }
            Err(failure) => {
                self.view = View::Notice(Notice::RepairFailed(failure));
                None
            }
        }
    }

    /// Shows why the request failed. The request stays as the key recovery
    /// left it, and continues at the next try.
    fn fail_request(&mut self, failure: RecoveryFailure) -> Option<Effect> {
        self.view = View::Notice(Notice::RecoveryFailed(failure));
        None
    }

    /// Takes the partition as the EFI partition of the device and looks for
    /// a saved request on it. The code view shows the serial number its
    /// bundle names.
    fn use_partition(&mut self, partition: DevicePartition) -> Effect {
        self.serial_number = partition.serial_number;
        self.view = View::FindingSavedRequest;
        Effect::UseDevicePartition { device: partition.device }
    }

    fn show_code_view(&mut self, refusal: Option<CodeRefusal>) {
        self.view = View::EnterCode {
            serial_number: self.serial_number.clone(),
            refusal,
        };
    }

    /// Shows what the firmware setup must clear and what the person can do
    /// about it.
    fn show_firmware_setup(&mut self, state: FirmwareState) {
        let tpm_needs_clear = matches!(
            state.readiness,
            FirmwareReadiness::TpmNotCleared
                | FirmwareReadiness::NothingCleared
        );
        let mut actions = vec![Action::OpenFirmwareSetup];
        if tpm_needs_clear && state.tpm_clear_requestable {
            actions.push(Action::RequestTpmClear);
        }
        actions.push(Action::Back);
        self.view = View::FirmwareSetup { readiness: state.readiness, actions };
    }

    fn check_later(&self) -> Effect {
        Effect::CheckLater {
            request_number: self.request_number,
            delay: self.check_interval,
        }
    }

    fn show_phases_of(&mut self, problem: Problem) {
        self.problem = Some(problem);
        self.current_phase = 0;
        self.view = View::Phases;
    }

    /// Starts the current phase of the chosen problem.
    fn start_phase(&mut self) -> Option<Effect> {
        let problem = self.problem?;
        let Some(phase) = problem.phases().get(self.current_phase) else {
            self.view = View::Notice(Notice::Finished);
            return None;
        };
        match phase {
            Phase::PrepareFirmware => {
                self.view = View::CheckingFirmware;
                Some(Effect::CheckFirmware)
            }
            Phase::ConnectNetwork => {
                self.automatic_rescans = 0;
                self.view = View::CheckingConnection;
                Some(Effect::CheckConnection)
            }
            Phase::EnterCode => {
                self.request_number += 1;
                self.view = View::Requesting;
                Some(Effect::ResumeRequest {
                    request_number: self.request_number,
                    problem,
                })
            }
            Phase::Repair => {
                self.view = View::Repairing;
                Some(Effect::Repair {
                    request_number: self.request_number,
                    problem,
                })
            }
            Phase::ResetCommandLine => {
                self.view = View::Notice(Notice::NotAvailable);
                None
            }
        }
    }

    /// Starts a scan that supersedes any earlier scan or connection.
    fn scan_networks(&mut self) -> Option<Effect> {
        self.network_number += 1;
        self.view = View::Networks { networks: Vec::new(), scanning: true };
        Some(Effect::Scan { network_number: self.network_number })
    }

    /// Starts a connection that supersedes any earlier scan or connection.
    fn connect_to(
        &mut self,
        network: WirelessNetwork,
        passphrase: Option<Passphrase>,
    ) -> Option<Effect> {
        self.network_number += 1;
        self.view = View::Connecting { network_name: network.name };
        Some(Effect::Connect {
            network_number: self.network_number,
            access_point_address: network.access_point_address,
            passphrase,
        })
    }

    /// Marks the current phase done and shows the phases again, or the end.
    fn finish_phase(&mut self) {
        let Some(problem) = self.problem else {
            self.view = View::Start;
            return;
        };
        self.current_phase += 1;
        self.view = if self.current_phase < problem.phases().len() {
            View::Phases
        } else {
            View::Notice(Notice::Finished)
        };
    }

    /// Returns to the phases from the views that lead back to them. Work
    /// they started may still report, and is dropped then.
    fn return_to_phases(&mut self) -> Option<Effect> {
        if matches!(
            self.view,
            View::CheckingConnection
                | View::CheckingFirmware
                | View::FirmwareSetup { .. }
                | View::Networks { .. }
                | View::Requesting
                | View::EnterCode { .. }
                | View::Notice(_)
        ) {
            self.view = View::Phases;
        }
        None
    }
}

//! Runs the work the flow asks for, each piece on its own thread, and
//! hands back what the services reported.

use std::sync::mpsc::{channel, Receiver, Sender};
use std::sync::Arc;
use std::thread;
use std::time::Duration;

use log::{debug, warn};
use recovery_flow::{Effect, Problem, Report};
use recovery_services::disk::{self, EfiPartition, RepairFailure};
use recovery_services::recovery_service::{
    read_saved_purpose, ServiceKeyRecovery,
};

use crate::power;

/// How long an empty scan waits before the next one.
const RESCAN_DELAY: Duration = Duration::from_secs(3);

/// Runs effects with the services of the device. The key recovery keeps
/// its request between calls, so the threads share it.
pub struct Runner {
    key_recovery: Arc<ServiceKeyRecovery>,
    sender: Sender<Report>,
    reports: Receiver<Report>,
}

impl Default for Runner {
    fn default() -> Self {
        Self::new()
    }
}

impl Runner {
    pub fn new() -> Self {
        let (sender, reports) = channel();
        Runner { key_recovery: Arc::default(), sender, reports }
    }

    /// Starts the work of an effect without waiting for it. Restarts happen
    /// at once.
    pub fn run_effect(&self, effect: Effect) {
        debug!("running {effect:?}");
        let sender = self.sender.clone();
        let key_recovery = Arc::clone(&self.key_recovery);
        let report = move |report: Report| {
            let _ = sender.send(report);
        };
        let work: Box<dyn FnOnce() + Send> = match effect {
            Effect::Restart => return power::restart(),
            Effect::OpenFirmwareSetup => return power::open_firmware_setup(),
            Effect::FindDevicePartitions => Box::new(move || {
                let partitions =
                    disk::find_device_partitions().unwrap_or_else(|error| {
                        warn!("failed to look for the EFI partitions: {error}");
                        Vec::new()
                    });
                report(Report::DevicePartitionsFound { partitions });
            }),
            Effect::UseDevicePartition { device } => Box::new(move || {
                let locale = match EfiPartition::mount_device(&device)
                    .and_then(|partition| partition.read_locale())
                {
                    Ok(locale) => locale,
                    Err(error) => {
                        warn!("failed to use {}: {error}", device.display());
                        None
                    }
                };
                // A request saved for an unknown purpose leaves the choice to
                // the person, and continues when they choose.
                let problem = read_saved_purpose()
                    .and_then(|purpose| Problem::from_name(&purpose));
                report(Report::SavedRequestChecked { problem, locale });
            }),
            Effect::CheckFirmware => Box::new(move || {
                let result = disk::read_firmware_state();
                report(Report::FirmwareChecked { result });
            }),
            Effect::RequestTpmClear => Box::new(move || {
                let result = disk::request_tpm_clear();
                report(Report::TpmClearRequested { result });
            }),
            Effect::CheckConnection => Box::new(move || {
                let connected = recovery_services::network::is_connected();
                report(Report::ConnectionChecked { connected });
            }),
            Effect::Scan { network_number } => Box::new(move || {
                let result = recovery_services::network::scan();
                report(Report::Scanned { network_number, result });
            }),
            Effect::ScanLater => Box::new(move || {
                thread::sleep(RESCAN_DELAY);
                report(Report::RescanDue);
            }),
            Effect::Connect {
                network_number,
                access_point_address,
                passphrase,
            } => Box::new(move || {
                let result = recovery_services::network::connect(
                    &access_point_address,
                    passphrase.as_ref(),
                );
                report(Report::Connected { network_number, result });
            }),
            Effect::ResumeRequest { request_number, problem } => {
                Box::new(move || {
                    let result = key_recovery
                        .resume_request(request_number, problem.name());
                    report(Report::Resumed { request_number, result });
                })
            }
            Effect::JoinQueue { request_number, problem, code } => {
                Box::new(move || {
                    let result = key_recovery.join_queue(
                        request_number,
                        problem.name(),
                        &code,
                    );
                    report(Report::Joined { request_number, result });
                })
            }
            Effect::CheckLater { request_number, delay } => {
                Box::new(move || {
                    thread::sleep(delay);
                    let result = key_recovery.check_request(request_number);
                    report(Report::Checked { request_number, result });
                })
            }
            Effect::CancelRequest { request_number } => Box::new(move || {
                let result = key_recovery.cancel_request(request_number);
                report(Report::Cancelled { request_number, result });
            }),
            Effect::EndRequest { request_number } => {
                Box::new(move || key_recovery.end_request(request_number))
            }
            Effect::Repair { request_number, problem } => Box::new(move || {
                let recovery_key = key_recovery.received_key(request_number);
                let result = match (problem, recovery_key) {
                    (_, None) => Err(RepairFailure::NoKey),
                    (Problem::ForgottenPin, Some(recovery_key)) => {
                        disk::repair_forgotten_pin(recovery_key.as_bytes())
                    }
                    (Problem::FullReset, Some(recovery_key)) => {
                        disk::reset_disk_encryption(recovery_key.as_bytes())
                    }
                    // The flow asks no repair for it.
                    (Problem::CommandLine, Some(_)) => {
                        Err(RepairFailure::Failed(
                            "the kernel command line has no repair".into(),
                        ))
                    }
                };
                report(Report::Repaired { result });
            }),
        };
        thread::spawn(work);
    }

    /// The next report, if one has arrived.
    pub fn next_report(&self) -> Option<Report> {
        self.reports.try_recv().ok()
    }
}

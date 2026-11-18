//! Pictures of every view in English, drawn in memory as the device draws
//! them, with an index of their texts. Run from the workspace with
//!
//! ```text
//! RECOVERY_VIEWS_DIRECTORY=<directory> \
//! RECOVERY_SUPPORT_ADDRESSES=<the support addresses> \
//! cargo test --features recovery-interface/development -- \
//!     --ignored every_view_is_drawn
//! ```
//!
//! Each view becomes a PPM file, numbered in the order of the flow. The
//! interface builds it as a test of its presenter, which reaches the screens
//! without a device.

use std::fmt::Write as _;
use std::fs;
use std::path::Path;
use std::rc::Rc;
use std::time::{Duration, Instant};

use recovery_flow::{Action, CodeRefusal, Notice, Problem, View};
use recovery_services::disk::{
    DevicePartition, FirmwareReadiness, RepairFailure,
};
use recovery_services::network::{NetworkFailure, Security, WirelessNetwork};
use recovery_services::recovery_service::{QueuePlace, RecoveryFailure};
use recovery_services::support::support_addresses;
use slint::platform::software_renderer::{
    MinimalSoftwareWindow, PremultipliedRgbaColor, RepaintBufferType,
};
use slint::platform::{Platform, WindowAdapter};
use slint::{ComponentHandle, PhysicalSize};

use super::screen::{screen_of_view, Content, Screen};
use super::{label_window, show_screen};
use crate::strings::{Language, Strings};
use crate::{RecoveryWindow, ViewKind};

/// The screen of the virtual machines of the end test.
const WIDTH: usize = 1280;
const HEIGHT: usize = 800;
/// Keeps the drawn pointer off the screen.
const POINTER_AWAY: f32 = -100.0;
const VIEWS_DIRECTORY: &str = "RECOVERY_VIEWS_DIRECTORY";
const INDEX: &str = "index.md";
const SERIAL_NUMBER: &str = "PF3ABC12";
/// A failure the boot trust manager reports in its own words.
const MANAGER_ERROR: &str = "Failed to unlock device";

/// Gives Slint one window that draws into memory.
struct MemoryPlatform {
    window: Rc<MinimalSoftwareWindow>,
    start: Instant,
}

impl Platform for MemoryPlatform {
    fn create_window_adapter(
        &self,
    ) -> Result<Rc<dyn WindowAdapter>, slint::PlatformError> {
        Ok(self.window.clone())
    }

    fn duration_since_start(&self) -> Duration {
        self.start.elapsed()
    }
}

/// A view, the progress the phases view shows, and the name of its picture
/// after its number.
struct NamedView {
    name: &'static str,
    view: View,
    progress: Option<(Problem, usize)>,
}

fn named(name: &'static str, view: View) -> NamedView {
    NamedView { name, view, progress: None }
}

fn phases(name: &'static str, problem: Problem, phase: usize) -> NamedView {
    NamedView { name, view: View::Phases, progress: Some((problem, phase)) }
}

fn wireless_network(name: &str, security: Security) -> WirelessNetwork {
    WirelessNetwork {
        name: name.into(),
        access_point_address: "AA:BB:CC:DD:EE:FF".into(),
        signal: 70,
        security,
    }
}

fn queued(position: u32) -> View {
    View::WaitingForKey { queue: Some(QueuePlace { position }) }
}

fn code_entry(refusal: Option<CodeRefusal>) -> View {
    View::EnterCode { serial_number: SERIAL_NUMBER.into(), refusal }
}

fn partition(device: &str, serial_number: &str, disk: &str) -> DevicePartition {
    DevicePartition {
        device: device.into(),
        serial_number: serial_number.into(),
        disk: disk.into(),
    }
}

fn firmware_setup(readiness: FirmwareReadiness) -> View {
    let mut actions = vec![Action::OpenFirmwareSetup];
    if readiness != FirmwareReadiness::KeysNotCleared {
        actions.push(Action::RequestTpmClear);
    }
    actions.push(Action::Back);
    View::FirmwareSetup { readiness, actions }
}

/// Every view, in the order of the flow.
fn every_view() -> Vec<NamedView> {
    let notice = |name, notice| named(name, View::Notice(notice));
    let service_failure = |name, failure| {
        named(name, View::Notice(Notice::RecoveryFailed(failure)))
    };
    let network_failure = |name, failure| {
        named(name, View::Notice(Notice::ConnectFailed(failure)))
    };
    vec![
        named("starting", View::FindingSavedRequest),
        named(
            "disk-choice",
            View::ChoosePartition {
                partitions: vec![
                    partition(
                        "/dev/nvme0n1p1",
                        SERIAL_NUMBER,
                        "SAMSUNG MZVL2512HCJQ, 512 GB, nvme0n1",
                    ),
                    partition(
                        "/dev/sda1",
                        "5CG1234XYZ",
                        "SanDisk Ultra, 32 GB, sda",
                    ),
                ],
            },
        ),
        notice("disk-none", Notice::NoDevicePartition),
        named("start", View::Start),
        phases("phases-full-reset", Problem::FullReset, 0),
        phases("phases-forgotten-pin", Problem::ForgottenPin, 0),
        phases("phases-kernel-command-line", Problem::CommandLine, 0),
        named("firmware-checking", View::CheckingFirmware),
        phases("firmware-ready", Problem::FullReset, 1),
        named(
            "firmware-keys-not-cleared",
            firmware_setup(FirmwareReadiness::KeysNotCleared),
        ),
        named(
            "firmware-tpm-not-cleared",
            firmware_setup(FirmwareReadiness::TpmNotCleared),
        ),
        named(
            "firmware-nothing-cleared",
            firmware_setup(FirmwareReadiness::NothingCleared),
        ),
        notice(
            "firmware-tpm-clear-failed",
            Notice::RepairFailed(RepairFailure::Failed(
                "failed to request a TPM clear: exit status: 1".into(),
            )),
        ),
        named("network-checking-wired", View::CheckingConnection),
        named(
            "network-scanning",
            View::Networks { networks: Vec::new(), scanning: true },
        ),
        named(
            "network-none-found",
            View::Networks { networks: Vec::new(), scanning: false },
        ),
        named(
            "network-list",
            View::Networks {
                networks: vec![
                    wireless_network("School", Security::Personal),
                    wireless_network("Guests", Security::Open),
                    wireless_network("Staff", Security::Enterprise),
                ],
                scanning: false,
            },
        ),
        named(
            "network-passphrase",
            View::Passphrase {
                network: wireless_network("School", Security::Personal),
            },
        ),
        named(
            "network-connecting",
            View::Connecting { network_name: "School".into() },
        ),
        network_failure("network-refused", NetworkFailure::Refused),
        network_failure("network-no-answer", NetworkFailure::NoAnswer),
        network_failure("network-failed", NetworkFailure::Failed),
        notice("network-scan-failed", Notice::ScanFailed),
        notice(
            "network-enterprise-not-supported",
            Notice::EnterpriseNotSupported,
        ),
        phases("phases-network-done", Problem::ForgottenPin, 1),
        named("code-contacting", View::Requesting),
        named("code-entry", code_entry(None)),
        named("code-malformed", code_entry(Some(CodeRefusal::Malformed))),
        named("code-not-accepted", code_entry(Some(CodeRefusal::NotAccepted))),
        named("code-in-use", code_entry(Some(CodeRefusal::InUse))),
        named("code-ended", code_entry(Some(CodeRefusal::Ended))),
        named(
            "code-not-answered",
            code_entry(Some(CodeRefusal::Failed(RecoveryFailure::Unreachable))),
        ),
        named("code-waiting", View::WaitingForCode),
        named("queue-joined", View::WaitingForKey { queue: None }),
        named("queue-next", queued(1)),
        named("queue-place", queued(3)),
        service_failure("service-no-bundle", RecoveryFailure::NoBundle),
        service_failure(
            "service-not-configured",
            RecoveryFailure::NotConfigured,
        ),
        service_failure("service-unreachable", RecoveryFailure::Unreachable),
        service_failure("service-untrusted", RecoveryFailure::Untrusted),
        service_failure("service-recovery-ended", RecoveryFailure::Ended),
        service_failure(
            "service-device-refused",
            RecoveryFailure::DeviceRefused,
        ),
        service_failure("service-not-cancelled", RecoveryFailure::NotCancelled),
        service_failure(
            "service-key-service-failed",
            RecoveryFailure::KeyServiceFailed,
        ),
        service_failure("service-failed", RecoveryFailure::Failed),
        phases("phases-code-done", Problem::ForgottenPin, 2),
        named("repairing", View::Repairing),
        notice("finished", Notice::Finished),
        notice(
            "repair-failed-manager-error",
            Notice::RepairFailed(RepairFailure::Failed(MANAGER_ERROR.into())),
        ),
        notice("repair-no-key", Notice::RepairFailed(RepairFailure::NoKey)),
        notice(
            "repair-secure-boot-disabled",
            Notice::RepairFailed(RepairFailure::SecureBootDisabled),
        ),
        notice("kernel-command-line-not-available", Notice::NotAvailable),
    ]
}

/// The buttons a view has besides its list.
fn buttons(screen: &Screen, strings: &Strings) -> Vec<&'static str> {
    match screen.kind {
        ViewKind::Start => vec![
            strings.restart_button,
            strings.firmware_settings_button,
            strings.power_off_button,
        ],
        ViewKind::Phases => {
            let mut buttons =
                vec![strings.continue_button, strings.back_button];
            if screen.choice_count > buttons.len() {
                buttons.push(strings.change_network_button);
            }
            buttons
        }
        ViewKind::Waiting => {
            vec![strings.back_button, strings.power_off_button]
        }
        ViewKind::Notice => vec![strings.continue_button],
        _ => Vec::new(),
    }
}

/// The texts of a picture for the index.
fn describe(
    name: &str,
    screen: &Screen,
    window: &RecoveryWindow,
    strings: &Strings,
) -> String {
    let mut text = format!("## {name}.png\n\n");
    let _ = writeln!(text, "- Title: {}", window.get_app_title());
    let _ = writeln!(text, "- Heading: {}", screen.heading);
    if !screen.hint.is_empty() {
        let _ = writeln!(text, "- Hint: {}", screen.hint);
    }
    match &screen.content {
        Content::None => {}
        Content::Choices(items) => {
            for item in items {
                let _ = write!(text, "- Choice: {}", item.title);
                if !item.description.is_empty() {
                    let _ = write!(text, ". {}", item.description);
                }
                text.push('\n');
            }
        }
        Content::Phases(items) => {
            for item in items {
                let _ = writeln!(
                    text,
                    "- Phase: {} ({:?})",
                    item.title, item.state
                );
            }
        }
        Content::Networks(items) => {
            for item in items {
                let _ = writeln!(
                    text,
                    "- Network: {}, {}, {} %",
                    item.name, item.security, item.signal
                );
            }
        }
        Content::CodeEntry { serial_number, refusal } => {
            let label = window.get_serial_label();
            let _ = writeln!(text, "- {label}: {serial_number}");
            let support = window.get_support();
            if !support.is_empty() {
                let _ = writeln!(text, "- {support}");
            }
            let _ = writeln!(text, "- Field: the code");
            if !refusal.is_empty() {
                let _ = writeln!(text, "- Refusal: {refusal}");
            }
            let _ = writeln!(text, "- Keys: {}", window.get_code_keys());
        }
        Content::Status(status) => {
            let _ = writeln!(text, "- Status: {status}");
            let _ = writeln!(text, "- Note: {}", window.get_note());
        }
    }
    let buttons = buttons(screen, strings);
    if !buttons.is_empty() {
        let _ = writeln!(text, "- Buttons: {}", buttons.join(", "));
    }
    text.push('\n');
    text
}

fn write_picture(
    path: &Path,
    pixels: &[PremultipliedRgbaColor],
) -> std::io::Result<()> {
    let mut picture = format!("P6\n{WIDTH} {HEIGHT}\n255\n").into_bytes();
    for pixel in pixels {
        picture.extend([pixel.red, pixel.green, pixel.blue]);
    }
    fs::write(path, picture)
}

#[test]
#[ignore = "writes a picture of every view into RECOVERY_VIEWS_DIRECTORY"]
fn every_view_is_drawn() {
    let directory = std::env::var(VIEWS_DIRECTORY)
        .expect("RECOVERY_VIEWS_DIRECTORY names the directory of the pictures");
    fs::create_dir_all(&directory).unwrap();

    let window = MinimalSoftwareWindow::new(RepaintBufferType::NewBuffer);
    window.set_size(PhysicalSize::new(WIDTH as u32, HEIGHT as u32));
    slint::platform::set_platform(Box::new(MemoryPlatform {
        window: window.clone(),
        start: Instant::now(),
    }))
    .unwrap();

    let strings = Strings::for_language(Language::English);
    let interface = RecoveryWindow::new().unwrap();
    label_window(&interface, strings, &support_addresses());
    interface.set_pointer_x(POINTER_AWAY);
    interface.set_pointer_y(POINTER_AWAY);
    interface.show().unwrap();

    let mut index = String::from(
        "# The views of the recovery interface\n\n\
         Drawn in English by the test every_view_is_drawn.\n\n",
    );
    let mut pixels = vec![PremultipliedRgbaColor::default(); WIDTH * HEIGHT];
    for (index_in_flow, named_view) in every_view().iter().enumerate() {
        let name = format!("{:02}-{}", index_in_flow + 1, named_view.name);
        let screen =
            screen_of_view(&named_view.view, named_view.progress, strings);
        index.push_str(&describe(&name, &screen, &interface, strings));
        show_screen(&interface, screen);

        slint::platform::update_timers_and_animations();
        window.request_redraw();
        window.draw_if_needed(|renderer| {
            renderer.render(&mut pixels, WIDTH);
        });
        let path = Path::new(&directory).join(format!("{name}.ppm"));
        write_picture(&path, &pixels).unwrap();
    }
    fs::write(Path::new(&directory).join(INDEX), index).unwrap();
}

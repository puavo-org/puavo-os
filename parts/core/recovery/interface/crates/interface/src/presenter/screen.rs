//! What each view of the flow shows, as plain values, and what a choice in
//! it means.

use std::cmp::Ordering;

use recovery_flow::{Action, CodeRefusal, Notice, Phase, Problem, View};
use recovery_services::disk::{
    DevicePartition, FirmwareReadiness, RepairFailure,
};
use recovery_services::network::{NetworkFailure, Security, WirelessNetwork};
use recovery_services::recovery_service::{QueuePlace, RecoveryFailure};

use crate::strings::{self, Strings};
use crate::{ChoiceItem, NetworkItem, PhaseItem, PhaseState, ViewKind};

/// The problems on the start view, in their order on the screen. The
/// restart, firmware settings and power off buttons follow them.
const START_PROBLEMS: [Problem; 3] =
    [Problem::FullReset, Problem::ForgottenPin, Problem::CommandLine];
const START_BUTTONS: [Choice; 3] =
    [Choice::Restart, Choice::OpenFirmwareSetup, Choice::PowerOff];
/// Continue and back, and the network change once the network is done.
const PHASES_BUTTONS: [Choice; 3] =
    [Choice::Proceed, Choice::Back, Choice::ChangeNetwork];
/// Back and power off.
const WAITING_BUTTONS: usize = 2;

/// What a view shows.
#[derive(Debug, PartialEq)]
pub struct Screen {
    pub kind: ViewKind,
    pub heading: String,
    pub hint: String,
    /// How many items the arrow keys move between.
    pub choice_count: usize,
    pub content: Content,
}

/// The part of a view that only some views have.
#[derive(Debug, PartialEq)]
pub enum Content {
    None,
    Choices(Vec<ChoiceItem>),
    Phases(Vec<PhaseItem>),
    Networks(Vec<NetworkItem>),
    CodeEntry {
        serial_number: String,
        /// Why the typed code was refused, or empty.
        refusal: String,
    },
    Status(String),
}

/// The screen of a view in the texts of a language. The phases view shows
/// the progress, the chosen problem and the index of its current phase.
pub fn screen_of_view(
    view: &View,
    progress: Option<(Problem, usize)>,
    strings: &Strings,
) -> Screen {
    match view {
        View::Start => Screen {
            kind: ViewKind::Start,
            heading: strings.start_question.into(),
            hint: strings.start_hint.into(),
            choice_count: START_PROBLEMS.len() + START_BUTTONS.len(),
            content: Content::Choices(
                START_PROBLEMS
                    .map(|problem| problem_item(problem, strings))
                    .to_vec(),
            ),
        },
        View::Phases => Screen {
            kind: ViewKind::Phases,
            heading: progress
                .map(|(problem, _)| problem_title(problem, strings).into())
                .unwrap_or_default(),
            hint: strings.phases_hint.into(),
            choice_count: phases_buttons(progress).len(),
            content: Content::Phases(
                progress
                    .map(|(problem, current_phase)| {
                        phase_items(problem, current_phase, strings)
                    })
                    .unwrap_or_default(),
            ),
        },
        View::FindingDevice | View::FindingSavedRequest => {
            busy_screen(strings.finding_saved_request)
        }
        View::ChoosePartition { partitions } => Screen {
            kind: ViewKind::Actions,
            heading: strings.choose_partition.into(),
            hint: strings.choose_partition_hint.into(),
            choice_count: partitions.len(),
            content: Content::Choices(
                partitions.iter().map(partition_item).collect(),
            ),
        },
        View::CheckingConnection => busy_screen(strings.checking_connection),
        View::CheckingFirmware => busy_screen(strings.checking_firmware),
        View::FirmwareSetup { readiness, actions } => Screen {
            kind: ViewKind::Actions,
            heading: readiness_text(*readiness, strings).into(),
            hint: strings.firmware_setup_hint.into(),
            choice_count: actions.len(),
            content: Content::Choices(
                actions
                    .iter()
                    .map(|action| action_item(*action, strings))
                    .collect(),
            ),
        },
        View::Networks { scanning: true, .. } => busy_screen(strings.scanning),
        View::Networks { networks, .. } if networks.is_empty() => Screen {
            kind: ViewKind::Networks,
            heading: strings.no_networks.into(),
            hint: strings.no_networks_keys.into(),
            choice_count: 0,
            content: Content::Networks(Vec::new()),
        },
        View::Networks { networks, .. } => Screen {
            kind: ViewKind::Networks,
            heading: strings.choose_network.into(),
            hint: strings.network_keys.into(),
            choice_count: networks.len(),
            content: Content::Networks(
                networks
                    .iter()
                    .map(|network| network_item(network, strings))
                    .collect(),
            ),
        },
        View::Passphrase { network } => Screen {
            kind: ViewKind::Passphrase,
            heading: strings
                .passphrase
                .replace(strings::NETWORK, &network.name),
            hint: strings.passphrase_keys.into(),
            choice_count: 0,
            content: Content::None,
        },
        View::Connecting { network_name } => Screen {
            kind: ViewKind::Busy,
            heading: strings.connecting.replace(strings::NETWORK, network_name),
            hint: strings.connecting_keys.into(),
            choice_count: 0,
            content: Content::None,
        },
        View::Requesting => busy_screen(strings.requesting),
        View::EnterCode { serial_number, refusal } => Screen {
            kind: ViewKind::CodeEntry,
            heading: strings.enter_code.into(),
            hint: strings.enter_code_hint.into(),
            choice_count: 0,
            content: Content::CodeEntry {
                serial_number: serial_number.clone(),
                refusal: refusal
                    .map(|refusal| refusal_text(refusal, strings))
                    .unwrap_or_default()
                    .into(),
            },
        },
        // The request waits also while the device is off, so the view offers
        // to turn it off.
        View::WaitingForKey { queue } => {
            let status = match queue {
                Some(place) => queue_place_text(*place, strings),
                None => strings.waiting_for_key.into(),
            };
            Screen {
                kind: ViewKind::Waiting,
                heading: strings.waiting_heading.into(),
                hint: strings.waiting_hint.into(),
                choice_count: WAITING_BUTTONS,
                content: Content::Status(status),
            }
        }
        View::WaitingForCode => Screen {
            kind: ViewKind::Waiting,
            heading: strings.waiting_for_code.into(),
            hint: strings.code_in_use.into(),
            choice_count: WAITING_BUTTONS,
            content: Content::Status(strings.code_retried.into()),
        },
        View::Repairing => busy_screen(strings.repairing),
        View::Notice(notice) => Screen {
            kind: ViewKind::Notice,
            heading: notice_text(notice, strings).into(),
            hint: notice_detail(notice, strings),
            choice_count: 1,
            content: Content::None,
        },
    }
}

/// What a place in the lists of a view stands for, such as the restart
/// button after the problems on the start view.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Choice {
    Problem(Problem),
    Proceed,
    Back,
    ChangeNetwork,
    Partition(usize),
    Network(usize),
    Action(Action),
    Restart,
    OpenFirmwareSetup,
    PowerOff,
}

/// What the person chose with the item at an index of a view.
pub fn choice_at(view: &View, index: usize) -> Option<Choice> {
    match view {
        View::Start => match START_PROBLEMS.get(index) {
            Some(problem) => Some(Choice::Problem(*problem)),
            None => START_BUTTONS.get(index - START_PROBLEMS.len()).copied(),
        },
        View::Phases => PHASES_BUTTONS.get(index).copied(),
        View::ChoosePartition { .. } => Some(Choice::Partition(index)),
        View::Networks { scanning: false, .. } => Some(Choice::Network(index)),
        View::WaitingForKey { .. } | View::WaitingForCode if index == 0 => {
            Some(Choice::Back)
        }
        View::WaitingForKey { .. } | View::WaitingForCode => {
            Some(Choice::PowerOff)
        }
        View::Notice(_) => Some(Choice::Proceed),
        View::FirmwareSetup { actions, .. } => {
            actions.get(index).copied().map(Choice::Action)
        }
        _ => None,
    }
}

/// The place of a request in the queue, such as "Number 3 in the queue."
fn queue_place_text(place: QueuePlace, strings: &Strings) -> String {
    if place.position == 1 {
        return strings.next_in_queue.into();
    }

    let position = place.position.to_string();
    strings.queue_place.replace(strings::POSITION, &position)
}

fn refusal_text(refusal: CodeRefusal, strings: &Strings) -> &'static str {
    match refusal {
        CodeRefusal::Malformed => strings.code_malformed,
        CodeRefusal::NotAccepted => strings.code_not_accepted,
        CodeRefusal::InUse => strings.code_in_use,
        CodeRefusal::Ended => strings.code_ended,
        CodeRefusal::Failed(failure) => recovery_failure_text(failure, strings),
    }
}

/// The buttons of the phases view. The network can be changed once its
/// phase is done.
fn phases_buttons(progress: Option<(Problem, usize)>) -> &'static [Choice] {
    let network_done = progress.is_some_and(|(problem, current_phase)| {
        problem.connects_before(current_phase)
    });
    if network_done {
        &PHASES_BUTTONS
    } else {
        &PHASES_BUTTONS[..2]
    }
}

/// A partition as the person tells the devices apart: by the serial number
/// and the disk.
fn partition_item(partition: &DevicePartition) -> ChoiceItem {
    ChoiceItem {
        title: partition.serial_number.as_str().into(),
        description: partition.disk.as_str().into(),
    }
}

fn busy_screen(heading: &str) -> Screen {
    Screen {
        kind: ViewKind::Busy,
        heading: heading.into(),
        hint: String::new(),
        choice_count: 0,
        content: Content::None,
    }
}

fn problem_item(problem: Problem, strings: &Strings) -> ChoiceItem {
    let description = match problem {
        Problem::FullReset => strings.full_reset_description,
        Problem::ForgottenPin => strings.forgotten_pin_description,
        Problem::CommandLine => strings.command_line_description,
    };
    ChoiceItem {
        title: problem_title(problem, strings).into(),
        description: description.into(),
    }
}

fn problem_title(problem: Problem, strings: &Strings) -> &'static str {
    match problem {
        Problem::FullReset => strings.full_reset,
        Problem::ForgottenPin => strings.forgotten_pin,
        Problem::CommandLine => strings.command_line,
    }
}

fn action_item(action: Action, strings: &Strings) -> ChoiceItem {
    let (title, description) = match action {
        Action::OpenFirmwareSetup => (
            strings.open_firmware_setup,
            strings.open_firmware_setup_description,
        ),
        Action::RequestTpmClear => {
            (strings.request_tpm_clear, strings.request_tpm_clear_description)
        }
        Action::Back => (strings.back_button, ""),
    };
    ChoiceItem { title: title.into(), description: description.into() }
}

fn network_item(network: &WirelessNetwork, strings: &Strings) -> NetworkItem {
    let security = match network.security {
        Security::Open => strings.open_network,
        Security::Personal => strings.personal_network,
        Security::Enterprise => strings.enterprise_network,
    };
    NetworkItem {
        name: network.name.as_str().into(),
        signal: network.signal.into(),
        security: security.into(),
    }
}

fn phase_items(
    problem: Problem,
    current_phase: usize,
    strings: &Strings,
) -> Vec<PhaseItem> {
    let state = |index: usize| match index.cmp(&current_phase) {
        Ordering::Less => PhaseState::Done,
        Ordering::Equal => PhaseState::Current,
        Ordering::Greater => PhaseState::Waiting,
    };
    problem
        .phases()
        .iter()
        .enumerate()
        .map(|(index, phase)| PhaseItem {
            title: phase_title(*phase, strings).into(),
            state: state(index),
        })
        .collect()
}

fn phase_title(phase: Phase, strings: &Strings) -> &'static str {
    match phase {
        Phase::PrepareFirmware => strings.prepare_firmware_phase,
        Phase::ConnectNetwork => strings.connect_network_phase,
        Phase::EnterCode => strings.enter_code_phase,
        Phase::Repair => strings.repair_phase,
        Phase::ResetCommandLine => strings.reset_command_line_phase,
    }
}

fn readiness_text(
    readiness: FirmwareReadiness,
    strings: &Strings,
) -> &'static str {
    match readiness {
        FirmwareReadiness::Ready => strings.firmware_ready,
        FirmwareReadiness::KeysNotCleared => strings.keys_not_cleared,
        FirmwareReadiness::TpmNotCleared => strings.tpm_not_cleared,
        FirmwareReadiness::NothingCleared => strings.nothing_cleared,
    }
}

fn notice_text(notice: &Notice, strings: &Strings) -> &'static str {
    match notice {
        Notice::NoDevicePartition => strings.no_device_partition,
        Notice::NotAvailable => strings.not_available,
        Notice::EnterpriseNotSupported => strings.enterprise_not_supported,
        Notice::ScanFailed => strings.scan_failed,
        Notice::ConnectFailed(failure) => {
            network_failure_text(*failure, strings)
        }
        Notice::RecoveryFailed(failure) => {
            recovery_failure_text(*failure, strings)
        }
        Notice::RepairFailed(failure) => repair_failure_text(failure, strings),
        Notice::Finished => strings.finished,
    }
}

fn network_failure_text(
    failure: NetworkFailure,
    strings: &Strings,
) -> &'static str {
    match failure {
        NetworkFailure::Refused => strings.network_refused,
        NetworkFailure::NoAnswer => strings.network_no_answer,
        NetworkFailure::Failed => strings.network_failed,
    }
}

fn recovery_failure_text(
    failure: RecoveryFailure,
    strings: &Strings,
) -> &'static str {
    match failure {
        RecoveryFailure::NoBundle => strings.no_bundle,
        RecoveryFailure::NotConfigured => strings.not_configured,
        RecoveryFailure::Unreachable => strings.service_unreachable,
        RecoveryFailure::Untrusted => strings.service_untrusted,
        RecoveryFailure::CodeNotAccepted => strings.code_not_accepted,
        RecoveryFailure::CodeInUse => strings.code_in_use,
        RecoveryFailure::CodeEnded => strings.code_ended,
        RecoveryFailure::DeviceRefused => strings.device_refused,
        RecoveryFailure::NotCancelled => strings.not_cancelled,
        RecoveryFailure::Ended => strings.recovery_ended,
        RecoveryFailure::KeyServiceFailed => strings.key_service_failed,
        RecoveryFailure::Failed => strings.getting_key_failed,
    }
}

fn repair_failure_text(
    failure: &RepairFailure,
    strings: &Strings,
) -> &'static str {
    match failure {
        RepairFailure::NoKey => strings.no_key,
        RepairFailure::SecureBootDisabled => strings.secure_boot_disabled,
        RepairFailure::Failed(_) => strings.repair_failed,
    }
}

/// More of a notice: what the boot trust manager told of a failed repair,
/// in its own words.
fn notice_detail(notice: &Notice, strings: &Strings) -> String {
    match notice {
        Notice::NoDevicePartition => strings.no_device_partition_hint.into(),
        Notice::RepairFailed(RepairFailure::Failed(message)) => message.clone(),
        _ => String::new(),
    }
}

#[cfg(test)]
mod tests {

    use crate::strings::Language;

    use super::*;

    fn english_strings() -> &'static Strings {
        Strings::for_language(Language::English)
    }

    fn wireless_network(name: &str, security: Security) -> WirelessNetwork {
        WirelessNetwork {
            name: name.into(),
            access_point_address: "AA:BB:CC:DD:EE:FF".into(),
            signal: 70,
            security,
        }
    }

    #[test]
    fn the_start_view_lists_the_problems_then_the_buttons() {
        let view = View::Start;
        assert_eq!(
            screen_of_view(&view, None, english_strings()).choice_count,
            6
        );
        let first = Choice::Problem(Problem::FullReset);
        assert_eq!(choice_at(&view, 0), Some(first));
        let second = Choice::Problem(Problem::ForgottenPin);
        assert_eq!(choice_at(&view, 1), Some(second));
        assert_eq!(choice_at(&view, 3), Some(Choice::Restart));
        assert_eq!(choice_at(&view, 4), Some(Choice::OpenFirmwareSetup));
        assert_eq!(choice_at(&view, 5), Some(Choice::PowerOff));
    }

    #[test]
    fn the_phases_before_the_current_one_show_as_done() {
        let view = View::Phases;
        let progress = Some((Problem::ForgottenPin, 1));
        let Content::Phases(phases) =
            screen_of_view(&view, progress, english_strings()).content
        else {
            panic!("no phases");
        };
        let states: Vec<PhaseState> =
            phases.iter().map(|phase| phase.state).collect();
        let expected =
            [PhaseState::Done, PhaseState::Current, PhaseState::Waiting];
        assert_eq!(states, expected);
        assert_eq!(phases[1].title, "Enter the code");
        assert_eq!(choice_at(&view, 0), Some(Choice::Proceed));
        assert_eq!(choice_at(&view, 1), Some(Choice::Back));
    }

    #[test]
    fn the_network_can_be_changed_once_its_phase_is_done() {
        let view = View::Phases;
        let count = |progress| {
            screen_of_view(&view, progress, english_strings()).choice_count
        };
        assert_eq!(count(Some((Problem::ForgottenPin, 0))), 2);
        assert_eq!(count(Some((Problem::ForgottenPin, 1))), 3);
        assert_eq!(count(Some((Problem::FullReset, 1))), 2);
        assert_eq!(choice_at(&view, 2), Some(Choice::ChangeNetwork));
    }

    #[test]
    fn several_partitions_show_their_serial_numbers_and_disks() {
        let partitions = vec![
            DevicePartition {
                device: "/dev/sda1".into(),
                serial_number: "OTHER".into(),
                disk: "USB stick, 16 GB, sda".into(),
            },
            DevicePartition {
                device: "/dev/nvme0n1p1".into(),
                serial_number: "PF3ABC12".into(),
                disk: "SAMSUNG, 512 GB, nvme0n1".into(),
            },
        ];
        let view = View::ChoosePartition { partitions };
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.choice_count, 2);
        let Content::Choices(items) = shown_screen.content else {
            panic!("no choices");
        };
        assert_eq!(items[1].title, "PF3ABC12");
        assert_eq!(items[1].description, "SAMSUNG, 512 GB, nvme0n1");
        assert_eq!(choice_at(&view, 1), Some(Choice::Partition(1)));
    }

    #[test]
    fn a_failed_join_is_told_in_the_code_view() {
        let refusal = CodeRefusal::Failed(RecoveryFailure::Unreachable);
        let view = View::EnterCode {
            serial_number: "PF3ABC12".into(),
            refusal: Some(refusal),
        };
        let Content::CodeEntry { refusal, .. } =
            screen_of_view(&view, None, english_strings()).content
        else {
            panic!("no code entry");
        };
        assert_eq!(refusal, english_strings().service_unreachable);
    }

    #[test]
    fn a_scan_in_progress_shows_as_busy_and_takes_no_choice() {
        let view = View::Networks { networks: Vec::new(), scanning: true };
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.kind, ViewKind::Busy);
        assert_eq!(shown_screen.heading, english_strings().scanning);
        assert_eq!(choice_at(&view, 0), None);
    }

    #[test]
    fn listed_networks_show_their_security_and_are_chosen_by_place() {
        let view = View::Networks {
            networks: vec![
                wireless_network("School", Security::Personal),
                wireless_network("Guests", Security::Open),
            ],
            scanning: false,
        };
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.choice_count, 2);
        let Content::Networks(items) = shown_screen.content else {
            panic!("no networks");
        };
        assert_eq!(items[0].security, "passphrase");
        assert_eq!(items[1].security, "open");
        assert_eq!(choice_at(&view, 1), Some(Choice::Network(1)));
    }

    #[test]
    fn the_code_view_shows_the_serial_number_and_why_a_code_was_refused() {
        let view = View::EnterCode {
            serial_number: "PF123456".into(),
            refusal: Some(CodeRefusal::NotAccepted),
        };
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.kind, ViewKind::CodeEntry);
        assert_eq!(
            shown_screen.content,
            Content::CodeEntry {
                serial_number: "PF123456".into(),
                refusal: english_strings().code_not_accepted.into(),
            }
        );
        assert_eq!(choice_at(&view, 0), None);
    }

    fn queued_status(position: u32) -> String {
        let place = QueuePlace { position };
        let view = View::WaitingForKey { queue: Some(place) };
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.kind, ViewKind::Waiting);
        let Content::Status(status) = shown_screen.content else {
            panic!("no status");
        };
        status
    }

    #[test]
    fn a_queued_request_shows_its_place() {
        assert_eq!(queued_status(3), "Number 3 in the queue.");
    }

    #[test]
    fn the_next_request_in_the_queue_is_told_so() {
        assert_eq!(queued_status(1), "Next in the queue.");
    }

    #[test]
    fn waiting_for_the_code_tells_it_is_in_use_and_may_go_back() {
        let view = View::WaitingForCode;
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.kind, ViewKind::Waiting);
        assert_eq!(shown_screen.hint, english_strings().code_in_use);
        assert_eq!(choice_at(&view, 0), Some(Choice::Back));
        assert_eq!(choice_at(&view, 1), Some(Choice::PowerOff));
    }

    #[test]
    fn a_queued_request_may_go_back_or_power_off() {
        let view = View::WaitingForKey { queue: None };
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.choice_count, 2);
        assert_eq!(choice_at(&view, 0), Some(Choice::Back));
        assert_eq!(choice_at(&view, 1), Some(Choice::PowerOff));
    }

    #[test]
    fn the_texts_and_their_values_show_in_the_language_of_the_device() {
        let view = View::Connecting { network_name: "School".into() };
        let finnish = Strings::for_language(Language::Finnish);
        let shown_screen = screen_of_view(&view, None, finnish);
        assert_eq!(shown_screen.heading, "Yhdistetään verkkoon School...");
        assert_eq!(shown_screen.hint, "Esc peruu.");
    }

    #[test]
    fn a_notice_shows_its_text_and_continues() {
        let failure = RecoveryFailure::Unreachable;
        let view = View::Notice(Notice::RecoveryFailed(failure));
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.heading, english_strings().service_unreachable);
        assert_eq!(choice_at(&view, 0), Some(Choice::Proceed));
    }

    #[test]
    fn a_failed_repair_shows_what_the_boot_trust_manager_told() {
        let failure = RepairFailure::Failed("Unlocking failed".into());
        let view = View::Notice(Notice::RepairFailed(failure));
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.heading, english_strings().repair_failed);
        assert_eq!(shown_screen.hint, "Unlocking failed");
    }

    #[test]
    fn an_empty_list_offers_a_new_search() {
        let view = View::Networks { networks: Vec::new(), scanning: false };
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.kind, ViewKind::Networks);
        assert_eq!(shown_screen.heading, english_strings().no_networks);
        assert_eq!(shown_screen.choice_count, 0);
    }

    #[test]
    fn the_passphrase_view_names_the_network() {
        let network = wireless_network("School", Security::Personal);
        let view = View::Passphrase { network };
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.kind, ViewKind::Passphrase);
        assert_eq!(shown_screen.heading, "Passphrase for School");
        assert_eq!(choice_at(&view, 0), None);
    }

    #[test]
    fn connecting_names_the_network_and_can_be_cancelled() {
        let view = View::Connecting { network_name: "School".into() };
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.kind, ViewKind::Busy);
        assert_eq!(shown_screen.heading, "Connecting to School...");
        assert_eq!(shown_screen.hint, english_strings().connecting_keys);
    }

    #[test]
    fn the_waiting_views_are_busy_and_take_no_choice() {
        let views = [
            (
                View::FindingSavedRequest,
                english_strings().finding_saved_request,
            ),
            (View::CheckingConnection, english_strings().checking_connection),
            (View::Requesting, english_strings().requesting),
            (View::Repairing, english_strings().repairing),
        ];
        for (view, heading) in views {
            let shown_screen = screen_of_view(&view, None, english_strings());
            assert_eq!(shown_screen.kind, ViewKind::Busy);
            assert_eq!(shown_screen.heading, heading);
            assert_eq!(shown_screen.choice_count, 0);
            assert_eq!(choice_at(&view, 0), None);
        }
    }

    #[test]
    fn the_firmware_setup_lists_the_actions_of_the_flow() {
        let actions = vec![
            Action::OpenFirmwareSetup,
            Action::RequestTpmClear,
            Action::Back,
        ];
        let view = View::FirmwareSetup {
            readiness: FirmwareReadiness::NothingCleared,
            actions,
        };
        let shown_screen = screen_of_view(&view, None, english_strings());
        assert_eq!(shown_screen.kind, ViewKind::Actions);
        assert_eq!(shown_screen.heading, english_strings().nothing_cleared);
        assert_eq!(shown_screen.choice_count, 3);
        let open = Choice::Action(Action::OpenFirmwareSetup);
        assert_eq!(choice_at(&view, 0), Some(open));
        let back = Choice::Action(Action::Back);
        assert_eq!(choice_at(&view, 2), Some(back));
        assert_eq!(choice_at(&view, 3), None);
    }
}

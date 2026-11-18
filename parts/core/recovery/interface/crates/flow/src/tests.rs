//! The flow driven through whole recoveries.

use std::path::PathBuf;

use recovery_services::disk::{
    DevicePartition, FirmwareReadiness, FirmwareState, RepairFailure,
};
use recovery_services::recovery_service::QueuePlace;

use super::*;

fn network(name: &str, security: Security) -> WirelessNetwork {
    WirelessNetwork {
        name: name.to_string(),
        access_point_address: format!("{name} address"),
        signal: 80,
        security,
    }
}

fn scanned(networks: Vec<WirelessNetwork>) -> Report {
    Report::Scanned { network_number: 1, result: Ok(networks) }
}

/// The scan of the network phase takes the first network number and the
/// connection after it the second.
const CONNECTION_NUMBER: u32 = 2;

fn assert_phase(flow: &Flow, problem: Problem, phase: usize) {
    assert_eq!(flow.view(), &View::Phases);
    assert_eq!(flow.progress(), Some((problem, phase)));
}

fn partition(name: &str, serial_number: &str) -> DevicePartition {
    DevicePartition {
        device: PathBuf::from(format!("/dev/{name}")),
        serial_number: serial_number.to_string(),
        disk: name.to_string(),
    }
}

/// A flow at the start view, with the EFI partition of the device found.
fn started() -> Flow {
    let mut flow = Flow::new();
    flow.start();
    flow.receive_report(Report::DevicePartitionsFound {
        partitions: vec![partition("vda1", SERIAL_NUMBER)],
    });
    flow.receive_report(Report::SavedRequestChecked {
        problem: None,
        locale: None,
    });
    flow
}

fn at_network_phase() -> Flow {
    let mut flow = started();
    flow.choose_problem(Problem::ForgottenPin);
    flow.proceed_from_view();
    flow.receive_report(Report::ConnectionChecked { connected: false });
    flow
}

#[test]
fn a_connected_device_skips_the_network_phase() {
    let mut flow = Flow::new();
    flow.choose_problem(Problem::ForgottenPin);
    let effect = flow.proceed_from_view();
    assert_eq!(effect, Some(Effect::CheckConnection));
    flow.receive_report(Report::ConnectionChecked { connected: true });
    assert_phase(&flow, Problem::ForgottenPin, 1);
}

#[test]
fn choosing_a_problem_shows_its_phases() {
    let mut flow = Flow::new();
    flow.choose_problem(Problem::ForgottenPin);
    assert_phase(&flow, Problem::ForgottenPin, 0);
}

#[test]
fn a_personal_network_asks_for_a_passphrase_and_connects_with_it() {
    let mut flow = at_network_phase();
    flow.receive_report(scanned(vec![network("School", Security::Personal)]));
    flow.select_network(0);
    assert!(matches!(flow.view(), View::Passphrase { .. }));
    let passphrase = Passphrase::new("secret".into());
    let effect = flow.submit_passphrase(passphrase.clone());
    assert_eq!(
        effect,
        Some(Effect::Connect {
            network_number: CONNECTION_NUMBER,
            access_point_address: "School address".to_string(),
            passphrase: Some(passphrase),
        })
    );
}

#[test]
fn an_open_network_connects_without_a_passphrase() {
    let mut flow = at_network_phase();
    flow.receive_report(scanned(vec![network("Guest", Security::Open)]));
    let effect = flow.select_network(0);
    assert!(matches!(effect, Some(Effect::Connect { passphrase: None, .. })));
}

#[test]
fn an_enterprise_network_is_not_supported_yet() {
    let mut flow = at_network_phase();
    flow.receive_report(scanned(vec![network("Staff", Security::Enterprise)]));
    assert_eq!(flow.select_network(0), None);
    assert_eq!(flow.view(), &View::Notice(Notice::EnterpriseNotSupported));
}

#[test]
fn empty_scans_repeat_only_a_few_times_on_their_own() {
    let mut flow = at_network_phase();
    for network_number in 1..=AUTOMATIC_RESCANS {
        let result = Ok(Vec::new());
        let report = Report::Scanned { network_number, result };
        assert_eq!(flow.receive_report(report), Some(Effect::ScanLater));
        assert_eq!(
            flow.receive_report(Report::RescanDue),
            Some(Effect::Scan { network_number: network_number + 1 })
        );
    }
    let last = Report::Scanned {
        network_number: AUTOMATIC_RESCANS + 1,
        result: Ok(Vec::new()),
    };
    assert_eq!(flow.receive_report(last), None);
    assert!(matches!(flow.rescan(), Some(Effect::Scan { .. })));
}

#[test]
fn a_scan_superseded_by_a_newer_one_is_dropped() {
    let mut flow = at_network_phase();
    flow.go_back_from_view();
    flow.proceed_from_view();
    flow.receive_report(Report::ConnectionChecked { connected: false });
    flow.receive_report(scanned(vec![network("Open", Security::Open)]));
    assert!(matches!(flow.view(), View::Networks { scanning: true, .. }));
}

#[test]
fn a_shown_list_is_not_replaced_by_a_scan_result() {
    let mut flow = at_network_phase();
    flow.receive_report(scanned(vec![network("School", Security::Personal)]));
    flow.receive_report(scanned(vec![network("Open", Security::Open)]));
    let View::Networks { networks, .. } = flow.view() else {
        panic!("the network list is not shown");
    };
    assert_eq!(networks[0].name, "School");
}

#[test]
fn back_while_connecting_drops_the_late_result() {
    let mut flow = at_network_phase();
    flow.receive_report(scanned(vec![network("Guest", Security::Open)]));
    flow.select_network(0);
    flow.go_back_from_view();
    flow.receive_report(Report::Connected {
        network_number: CONNECTION_NUMBER,
        result: Ok(()),
    });
    assert!(matches!(flow.view(), View::Networks { .. }));
}

#[test]
fn a_connection_finishes_the_network_phase() {
    let mut flow = at_network_phase();
    flow.receive_report(scanned(vec![network("Guest", Security::Open)]));
    flow.select_network(0);
    flow.receive_report(Report::Connected {
        network_number: CONNECTION_NUMBER,
        result: Ok(()),
    });
    assert_phase(&flow, Problem::ForgottenPin, 1);
}

const INTERVAL: Duration = Duration::from_secs(5);
const SERIAL_NUMBER: &str = "PF123456";

fn at_code_phase() -> Flow {
    let mut flow = at_network_phase();
    flow.receive_report(scanned(vec![network("Guest", Security::Open)]));
    flow.select_network(0);
    flow.receive_report(Report::Connected {
        network_number: CONNECTION_NUMBER,
        result: Ok(()),
    });
    flow
}

fn status(progress: KeyProgress) -> KeyStatus {
    KeyStatus { progress, check_interval: INTERVAL }
}

fn status_report(
    request_number: u32,
    result: Result<KeyProgress, RecoveryFailure>,
) -> Report {
    Report::Checked { request_number, result: result.map(status) }
}

fn resumed(status: Option<KeyStatus>) -> Report {
    Report::Resumed { request_number: 1, result: Ok(status) }
}

fn cancelled(
    request_number: u32,
    result: Result<(), RecoveryFailure>,
) -> Report {
    Report::Cancelled { request_number, result }
}

fn code_view(refusal: Option<CodeRefusal>) -> View {
    View::EnterCode { serial_number: SERIAL_NUMBER.to_string(), refusal }
}

fn at_code_view() -> Flow {
    let mut flow = at_code_phase();
    flow.proceed_from_view();
    flow.receive_report(resumed(None));
    flow
}

fn joined(result: Result<KeyProgress, RecoveryFailure>) -> Report {
    Report::Joined { request_number: 2, result: result.map(status) }
}

/// The first request number resumes, the join after it takes the second.
fn waiting_for_key() -> Flow {
    let mut flow = at_code_view();
    flow.submit_code("abcd 2345");
    flow.receive_report(joined(Ok(KeyProgress::WaitingForKey(None))));
    flow
}

#[test]
fn the_code_phase_looks_for_a_saved_request_first() {
    let mut flow = at_code_phase();
    let effect = flow.proceed_from_view();
    assert_eq!(
        effect,
        Some(Effect::ResumeRequest {
            request_number: 1,
            problem: Problem::ForgottenPin
        })
    );
    assert_eq!(flow.view(), &View::Requesting);
}

#[test]
fn without_a_saved_request_the_code_view_shows_the_serial_number() {
    let flow = at_code_view();
    assert_eq!(flow.view(), &code_view(None));
}

#[test]
fn a_typed_code_joins_the_queue_in_the_form_of_the_service() {
    let mut flow = at_code_view();
    let effect = flow.submit_code(" abcd 2345 ");
    assert_eq!(
        effect,
        Some(Effect::JoinQueue {
            request_number: 2,
            problem: Problem::ForgottenPin,
            code: RecoveryCode::parse("ABCD2345").unwrap(),
        })
    );
    assert_eq!(flow.view(), &View::Requesting);

    let effect =
        flow.receive_report(joined(Ok(KeyProgress::WaitingForKey(None))));
    assert_eq!(flow.view(), &View::WaitingForKey { queue: None });
    assert_eq!(
        effect,
        Some(Effect::CheckLater { request_number: 2, delay: INTERVAL })
    );
}

#[test]
fn a_malformed_code_is_told_without_contacting_the_service() {
    let mut flow = at_code_view();
    assert_eq!(flow.submit_code("ABCD 12"), None);
    assert_eq!(flow.view(), &code_view(Some(CodeRefusal::Malformed)));
}

#[test]
fn a_code_the_service_does_not_accept_is_told_in_the_code_view() {
    let mut flow = at_code_view();
    flow.submit_code("ABCD2345");
    let effect =
        flow.receive_report(joined(Err(RecoveryFailure::CodeNotAccepted)));
    assert_eq!(effect, None);
    assert_eq!(flow.view(), &code_view(Some(CodeRefusal::NotAccepted)));
    let effect = flow.submit_code("ABCD2346");
    assert!(matches!(effect, Some(Effect::JoinQueue { .. })));
}

#[test]
fn a_code_another_join_uses_is_told_in_the_code_view() {
    let mut flow = at_code_view();
    flow.submit_code("ABCD2345");
    let effect = flow.receive_report(joined(Err(RecoveryFailure::CodeInUse)));
    assert_eq!(effect, None);
    assert_eq!(flow.view(), &code_view(Some(CodeRefusal::InUse)));
}

#[test]
fn a_saved_request_whose_code_is_in_use_waits_for_the_code() {
    let mut flow = at_code_phase();
    flow.proceed_from_view();
    let effect =
        flow.receive_report(resumed(Some(status(KeyProgress::WaitingForCode))));
    assert_eq!(flow.view(), &View::WaitingForCode);
    assert_eq!(
        effect,
        Some(Effect::CheckLater { request_number: 1, delay: INTERVAL })
    );

    flow.receive_report(status_report(1, Ok(KeyProgress::WaitingForKey(None))));
    assert_eq!(flow.view(), &View::WaitingForKey { queue: None });
}

#[test]
fn back_while_waiting_for_the_code_cancels_the_request() {
    let mut flow = at_code_phase();
    flow.proceed_from_view();
    flow.receive_report(resumed(Some(status(KeyProgress::WaitingForCode))));
    let effect = flow.go_back_from_view();
    assert_eq!(effect, Some(Effect::CancelRequest { request_number: 1 }));
    flow.receive_report(cancelled(1, Ok(())));
    assert_eq!(flow.view(), &code_view(None));
}

#[test]
fn a_cancel_the_service_did_not_take_is_told_and_the_request_stays() {
    let mut flow = waiting_for_key();
    flow.go_back_from_view();
    let failure = RecoveryFailure::NotCancelled;
    let effect = flow.receive_report(cancelled(2, Err(failure)));
    assert_eq!(effect, None);
    assert_eq!(flow.view(), &View::Notice(Notice::RecoveryFailed(failure)));
}

#[test]
fn a_code_whose_recovery_ended_is_told_in_the_code_view() {
    let mut flow = at_code_view();
    flow.submit_code("ABCD2345");
    flow.receive_report(joined(Err(RecoveryFailure::CodeEnded)));
    assert_eq!(flow.view(), &code_view(Some(CodeRefusal::Ended)));
}

#[test]
fn back_from_the_queue_cancels_and_the_same_code_joins_again() {
    let mut flow = waiting_for_key();
    let effect = flow.go_back_from_view();
    assert_eq!(effect, Some(Effect::CancelRequest { request_number: 2 }));
    assert_eq!(flow.view(), &View::Requesting);
    flow.receive_report(cancelled(2, Ok(())));
    assert_eq!(flow.view(), &code_view(None));

    flow.receive_report(status_report(2, Ok(KeyProgress::KeyReceived)));
    assert_eq!(flow.view(), &code_view(None));
    let effect = flow.submit_code("abcd2345");
    assert!(matches!(
        effect,
        Some(Effect::JoinQueue { request_number: 3, .. })
    ));
}

#[test]
fn a_saved_request_in_the_queue_continues_without_a_code() {
    let mut flow = at_code_phase();
    flow.proceed_from_view();
    let place = QueuePlace { position: 2 };
    let effect = flow.receive_report(resumed(Some(status(
        KeyProgress::WaitingForKey(Some(place)),
    ))));
    assert_eq!(flow.view(), &View::WaitingForKey { queue: Some(place) });
    assert_eq!(
        effect,
        Some(Effect::CheckLater { request_number: 1, delay: INTERVAL })
    );

    flow.go_back_from_view();
    flow.receive_report(cancelled(1, Ok(())));
    assert_eq!(flow.view(), &code_view(None));
}

#[test]
fn the_received_key_finishes_the_code_phase() {
    let mut flow = waiting_for_key();
    assert_eq!(
        flow.receive_report(status_report(2, Ok(KeyProgress::KeyReceived))),
        None
    );
    assert_phase(&flow, Problem::ForgottenPin, 2);
}

#[test]
fn a_queued_request_shows_its_place_and_checks_at_the_given_pace() {
    let mut flow = waiting_for_key();
    let place = QueuePlace { position: 3 };
    let slower = Duration::from_secs(60);
    let effect = flow.receive_report(Report::Checked {
        request_number: 2,
        result: Ok(KeyStatus {
            progress: KeyProgress::WaitingForKey(Some(place)),
            check_interval: slower,
        }),
    });
    assert_eq!(flow.view(), &View::WaitingForKey { queue: Some(place) });
    assert_eq!(
        effect,
        Some(Effect::CheckLater { request_number: 2, delay: slower })
    );
}

#[test]
fn a_request_that_failed_on_the_device_stays_for_the_next_try() {
    let mut flow = waiting_for_key();
    let effect =
        flow.receive_report(status_report(2, Err(RecoveryFailure::Failed)));
    assert_eq!(effect, None);
}

#[test]
fn a_request_the_service_ended_or_failed_is_told_and_left_to_it() {
    for failure in [RecoveryFailure::Ended, RecoveryFailure::KeyServiceFailed] {
        let mut flow = waiting_for_key();
        let effect = flow.receive_report(status_report(2, Err(failure)));
        assert_eq!(effect, None);
        assert_eq!(flow.view(), &View::Notice(Notice::RecoveryFailed(failure)));
    }
}

#[test]
fn an_unreachable_service_is_checked_again_a_few_times() {
    let mut flow = waiting_for_key();
    for _ in 0..UNREACHABLE_CHECKS {
        let effect = flow.receive_report(status_report(
            2,
            Err(RecoveryFailure::Unreachable),
        ));
        assert!(matches!(effect, Some(Effect::CheckLater { .. })));
    }
    let effect = flow
        .receive_report(status_report(2, Err(RecoveryFailure::Unreachable)));
    assert_eq!(effect, None);
    assert_eq!(
        flow.view(),
        &View::Notice(Notice::RecoveryFailed(RecoveryFailure::Unreachable))
    );
}

#[test]
fn a_check_of_an_earlier_request_is_dropped() {
    let mut flow = waiting_for_key();
    flow.go_back_from_view();
    flow.receive_report(cancelled(2, Ok(())));
    flow.submit_code("ABCD2345");
    flow.receive_report(Report::Joined {
        request_number: 3,
        result: Ok(status(KeyProgress::WaitingForKey(None))),
    });
    flow.receive_report(status_report(2, Ok(KeyProgress::KeyReceived)));
    assert_eq!(flow.view(), &View::WaitingForKey { queue: None });
}

fn at_repair() -> Flow {
    let mut flow = waiting_for_key();
    flow.receive_report(status_report(2, Ok(KeyProgress::KeyReceived)));
    flow
}

#[test]
fn the_repair_phase_repairs_with_the_key_of_the_request() {
    let mut flow = at_repair();
    let effect = flow.proceed_from_view();
    assert_eq!(
        effect,
        Some(Effect::Repair {
            request_number: 2,
            problem: Problem::ForgottenPin
        })
    );
    assert_eq!(flow.view(), &View::Repairing);
}

#[test]
fn a_repaired_device_restarts_from_the_last_notice() {
    let mut flow = at_repair();
    flow.proceed_from_view();
    flow.receive_report(Report::Repaired { result: Ok(()) });
    assert_eq!(flow.view(), &View::Notice(Notice::Finished));
    assert_eq!(flow.proceed_from_view(), Some(Effect::Restart));
}

#[test]
fn a_failed_repair_can_be_tried_again() {
    let mut flow = at_repair();
    flow.proceed_from_view();
    let failure = RepairFailure::Failed("Unlocking failed".into());
    flow.receive_report(Report::Repaired { result: Err(failure.clone()) });
    assert_eq!(flow.view(), &View::Notice(Notice::RepairFailed(failure)));
    flow.proceed_from_view();
    assert_eq!(
        flow.proceed_from_view(),
        Some(Effect::Repair {
            request_number: 2,
            problem: Problem::ForgottenPin
        })
    );
}

#[test]
fn a_saved_request_continues_after_the_network() {
    let mut flow = Flow::new();
    assert_eq!(flow.start(), Effect::FindDevicePartitions);
    flow.receive_report(Report::DevicePartitionsFound {
        partitions: vec![partition("vda1", SERIAL_NUMBER)],
    });
    flow.receive_report(Report::SavedRequestChecked {
        problem: Some(Problem::ForgottenPin),
        locale: None,
    });
    assert_phase(&flow, Problem::ForgottenPin, 0);
    flow.proceed_from_view();
    flow.receive_report(Report::ConnectionChecked { connected: true });
    let effect = flow.proceed_from_view();
    assert_eq!(
        effect,
        Some(Effect::ResumeRequest {
            request_number: 1,
            problem: Problem::ForgottenPin
        })
    );
}

#[test]
fn without_a_saved_request_the_start_is_offered() {
    let flow = started();
    assert_eq!(flow.view(), &View::Start);
}

#[test]
fn a_repaired_vault_ends_the_request() {
    let mut flow = at_repair();
    flow.proceed_from_view();
    let effect = flow.receive_report(Report::Repaired { result: Ok(()) });
    assert_eq!(effect, Some(Effect::EndRequest { request_number: 2 }));
}

#[test]
fn the_command_line_reset_is_not_available_yet() {
    let mut flow = Flow::new();
    flow.choose_problem(Problem::CommandLine);
    flow.proceed_from_view();
    assert_eq!(flow.view(), &View::Notice(Notice::NotAvailable));
}

fn firmware_checked(readiness: FirmwareReadiness, requestable: bool) -> Report {
    Report::FirmwareChecked {
        result: Ok(FirmwareState {
            readiness,
            tpm_clear_requestable: requestable,
        }),
    }
}

#[test]
fn a_full_reset_starts_by_checking_the_firmware() {
    let mut flow = Flow::new();
    flow.choose_problem(Problem::FullReset);
    assert_eq!(flow.proceed_from_view(), Some(Effect::CheckFirmware));
    assert_eq!(flow.view(), &View::CheckingFirmware);

    flow.receive_report(firmware_checked(FirmwareReadiness::Ready, false));
    assert_phase(&flow, Problem::FullReset, 1);
}

#[test]
fn a_firmware_that_must_clear_something_tells_what_and_waits() {
    let mut flow = Flow::new();
    flow.choose_problem(Problem::FullReset);
    flow.proceed_from_view();
    flow.receive_report(firmware_checked(
        FirmwareReadiness::TpmNotCleared,
        true,
    ));
    assert!(matches!(flow.view(), View::FirmwareSetup { .. }));

    let View::FirmwareSetup { actions, .. } = flow.view() else {
        panic!("no firmware setup");
    };
    let expected =
        [Action::OpenFirmwareSetup, Action::RequestTpmClear, Action::Back];
    assert_eq!(actions, &expected);

    let effect = flow.take_action(Action::OpenFirmwareSetup);
    assert_eq!(effect, Some(Effect::OpenFirmwareSetup));
    let effect = flow.take_action(Action::RequestTpmClear);
    assert_eq!(effect, Some(Effect::RequestTpmClear));
    let effect =
        flow.receive_report(Report::TpmClearRequested { result: Ok(()) });
    assert_eq!(effect, Some(Effect::Restart));
}

#[test]
fn a_tpm_clear_is_offered_only_where_the_firmware_takes_it_and_it_helps() {
    let mut flow = Flow::new();
    flow.choose_problem(Problem::FullReset);
    flow.proceed_from_view();
    flow.receive_report(firmware_checked(
        FirmwareReadiness::NothingCleared,
        false,
    ));
    let effect = flow.take_action(Action::RequestTpmClear);
    assert_eq!(effect, None);

    flow.go_back_from_view();
    flow.proceed_from_view();
    flow.receive_report(firmware_checked(
        FirmwareReadiness::KeysNotCleared,
        true,
    ));
    let View::FirmwareSetup { actions, .. } = flow.view() else {
        panic!("no firmware setup");
    };
    let expected = [Action::OpenFirmwareSetup, Action::Back];
    assert_eq!(actions, &expected);
}

#[test]
fn a_saved_full_reset_continues_as_a_full_reset() {
    let mut flow = Flow::new();
    flow.start();
    flow.receive_report(Report::DevicePartitionsFound {
        partitions: vec![partition("vda1", SERIAL_NUMBER)],
    });
    flow.receive_report(Report::SavedRequestChecked {
        problem: Some(Problem::FullReset),
        locale: None,
    });
    assert_phase(&flow, Problem::FullReset, 0);
}

#[test]
fn a_failed_tpm_clear_request_is_told() {
    let mut flow = Flow::new();
    flow.choose_problem(Problem::FullReset);
    flow.proceed_from_view();
    flow.receive_report(firmware_checked(
        FirmwareReadiness::TpmNotCleared,
        true,
    ));
    flow.take_action(Action::RequestTpmClear);
    let failure = RepairFailure::Failed("failed to request a TPM clear".into());
    let effect = flow.receive_report(Report::TpmClearRequested {
        result: Err(failure.clone()),
    });
    assert_eq!(effect, None);
    assert_eq!(flow.view(), &View::Notice(Notice::RepairFailed(failure)));
}

#[test]
fn a_full_reset_ends_with_a_restart() {
    let mut flow = Flow::new();
    flow.choose_problem(Problem::FullReset);
    flow.proceed_from_view();
    flow.receive_report(firmware_checked(FirmwareReadiness::Ready, false));
    flow.proceed_from_view();
    flow.receive_report(Report::ConnectionChecked { connected: true });
    flow.proceed_from_view();
    flow.receive_report(resumed(Some(status(KeyProgress::KeyReceived))));
    assert_eq!(
        flow.proceed_from_view(),
        Some(Effect::Repair { request_number: 1, problem: Problem::FullReset })
    );

    let effect = flow.receive_report(Report::Repaired { result: Ok(()) });
    assert_eq!(effect, Some(Effect::EndRequest { request_number: 1 }));
    assert_eq!(flow.view(), &View::Notice(Notice::Finished));
    assert_eq!(flow.proceed_from_view(), Some(Effect::Restart));
}

#[test]
fn the_one_partition_of_a_device_is_taken_without_asking() {
    let mut flow = Flow::new();
    flow.start();
    let effect = flow.receive_report(Report::DevicePartitionsFound {
        partitions: vec![partition("vda1", SERIAL_NUMBER)],
    });
    assert_eq!(
        effect,
        Some(Effect::UseDevicePartition { device: "/dev/vda1".into() })
    );
    assert_eq!(flow.view(), &View::FindingSavedRequest);
}

#[test]
fn several_partitions_of_devices_are_offered_to_choose_from() {
    let mut flow = Flow::new();
    flow.start();
    let partitions =
        vec![partition("sda1", "OTHER"), partition("vda1", SERIAL_NUMBER)];
    let effect = flow.receive_report(Report::DevicePartitionsFound {
        partitions: partitions.clone(),
    });
    assert_eq!(effect, None);
    assert_eq!(flow.view(), &View::ChoosePartition { partitions });

    let effect = flow.choose_partition(1);
    assert_eq!(
        effect,
        Some(Effect::UseDevicePartition { device: "/dev/vda1".into() })
    );
    flow.receive_report(Report::SavedRequestChecked {
        problem: None,
        locale: None,
    });
    flow.choose_problem(Problem::ForgottenPin);
    flow.proceed_from_view();
    flow.receive_report(Report::ConnectionChecked { connected: true });
    flow.proceed_from_view();
    flow.receive_report(resumed(None));
    assert_eq!(flow.view(), &code_view(None));
}

#[test]
fn without_a_partition_of_a_device_it_is_told_and_the_start_offered() {
    let mut flow = Flow::new();
    flow.start();
    let effect = flow.receive_report(Report::DevicePartitionsFound {
        partitions: Vec::new(),
    });
    assert_eq!(effect, None);
    assert_eq!(flow.view(), &View::Notice(Notice::NoDevicePartition));
    flow.proceed_from_view();
    assert_eq!(flow.view(), &View::Start);
}

#[test]
fn another_network_is_chosen_from_the_phases_after_the_network_phase() {
    let mut flow = at_code_phase();
    assert_eq!(flow.change_network(), Some(Effect::Scan { network_number: 3 }));
    flow.receive_report(Report::Scanned {
        network_number: 3,
        result: Ok(vec![network("Other", Security::Open)]),
    });
    flow.select_network(0);
    flow.receive_report(Report::Connected {
        network_number: 4,
        result: Ok(()),
    });
    assert_phase(&flow, Problem::ForgottenPin, 1);
}

#[test]
fn no_network_is_changed_before_the_network_phase() {
    let mut flow = started();
    flow.choose_problem(Problem::ForgottenPin);
    assert_eq!(flow.change_network(), None);
    assert_phase(&flow, Problem::ForgottenPin, 0);
}

#[test]
fn a_join_without_an_answer_leaves_the_code_view_open() {
    let mut flow = at_code_view();
    flow.submit_code("ABCD2345");
    let effect = flow.receive_report(joined(Err(RecoveryFailure::Unreachable)));
    assert_eq!(effect, None);
    let refusal = CodeRefusal::Failed(RecoveryFailure::Unreachable);
    assert_eq!(flow.view(), &code_view(Some(refusal)));
    assert!(flow.submit_code("BCDE2345").is_some());
}

#[test]
fn a_saved_request_without_an_answer_leaves_the_code_view_open() {
    let mut flow = at_code_phase();
    flow.proceed_from_view();
    flow.receive_report(Report::Resumed {
        request_number: 1,
        result: Err(RecoveryFailure::Unreachable),
    });
    let refusal = CodeRefusal::Failed(RecoveryFailure::Unreachable);
    assert_eq!(flow.view(), &code_view(Some(refusal)));
}

#[test]
fn a_device_without_its_bundle_is_told_instead_of_the_code_view() {
    let mut flow = at_code_phase();
    flow.proceed_from_view();
    flow.receive_report(Report::Resumed {
        request_number: 1,
        result: Err(RecoveryFailure::NoBundle),
    });
    assert_eq!(
        flow.view(),
        &View::Notice(Notice::RecoveryFailed(RecoveryFailure::NoBundle))
    );
}

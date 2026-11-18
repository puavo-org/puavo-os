//! The key recovery against a test server that answers from a script.
//!
//! ```text
//!   test ──calls──> KeyRequest ──HTTP──> test server ──> scripted answers
//!                        │
//!                        └──> saved request in a directory
//! ```

use std::fs;
use std::io::{BufRead, BufReader, Write};
use std::net::TcpListener;
use std::path::PathBuf;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::OnceLock;
use std::thread::{self, JoinHandle};

use rsa::pkcs8::DecodePublicKey;
use rsa::rand_core::OsRng;
use rsa::{Oaep, RsaPublicKey};
use sha2::Sha256;

use super::*;

const SERIAL_NUMBER: &str = "PF3ABC12";
const BUNDLE: &str =
    r#"{"organisation_id":"hogwarts","serial_number":"PF3ABC12"}"#;
const CODE: &str = "ABCD2345";
const OTHER_CODE: &str = "BCDE2345";
const PURPOSE: &str = "forgotten-pin";
const REQUEST_NUMBER: u32 = 1;
const SAVED_REQUEST: &str = "EFI/puavo/recovery-request.json";
const RECOVERY_KEY: &[u8] = b"the recovery key";

static DIRECTORY_NUMBER: AtomicU32 = AtomicU32::new(0);
static RETURN_KEY: OnceLock<Vec<u8>> = OnceLock::new();

/// What the test server answers to one call.
enum Answer {
    Json(u16, String),
    /// Takes the call and closes the connection, as a lost answer.
    Nothing,
}

/// A call the test server took: method, path and body.
type Call = (String, String, String);

/// Answers the calls in the order of the script, one per connection.
struct TestServer {
    address: String,
    thread: Option<JoinHandle<Vec<Call>>>,
}

impl TestServer {
    fn start(script: Vec<Answer>) -> Self {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = format!("http://{}", listener.local_addr().unwrap());
        let thread = thread::spawn(move || {
            let mut calls = Vec::new();
            for answer in script {
                let (mut stream, _) = listener.accept().unwrap();
                let mut reader = BufReader::new(stream.try_clone().unwrap());
                calls.push(read_call(&mut reader));
                let Answer::Json(status, body) = answer else {
                    continue;
                };
                let response = format!(
                    "HTTP/1.1 {status} Answer\r\n\
                     Content-Type: application/json\r\n\
                     Content-Length: {}\r\nConnection: close\r\n\r\n{body}",
                    body.len()
                );
                stream.write_all(response.as_bytes()).unwrap();
            }
            calls
        });
        TestServer { address, thread: Some(thread) }
    }

    fn api(&self) -> RecoveryApi {
        RecoveryApi::new_unverified(&self.address).unwrap()
    }

    /// The calls the server took, once its script is done.
    fn calls(mut self) -> Vec<Call> {
        self.thread.take().unwrap().join().unwrap()
    }
}

fn read_call(reader: &mut impl BufRead) -> Call {
    let mut request_line = String::new();
    reader.read_line(&mut request_line).unwrap();
    let mut parts = request_line.split_whitespace();
    let method = parts.next().unwrap_or_default().to_string();
    let path = parts.next().unwrap_or_default().to_string();

    let mut length = 0;
    loop {
        let mut line = String::new();
        reader.read_line(&mut line).unwrap();
        if line.trim().is_empty() {
            break;
        }
        if let Some((name, value)) = line.split_once(':') {
            if name.eq_ignore_ascii_case("content-length") {
                length = value.trim().parse().unwrap();
            }
        }
    }
    let mut body = vec![0; length];
    reader.read_exact(&mut body).unwrap();
    (method, path, String::from_utf8(body).unwrap())
}

/// An EFI partition in a directory of its own, removed after the test.
struct TestPartition(PathBuf);

impl TestPartition {
    fn new() -> Self {
        let number = DIRECTORY_NUMBER.fetch_add(1, Ordering::Relaxed);
        let directory = std::env::temp_dir()
            .join(format!("key-recovery-test-{}-{number}", std::process::id()));
        fs::create_dir_all(directory.join("EFI/puavo")).unwrap();
        fs::write(directory.join("EFI/puavo/recovery.json"), BUNDLE).unwrap();
        TestPartition(directory)
    }

    fn files(&self) -> DeviceFiles {
        read_files_of(EfiPartition::in_directory(&self.0)).unwrap()
    }

    fn saved_request(&self) -> Option<serde_json::Value> {
        let contents = fs::read(self.0.join(SAVED_REQUEST)).ok()?;
        serde_json::from_slice(&contents).ok()
    }
}

impl Drop for TestPartition {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

/// One return key for all tests, since making one takes long.
fn return_key() -> ReturnKey {
    let saved = RETURN_KEY.get_or_init(|| {
        ReturnKey::new().unwrap().to_pkcs8_der().unwrap().to_vec()
    });
    ReturnKey::from_pkcs8_der(saved).unwrap()
}

fn request_id(letter: char) -> String {
    letter.to_string().repeat(43)
}

fn new_request(partition: &TestPartition, server: &TestServer) -> KeyRequest {
    KeyRequest {
        request_number: REQUEST_NUMBER,
        files: partition.files(),
        api: server.api(),
        code: RecoveryCode::parse(CODE).unwrap(),
        purpose: PURPOSE.to_string(),
        return_key: return_key(),
        request_id: None,
        recovery_key: None,
    }
}

fn joined(id: &str) -> Answer {
    Answer::Json(
        201,
        format!(r#"{{"id":"{id}","state":"queued","poll_seconds":5}}"#),
    )
}

fn joined_again(id: &str) -> Answer {
    Answer::Json(
        200,
        format!(r#"{{"id":"{id}","state":"queued","poll_seconds":5}}"#),
    )
}

fn queued(id: &str) -> Answer {
    Answer::Json(
        200,
        format!(
            r#"{{"id":"{id}","state":"queued","poll_seconds":5,"queue_position":2}}"#
        ),
    )
}

fn refused(status: u16, code: &str) -> Answer {
    Answer::Json(
        status,
        format!(r#"{{"error":{{"code":"{code}","message":"refused"}}}}"#),
    )
}

fn deleted() -> Answer {
    Answer::Json(200, "{}".to_string())
}

/// Saves a request as an earlier start of the device left it.
fn save_request(partition: &TestPartition, id: Option<&str>) {
    let server = TestServer::start(Vec::new());
    let mut saved_request = new_request(partition, &server);
    saved_request.request_id =
        id.map(|id| RequestId::try_from(id.to_string()).unwrap());
    saved_request.save().unwrap();
}

fn resume_saved_request_with(
    partition: &TestPartition,
    server: &TestServer,
    current: &mut Option<KeyRequest>,
) -> Result<Option<KeyStatus>, RecoveryFailure> {
    resume_saved_request(
        current,
        partition.files(),
        || Ok(server.api()),
        REQUEST_NUMBER,
        PURPOSE,
    )
}

/// Joins with a code as the person typed it.
fn join_with(
    current: &mut Option<KeyRequest>,
    partition: &TestPartition,
    server: &TestServer,
    code: &str,
) -> Result<KeyStatus, RecoveryFailure> {
    let code = RecoveryCode::parse(code).unwrap();
    join_with_code(current, REQUEST_NUMBER, &code, || {
        let mut request = new_request(partition, server);
        request.code = code.clone();
        Ok(request)
    })
}

fn progress(status: Option<KeyStatus>) -> Option<KeyProgress> {
    status.map(|status| status.progress)
}

#[test]
fn a_join_saves_the_return_key_before_it_and_the_id_after_it() {
    let partition = TestPartition::new();
    let server = TestServer::start(vec![joined(&request_id('A'))]);
    let mut current = None;

    let status = join_with(&mut current, &partition, &server, CODE);

    assert_eq!(status.unwrap().progress, KeyProgress::WaitingForKey(None));
    let saved_request = partition.saved_request().unwrap();
    assert_eq!(saved_request["id"], request_id('A'));
    assert_eq!(saved_request["code"], CODE);
    let calls = server.calls();
    let body: serde_json::Value = serde_json::from_str(&calls[0].2).unwrap();
    let mut fields: Vec<&String> = body.as_object().unwrap().keys().collect();
    fields.sort();
    let expected = [
        "bundle",
        "code",
        "organisation_id",
        "return_public_key",
        "serial_number",
    ];
    assert_eq!(fields, expected);
    assert_eq!(body["code"], CODE);
    assert_eq!(body["serial_number"], SERIAL_NUMBER);
}

#[test]
fn a_join_whose_answer_was_lost_is_sent_again_the_same() {
    let partition = TestPartition::new();
    let server = TestServer::start(vec![
        Answer::Nothing,
        joined_again(&request_id('A')),
    ]);
    let mut current = None;

    let failure = join_with(&mut current, &partition, &server, CODE);
    assert_eq!(failure, Err(RecoveryFailure::Unreachable));
    assert_eq!(
        partition.saved_request().unwrap()["id"],
        serde_json::Value::Null
    );

    let status =
        resume_saved_request_with(&partition, &server, &mut None).unwrap();
    assert_eq!(progress(status), Some(KeyProgress::WaitingForKey(None)));
    assert_eq!(partition.saved_request().unwrap()["id"], request_id('A'));
    let calls = server.calls();
    assert_eq!(calls[0].2, calls[1].2);
}

#[test]
fn the_code_typed_again_after_a_lost_answer_sends_the_same_join() {
    let partition = TestPartition::new();
    let server = TestServer::start(vec![
        Answer::Nothing,
        joined_again(&request_id('A')),
    ]);
    let mut current = None;

    let failure = join_with(&mut current, &partition, &server, CODE);
    assert_eq!(failure, Err(RecoveryFailure::Unreachable));
    let status = join_with(&mut current, &partition, &server, CODE);

    assert_eq!(status.unwrap().progress, KeyProgress::WaitingForKey(None));
    assert_eq!(partition.saved_request().unwrap()["id"], request_id('A'));
    let calls = server.calls();
    assert_eq!(calls[0].2, calls[1].2);
}

#[test]
fn a_refused_other_code_keeps_the_earlier_request() {
    let partition = TestPartition::new();
    let server =
        TestServer::start(vec![Answer::Nothing, refused(404, "NotFound")]);
    let mut current = None;

    let failure = join_with(&mut current, &partition, &server, CODE);
    assert_eq!(failure, Err(RecoveryFailure::Unreachable));
    let failure = join_with(&mut current, &partition, &server, OTHER_CODE);

    assert_eq!(failure, Err(RecoveryFailure::CodeNotAccepted));
    let saved_request = partition.saved_request().unwrap();
    assert_eq!(saved_request["code"], CODE);
    assert_eq!(saved_request["id"], serde_json::Value::Null);
    assert!(current.is_some_and(|request| request.code.as_str() == CODE));
}

#[test]
fn a_saved_code_without_an_answer_lets_another_code_join() {
    let partition = TestPartition::new();
    save_request(&partition, None);
    let server =
        TestServer::start(vec![Answer::Nothing, joined(&request_id('B'))]);
    let mut current = None;

    let resumed = resume_saved_request_with(&partition, &server, &mut current);
    assert_eq!(resumed, Err(RecoveryFailure::Unreachable));
    let status = join_with(&mut current, &partition, &server, OTHER_CODE);

    assert_eq!(status.unwrap().progress, KeyProgress::WaitingForKey(None));
    let saved_request = partition.saved_request().unwrap();
    assert_eq!(saved_request["code"], OTHER_CODE);
    assert_eq!(saved_request["id"], request_id('B'));
}

#[test]
fn a_typed_code_another_join_holds_leaves_nothing_saved() {
    let partition = TestPartition::new();
    let server = TestServer::start(vec![refused(409, "CodeInUse")]);
    let mut current = None;

    let failure = join_with(&mut current, &partition, &server, CODE);

    assert_eq!(failure, Err(RecoveryFailure::CodeInUse));
    assert!(partition.saved_request().is_none());
    assert!(current.is_none());
}

#[test]
fn a_code_whose_recovery_is_done_tells_it_ended() {
    let partition = TestPartition::new();
    let server = TestServer::start(vec![refused(409, "WrongState")]);

    let failure = join_with(&mut None, &partition, &server, CODE);

    assert_eq!(failure, Err(RecoveryFailure::CodeEnded));
}

#[test]
fn a_refused_device_is_told() {
    let partition = TestPartition::new();
    let server = TestServer::start(vec![refused(400, "OrganisationMismatch")]);

    let failure = join_with(&mut None, &partition, &server, CODE);

    assert_eq!(failure, Err(RecoveryFailure::DeviceRefused));
}

#[test]
fn without_a_saved_request_the_person_enters_a_code() {
    let partition = TestPartition::new();
    let server = TestServer::start(Vec::new());

    let resumed = resume_saved_request_with(&partition, &server, &mut None);

    assert_eq!(resumed, Ok(None));
}

#[test]
fn a_saved_request_in_the_queue_continues() {
    let partition = TestPartition::new();
    save_request(&partition, Some(&request_id('A')));
    let server = TestServer::start(vec![queued(&request_id('A'))]);
    let mut current = None;

    let status =
        resume_saved_request_with(&partition, &server, &mut current).unwrap();

    let place = QueuePlace { position: 2 };
    assert_eq!(progress(status), Some(KeyProgress::WaitingForKey(Some(place))));
    assert!(current.is_some());
}

/// A new opening of the device would count its code as wrong, so the
/// ended request does not join again.
#[test]
fn a_saved_request_the_service_no_longer_knows_has_ended() {
    let partition = TestPartition::new();
    save_request(&partition, Some(&request_id('A')));
    let server =
        TestServer::start(vec![refused(404, "RecoveryRequestNotFound")]);

    let resumed = resume_saved_request_with(&partition, &server, &mut None);

    assert_eq!(resumed, Err(RecoveryFailure::Ended));
    assert!(partition.saved_request().is_none());
    assert_eq!(server.calls().len(), 1);
}

#[test]
fn a_saved_request_whose_code_another_join_holds_waits_for_the_code() {
    let partition = TestPartition::new();
    save_request(&partition, None);
    let server = TestServer::start(vec![refused(409, "CodeInUse")]);

    let status =
        resume_saved_request_with(&partition, &server, &mut None).unwrap();

    assert_eq!(progress(status), Some(KeyProgress::WaitingForCode));
    assert!(partition.saved_request().is_some());
}

#[test]
fn a_saved_request_whose_code_ended_asks_for_a_code() {
    let partition = TestPartition::new();
    save_request(&partition, None);
    let server =
        TestServer::start(vec![refused(404, "RecoveryRequestNotFound")]);

    let resumed = resume_saved_request_with(&partition, &server, &mut None);

    assert_eq!(resumed, Ok(None));
    assert!(partition.saved_request().is_none());
}

#[test]
fn a_failed_resume_keeps_the_request_for_a_later_cancel() {
    let partition = TestPartition::new();
    save_request(&partition, Some(&request_id('A')));
    let server = TestServer::start(vec![
        Answer::Json(200, "not json".to_string()),
        deleted(),
    ]);
    let mut current = None;

    let resumed = resume_saved_request_with(&partition, &server, &mut current);
    assert_eq!(resumed, Err(RecoveryFailure::Failed));
    assert!(partition.saved_request().is_some());

    assert_eq!(cancel_current_request(&mut current, REQUEST_NUMBER), Ok(()));
    assert!(partition.saved_request().is_none());
    let calls = server.calls();
    assert_eq!(calls[1].0, "DELETE");
}

#[test]
fn a_done_request_gives_the_key() {
    let partition = TestPartition::new();
    save_request(&partition, Some(&request_id('A')));
    let public_key =
        RsaPublicKey::from_public_key_der(&return_key().public_der().unwrap())
            .unwrap();
    let result = BASE64.encode(
        public_key
            .encrypt(&mut OsRng, Oaep::new::<Sha256>(), RECOVERY_KEY)
            .unwrap(),
    );
    let server = TestServer::start(vec![Answer::Json(
        200,
        format!(
            r#"{{"id":"{}","state":"done","poll_seconds":5,"result":"{result}"}}"#,
            request_id('A')
        ),
    )]);
    let mut current = None;

    let status =
        resume_saved_request_with(&partition, &server, &mut current).unwrap();

    assert_eq!(progress(status), Some(KeyProgress::KeyReceived));
    let recovery_key = current.unwrap().recovery_key.unwrap();
    assert_eq!(recovery_key.as_bytes(), RECOVERY_KEY);
}

#[test]
fn a_cancel_the_service_does_not_take_keeps_the_saved_request() {
    let partition = TestPartition::new();
    save_request(&partition, Some(&request_id('A')));
    let busy = || Answer::Json(503, String::new());
    let server = TestServer::start(vec![
        queued(&request_id('A')),
        busy(),
        busy(),
        busy(),
    ]);
    let mut current = None;
    resume_saved_request_with(&partition, &server, &mut current).unwrap();

    let cancelled = cancel_current_request(&mut current, REQUEST_NUMBER);

    assert_eq!(cancelled, Err(RecoveryFailure::NotCancelled));
    assert!(partition.saved_request().is_some());
    assert!(current.is_some());
}

#[test]
fn the_end_removes_the_saved_request_before_the_service_hears_of_it() {
    let partition = TestPartition::new();
    save_request(&partition, Some(&request_id('A')));
    let busy = || Answer::Json(503, String::new());
    let server = TestServer::start(vec![
        queued(&request_id('A')),
        busy(),
        busy(),
        busy(),
    ]);
    let mut current = None;
    resume_saved_request_with(&partition, &server, &mut current).unwrap();

    end_current_request(&mut current, REQUEST_NUMBER);

    assert!(partition.saved_request().is_none());
    assert!(current.is_none());
    assert_eq!(server.calls().len(), 4);
}

#[test]
fn a_late_end_of_an_earlier_request_leaves_the_newer_one() {
    let partition = TestPartition::new();
    let server = TestServer::start(vec![joined(&request_id('A'))]);
    let mut current = None;
    let mut newer_request = new_request(&partition, &server);
    newer_request.request_number = REQUEST_NUMBER + 1;
    join_new_request(&mut current, newer_request, None).unwrap();

    end_current_request(&mut current, REQUEST_NUMBER);

    assert!(current.is_some());
    assert!(partition.saved_request().is_some());
}

#[test]
fn a_failure_of_the_key_service_ends_the_request() {
    let partition = TestPartition::new();
    save_request(&partition, Some(&request_id('A')));
    let server = TestServer::start(vec![Answer::Json(
        200,
        format!(
            r#"{{"id":"{}","state":"failed","poll_seconds":5,"error":{{"code":"UnwrapFailed","message":"failed"}}}}"#,
            request_id('A')
        ),
    )]);

    let resumed = resume_saved_request_with(&partition, &server, &mut None);

    assert_eq!(resumed, Err(RecoveryFailure::KeyServiceFailed));
    assert!(partition.saved_request().is_none());
}

#[test]
fn a_queued_request_the_service_no_longer_knows_ends_without_a_join() {
    let partition = TestPartition::new();
    save_request(&partition, Some(&request_id('A')));
    let server = TestServer::start(vec![
        queued(&request_id('A')),
        refused(404, "RecoveryRequestNotFound"),
    ]);
    let mut current = None;
    resume_saved_request_with(&partition, &server, &mut current).unwrap();

    let checked = check_current_request(&mut current, REQUEST_NUMBER);

    assert_eq!(checked, Err(RecoveryFailure::Ended));
    assert!(current.is_none());
    assert!(partition.saved_request().is_none());
    assert_eq!(server.calls().len(), 2);
}

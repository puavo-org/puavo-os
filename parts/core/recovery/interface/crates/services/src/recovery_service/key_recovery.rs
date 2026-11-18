//! Key recovery through the recovery service the device is configured for.

use std::sync::{Mutex, MutexGuard};
use std::time::Duration;

use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine;
use log::{debug, warn};
use serde::{Deserialize, Serialize};
use zeroize::{Zeroize, Zeroizing};

use crate::disk::EfiPartition;

use super::api::{
    ApiFailure, Device, RecoveryApi, RequestId, RequestState, RequestStatus,
};
use super::return_key::ReturnKey;
use super::{
    KeyProgress, KeyStatus, QueuePlace, RecoveryCode, RecoveryFailure,
    RecoveryKey,
};

/// The address of the recovery service and the authorities that may
/// certify it, from the build.
const ADDRESS: &str = "/etc/puavo-recovery/address";
#[cfg(not(feature = "development"))]
const AUTHORITIES: &str = "/etc/puavo-recovery/authorities.pem";

/// The bounds of the poll interval in the contract.
const MIN_POLL_SECONDS: u64 = 5;
const MAX_POLL_SECONDS: u64 = 300;
/// The longest recovery key in the contract.
const MAX_RECOVERY_KEY_LENGTH: usize = 318;
const DELETE_ATTEMPTS: u32 = 3;
const DELETE_PAUSE: Duration = Duration::from_secs(5);
/// How often the device tries the code while another join holds it.
const CODE_IN_USE_INTERVAL: Duration = Duration::from_secs(60);

/// The fields of the bundle that name the device. The rest is encrypted.
#[derive(Deserialize)]
struct BundleIdentity {
    organisation_id: String,
    serial_number: String,
}

/// What a request needs to continue after the device was turned off. It is
/// kept as plain text on the EFI partition until the request ends, and is
/// written before the join, so a join whose answer was lost is sent again
/// the same.
#[derive(Serialize, Deserialize)]
struct SavedRequest {
    /// Nothing until the service answered the join.
    #[serde(default)]
    id: Option<String>,
    code: String,
    /// The return key pair as DER PKCS#8 in base64.
    return_key: String,
    /// The problem the request is for, which the caller continues with.
    #[serde(default)]
    purpose: String,
}

impl Drop for SavedRequest {
    fn drop(&mut self) {
        self.code.zeroize();
        self.return_key.zeroize();
    }
}

/// The EFI partition and the bundle the installer left on it.
struct DeviceFiles {
    partition: EfiPartition,
    bundle: Vec<u8>,
    identity: BundleIdentity,
}

/// The request of the device for its key, with the files it is saved in.
struct KeyRequest {
    request_number: u32,
    files: DeviceFiles,
    api: RecoveryApi,
    code: RecoveryCode,
    purpose: String,
    return_key: ReturnKey,
    /// Nothing while the service has not answered the join, or after the
    /// request ended and the code waits to work again.
    request_id: Option<RequestId>,
    recovery_key: Option<RecoveryKey>,
}

/// Gets the recovery key of the device from the recovery service the device
/// is configured for. Each request carries a number from its caller, and a
/// call for any other than the latest is refused.
#[derive(Default)]
pub struct ServiceKeyRecovery {
    request: Mutex<Option<KeyRequest>>,
}

impl ServiceKeyRecovery {
    /// The status of the request saved before the device was turned off,
    /// when it continues. Without a request to continue, the person enters
    /// a code.
    pub fn resume_request(
        &self,
        request_number: u32,
        purpose: &str,
    ) -> Result<Option<KeyStatus>, RecoveryFailure> {
        let mut request = self.lock_request();
        resume_saved_request(
            &mut request,
            read_device_files()?,
            configured_api,
            request_number,
            purpose,
        )
    }

    /// Joins the queue with the code the owner got for the device. The
    /// request is saved on the EFI partition before the join. The code of
    /// the current request sends the same join again.
    pub fn join_queue(
        &self,
        request_number: u32,
        purpose: &str,
        code: &RecoveryCode,
    ) -> Result<KeyStatus, RecoveryFailure> {
        let new_request = || {
            Ok(KeyRequest {
                request_number,
                files: read_device_files()?,
                api: configured_api()?,
                code: code.clone(),
                purpose: purpose.to_string(),
                return_key: ReturnKey::new()
                    .map_err(request_step_failure("make a return key"))?,
                request_id: None,
                recovery_key: None,
            })
        };
        join_with_code(
            &mut self.lock_request(),
            request_number,
            code,
            new_request,
        )
    }

    /// Checks the request once, and takes the key when it is there. A
    /// request that ended at the service is forgotten here too.
    pub fn check_request(
        &self,
        request_number: u32,
    ) -> Result<KeyStatus, RecoveryFailure> {
        check_current_request(&mut self.lock_request(), request_number)
    }

    /// Cancels the request at the service and removes the saved request.
    /// When the service does not take the cancel, both stay.
    pub fn cancel_request(
        &self,
        request_number: u32,
    ) -> Result<(), RecoveryFailure> {
        cancel_current_request(&mut self.lock_request(), request_number)
    }

    /// Ends the request after the repair: removes the saved request, then
    /// acknowledges the result at the service.
    pub fn end_request(&self, request_number: u32) {
        end_current_request(&mut self.lock_request(), request_number);
    }

    /// The key the request received, if it did.
    pub fn received_key(&self, request_number: u32) -> Option<RecoveryKey> {
        let request = self.lock_request();
        let request = request
            .as_ref()
            .filter(|request| request.request_number == request_number)?;
        request.recovery_key.clone()
    }

    fn lock_request(&self) -> MutexGuard<'_, Option<KeyRequest>> {
        self.request.lock().unwrap_or_else(|poisoned| poisoned.into_inner())
    }
}

/// What the request saved before the device was turned off was made for,
/// if one waits to continue.
pub fn read_saved_purpose() -> Option<String> {
    let contents = EfiPartition::mount()
        .and_then(|partition| partition.read_saved_request())
        .ok()??;
    let saved_request: SavedRequest = serde_json::from_slice(&contents).ok()?;
    Some(saved_request.purpose.clone())
}

impl KeyRequest {
    /// Where the request stands. A request without an answered join joins
    /// with its code.
    fn read_status(&mut self) -> Result<KeyStatus, RecoveryFailure> {
        let Some(request_id) = &self.request_id else {
            return self.join_when_free();
        };
        let status =
            self.api.read_request(request_id).map_err(recovery_failure_of)?;
        let progress = self.receive_status(&status)?;
        Ok(KeyStatus {
            progress,
            check_interval: check_interval(status.poll_seconds),
        })
    }

    /// Joins with the code of the request, and waits while another join
    /// holds it.
    fn join_when_free(&mut self) -> Result<KeyStatus, RecoveryFailure> {
        match self.join_queue() {
            Err(RecoveryFailure::CodeInUse) => {
                debug!("another join holds the code");
                Ok(KeyStatus {
                    progress: KeyProgress::WaitingForCode,
                    check_interval: CODE_IN_USE_INTERVAL,
                })
            }
            result => result,
        }
    }

    /// Joins the queue and saves the id the service gave.
    fn join_queue(&mut self) -> Result<KeyStatus, RecoveryFailure> {
        let public_key = self
            .return_key
            .public_der()
            .map_err(request_step_failure("encode the return key"))?;
        let device = Device {
            organisation_id: &self.files.identity.organisation_id,
            serial_number: &self.files.identity.serial_number,
        };
        let joined_request = self
            .api
            .join(&device, &self.code, &self.files.bundle, &public_key)
            .map_err(|failure| match failure {
                ApiFailure::NotFound => RecoveryFailure::CodeNotAccepted,
                other => recovery_failure_of(other),
            })?;
        debug!("joined the queue");

        self.request_id = Some(joined_request.id);
        // Without the id, the request is found again by sending the same
        // join.
        if let Err(failure) = self.save() {
            warn!("failed to save the id of the request: {failure:?}");
        }
        Ok(KeyStatus {
            progress: KeyProgress::WaitingForKey(None),
            check_interval: check_interval(joined_request.poll_seconds),
        })
    }

    fn save(&self) -> Result<(), RecoveryFailure> {
        let return_key = self
            .return_key
            .to_pkcs8_der()
            .map_err(request_step_failure("encode the return key"))?;
        let saved_request = SavedRequest {
            id: self
                .request_id
                .as_ref()
                .map(|request_id| request_id.as_str().to_string()),
            code: self.code.as_str().to_string(),
            return_key: BASE64.encode(return_key.as_slice()),
            purpose: self.purpose.clone(),
        };
        let contents = Zeroizing::new(
            serde_json::to_vec(&saved_request)
                .map_err(request_step_failure("encode the saved request"))?,
        );
        self.files
            .partition
            .write_saved_request(&contents)
            .map_err(request_step_failure("save the request"))
    }

    /// Where the request stands by the answer of the service, with the key
    /// taken when it is there.
    fn receive_status(
        &mut self,
        status: &RequestStatus,
    ) -> Result<KeyProgress, RecoveryFailure> {
        debug!("the recovery request is {:?}", status.state);
        match status.state {
            RequestState::Queued => Ok(KeyProgress::WaitingForKey(
                status.queue_position.map(|position| QueuePlace { position }),
            )),
            RequestState::Done => {
                let result = status.result.as_deref().ok_or_else(|| {
                    warn!("the answer lacks the result");
                    RecoveryFailure::Failed
                })?;
                self.receive_key(result)?;
                Ok(KeyProgress::KeyReceived)
            }
            RequestState::Failed => Err(key_service_failure_of(status)),
        }
    }

    fn receive_key(&mut self, result: &str) -> Result<(), RecoveryFailure> {
        let ciphertext = BASE64
            .decode(result)
            .map_err(request_step_failure("decode the result"))?;
        let recovery_key = self
            .return_key
            .decrypt(&ciphertext)
            .map_err(request_step_failure("decrypt the result"))?;
        if recovery_key.len() > MAX_RECOVERY_KEY_LENGTH {
            warn!("the recovery key is {} bytes long", recovery_key.len());
            return Err(RecoveryFailure::Failed);
        }
        debug!("received the recovery key");
        self.recovery_key = Some(RecoveryKey(recovery_key));
        Ok(())
    }
}

/// Continues the saved request, if there is one.
fn resume_saved_request(
    current: &mut Option<KeyRequest>,
    files: DeviceFiles,
    api: impl FnOnce() -> Result<RecoveryApi, RecoveryFailure>,
    request_number: u32,
    purpose: &str,
) -> Result<Option<KeyStatus>, RecoveryFailure> {
    let Some(contents) = files.partition.read_saved_request().ok().flatten()
    else {
        return Ok(None);
    };
    let contents = Zeroizing::new(contents);
    let Some((request_id, code, return_key)) = parse_saved_request(&contents)
    else {
        warn!("the saved recovery request is unreadable");
        remove_saved_request(&files.partition);
        return Ok(None);
    };

    debug!("continuing the saved recovery request");
    let mut saved_request = KeyRequest {
        request_number,
        files,
        api: api()?,
        code,
        purpose: purpose.to_string(),
        return_key,
        request_id,
        recovery_key: None,
    };
    match saved_request.read_status() {
        Ok(status) => {
            *current = Some(saved_request);
            Ok(Some(status))
        }
        Err(RecoveryFailure::CodeNotAccepted | RecoveryFailure::CodeEnded) => {
            debug!("the code of the saved request has ended");
            remove_saved_request(&saved_request.files.partition);
            Ok(None)
        }
        Err(failure) if is_ended_at_service(failure) => {
            remove_saved_request(&saved_request.files.partition);
            Err(failure)
        }
        // Kept, so a later cancel or end still finds it.
        Err(failure) => {
            *current = Some(saved_request);
            Err(failure)
        }
    }
}

/// Joins with a code. The code of the current request sends its join
/// again, so a join whose answer was lost finds its request. Another code
/// makes a new request.
fn join_with_code(
    current: &mut Option<KeyRequest>,
    request_number: u32,
    code: &RecoveryCode,
    new_request: impl FnOnce() -> Result<KeyRequest, RecoveryFailure>,
) -> Result<KeyStatus, RecoveryFailure> {
    match current.take() {
        Some(mut same_code) if same_code.code == *code => {
            same_code.request_number = request_number;
            join_new_request(current, same_code, None)
        }
        earlier_request => {
            let new_request = match new_request() {
                Ok(new_request) => new_request,
                Err(failure) => {
                    *current = earlier_request;
                    return Err(failure);
                }
            };
            join_new_request(current, new_request, earlier_request)
        }
    }
}

/// Saves a new request and joins the queue with it. A join without an
/// answer stays saved and is sent again later. A join the service refused
/// leaves the earlier request saved, or nothing.
fn join_new_request(
    current: &mut Option<KeyRequest>,
    mut new_request: KeyRequest,
    earlier_request: Option<KeyRequest>,
) -> Result<KeyStatus, RecoveryFailure> {
    new_request.save()?;
    let failure = match new_request.join_queue() {
        Ok(status) => {
            *current = Some(new_request);
            return Ok(status);
        }
        Err(
            failure @ (RecoveryFailure::Unreachable
            | RecoveryFailure::Untrusted),
        ) => {
            *current = Some(new_request);
            return Err(failure);
        }
        Err(failure) => failure,
    };

    // A mistyped code must not lose a request whose join may hold the
    // right one.
    match earlier_request {
        Some(earlier_request) => {
            if let Err(error) = earlier_request.save() {
                warn!("failed to save the earlier request again: {error:?}");
            }
            *current = Some(earlier_request);
        }
        None => remove_saved_request(&new_request.files.partition),
    }
    Err(failure)
}

fn check_current_request(
    current: &mut Option<KeyRequest>,
    request_number: u32,
) -> Result<KeyStatus, RecoveryFailure> {
    let Some(request) = current
        .as_mut()
        .filter(|request| request.request_number == request_number)
    else {
        return Err(RecoveryFailure::Ended);
    };
    if request.recovery_key.is_some() {
        return Ok(KeyStatus {
            progress: KeyProgress::KeyReceived,
            check_interval: Duration::ZERO,
        });
    }

    // A code that no longer works means the recovery ended.
    let result = request.read_status().map_err(|failure| match failure {
        RecoveryFailure::CodeNotAccepted | RecoveryFailure::CodeEnded => {
            RecoveryFailure::Ended
        }
        other => other,
    });
    if let Err(failure) = result {
        if is_ended_at_service(failure) {
            if let Some(ended_request) = current.take() {
                remove_saved_request(&ended_request.files.partition);
            }
        }
    }
    result
}

fn cancel_current_request(
    current: &mut Option<KeyRequest>,
    request_number: u32,
) -> Result<(), RecoveryFailure> {
    let Some(request) = current
        .as_mut()
        .filter(|request| request.request_number == request_number)
    else {
        return Ok(());
    };

    // A join whose answer was lost may hold the code, and the same join
    // tells its id. A code another join holds or that ended holds nothing
    // of this device.
    if request.request_id.is_none() {
        match request.join_queue() {
            Ok(_)
            | Err(
                RecoveryFailure::CodeInUse
                | RecoveryFailure::CodeNotAccepted
                | RecoveryFailure::CodeEnded,
            ) => {}
            Err(failure) => {
                warn!("failed to find the request to cancel: {failure:?}");
                return Err(RecoveryFailure::NotCancelled);
            }
        }
    }
    if let Some(request_id) = &request.request_id {
        if let Err(failure) = delete_request(&request.api, request_id) {
            warn!("failed to cancel the recovery request: {failure:?}");
            return Err(RecoveryFailure::NotCancelled);
        }
    }

    if let Some(cancelled_request) = current.take() {
        remove_saved_request(&cancelled_request.files.partition);
    }
    debug!("cancelled the recovery request");
    Ok(())
}

/// Removes the saved request first, so a restart while the service is out
/// of reach leaves no private key behind. The result then waits at the
/// service until its lifetime ends, and nothing can decrypt it.
fn end_current_request(current: &mut Option<KeyRequest>, request_number: u32) {
    match current.take() {
        Some(ended_request)
            if ended_request.request_number == request_number =>
        {
            remove_saved_request(&ended_request.files.partition);
            if let Some(request_id) = &ended_request.request_id {
                if let Err(failure) =
                    delete_request(&ended_request.api, request_id)
                {
                    warn!("failed to acknowledge the result: {failure:?}");
                }
            }
        }
        Some(newer_request) => *current = Some(newer_request),
        // A saved request that never resumed.
        None => {
            if let Ok(partition) = EfiPartition::mount() {
                remove_saved_request(&partition);
            }
        }
    }
}

/// Whether the service ended or failed the request, which is then forgotten
/// on the device. A failed request is not deleted, so the same code joins
/// again.
fn is_ended_at_service(failure: RecoveryFailure) -> bool {
    matches!(
        failure,
        RecoveryFailure::Ended | RecoveryFailure::KeyServiceFailed
    )
}

/// Deletes a request at the service, with a few tries for a short break in
/// the network. A request the service no longer knows counts as deleted.
fn delete_request(
    api: &RecoveryApi,
    request_id: &RequestId,
) -> Result<(), ApiFailure> {
    let mut attempt = 1;
    loop {
        match api.delete_request(request_id) {
            Ok(()) | Err(ApiFailure::NotFound) => return Ok(()),
            Err(failure) if attempt == DELETE_ATTEMPTS => return Err(failure),
            Err(failure) => {
                debug!("failed to delete the recovery request: {failure:?}");
            }
        }
        attempt += 1;
        std::thread::sleep(DELETE_PAUSE);
    }
}

fn remove_saved_request(partition: &EfiPartition) {
    if let Err(error) = partition.remove_saved_request() {
        warn!("failed to remove the saved request: {error}");
    }
}

/// The EFI partition and the bundle as the installer wrote it.
fn read_device_files() -> Result<DeviceFiles, RecoveryFailure> {
    let partition = EfiPartition::mount().map_err(|error| {
        warn!("failed to mount the EFI partition: {error}");
        RecoveryFailure::NoBundle
    })?;
    read_files_of(partition)
}

fn read_files_of(
    partition: EfiPartition,
) -> Result<DeviceFiles, RecoveryFailure> {
    let no_bundle = |error: &dyn std::fmt::Display| {
        warn!("failed to read the recovery bundle: {error}");
        RecoveryFailure::NoBundle
    };
    let bundle = partition.read_bundle().map_err(|error| no_bundle(&error))?;
    let identity =
        serde_json::from_slice(&bundle).map_err(|error| no_bundle(&error))?;
    Ok(DeviceFiles { partition, bundle, identity })
}

/// The id, the code and the return key of a saved request.
fn parse_saved_request(
    contents: &[u8],
) -> Option<(Option<RequestId>, RecoveryCode, ReturnKey)> {
    let saved_request: SavedRequest = serde_json::from_slice(contents).ok()?;
    let request_id = match &saved_request.id {
        Some(id) => Some(RequestId::try_from(id.clone()).ok()?),
        None => None,
    };
    let code = RecoveryCode::parse(&saved_request.code)?;
    let private_key =
        Zeroizing::new(BASE64.decode(&saved_request.return_key).ok()?);
    let return_key = ReturnKey::from_pkcs8_der(&private_key).ok()?;
    Some((request_id, code, return_key))
}

/// The service at the address of the build.
fn configured_api() -> Result<RecoveryApi, RecoveryFailure> {
    let address = std::fs::read_to_string(ADDRESS)
        .map_err(not_configured_after_failing_to("read the address"))?;
    new_recovery_api(&address)?.ok_or_else(|| {
        warn!("failed to use the address or the authorities");
        RecoveryFailure::NotConfigured
    })
}

/// The service at an address, trusted with the authorities of the build.
#[cfg(not(feature = "development"))]
fn new_recovery_api(
    address: &str,
) -> Result<Option<RecoveryApi>, RecoveryFailure> {
    let authorities = std::fs::read(AUTHORITIES)
        .map_err(not_configured_after_failing_to("read the authorities"))?;
    Ok(RecoveryApi::new(address, &authorities))
}

/// A development build trusts the service at its address without checking
/// it, so it works with a test server.
#[cfg(feature = "development")]
fn new_recovery_api(
    address: &str,
) -> Result<Option<RecoveryApi>, RecoveryFailure> {
    Ok(RecoveryApi::new_unverified(address))
}

fn key_service_failure_of(status: &RequestStatus) -> RecoveryFailure {
    let code = status.error.as_ref().map(|error| error.code.as_str());
    warn!("the key service failed the request: {code:?}");
    RecoveryFailure::KeyServiceFailed
}

/// A failure of a step, with its cause in the log.
fn request_step_failure<E: std::fmt::Debug>(
    step: &str,
) -> impl Fn(E) -> RecoveryFailure + '_ {
    step_failure(step, RecoveryFailure::Failed)
}

fn not_configured_after_failing_to<E: std::fmt::Debug>(
    step: &str,
) -> impl Fn(E) -> RecoveryFailure + '_ {
    step_failure(step, RecoveryFailure::NotConfigured)
}

fn step_failure<E: std::fmt::Debug>(
    step: &str,
    failure: RecoveryFailure,
) -> impl Fn(E) -> RecoveryFailure + '_ {
    move |error| {
        warn!("failed to {step}: {error:?}");
        failure
    }
}

fn check_interval(poll_seconds: u64) -> Duration {
    Duration::from_secs(poll_seconds.clamp(MIN_POLL_SECONDS, MAX_POLL_SECONDS))
}

fn recovery_failure_of(failure: ApiFailure) -> RecoveryFailure {
    warn!("the recovery service call failed: {failure:?}");
    match failure {
        ApiFailure::Unreachable => RecoveryFailure::Unreachable,
        ApiFailure::Untrusted => RecoveryFailure::Untrusted,
        ApiFailure::NotFound => RecoveryFailure::Ended,
        ApiFailure::CodeInUse => RecoveryFailure::CodeInUse,
        ApiFailure::CodeEnded => RecoveryFailure::CodeEnded,
        ApiFailure::BadInput => RecoveryFailure::DeviceRefused,
        ApiFailure::Refused => RecoveryFailure::Failed,
    }
}

#[cfg(test)]
mod tests;

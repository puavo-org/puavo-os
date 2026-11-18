//! The calls of the device to the recovery service, as the recovery API
//! defines them. The service is trusted only with a
//! certificate from the authority the build names.

use std::sync::Arc;
use std::time::Duration;

use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine;
use log::debug;
use serde::{Deserialize, Serialize};
use ureq::http::Uri;
use ureq::tls::TlsConfig;
#[cfg(not(feature = "development"))]
use ureq::tls::{parse_pem, Certificate, PemItem, RootCerts};
use ureq::Agent;

use super::RecoveryCode;

const REQUESTS_PATH: &str = "/v3/recovery/requests";
const HTTPS: &str = "https";
#[cfg(any(test, feature = "development"))]
const HTTP: &str = "http";
const CALL_TIMEOUT: Duration = Duration::from_secs(30);
const MAX_ANSWER_LENGTH: u64 = 64 * 1024;

const OK: u16 = 200;
const CREATED: u16 = 201;
const BAD_REQUEST: u16 = 400;
const NOT_FOUND: u16 = 404;
const CONFLICT: u16 = 409;
/// The code of a conflict when another join of the code is queued.
const CODE_IN_USE: &str = "CodeInUse";
/// Server errors, which pass like a break in the network.
const SERVER_ERRORS: std::ops::RangeInclusive<u16> = 500..=599;

/// The length of a request identifier: 32 bytes in base64url without padding.
const REQUEST_ID_LENGTH: usize = 43;

/// Why a call failed.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ApiFailure {
    /// The service did not answer.
    Unreachable,
    /// The service did not prove that it is the one the build trusts.
    Untrusted,
    /// The service does not know the request, or it has ended. For a join:
    /// no recovery of the device takes the code.
    NotFound,
    /// Another join of the code waits in the queue.
    CodeInUse,
    /// The recovery of the code is done.
    CodeEnded,
    /// The service found the call malformed or not for its organisation.
    BadInput,
    /// The service refused the call, or its answer did not follow the API.
    Refused,
}

/// The states of a request, as the service reports them to the device.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum RequestState {
    Queued,
    Done,
    Failed,
}

/// A request that joined the queue, or the same join sent again.
#[derive(Deserialize)]
pub struct JoinedRequest {
    pub id: RequestId,
    pub poll_seconds: u64,
}

/// How a request stands.
#[derive(Deserialize)]
pub struct RequestStatus {
    id: String,
    pub state: RequestState,
    pub poll_seconds: u64,
    /// The recovery key encrypted to the return key, once it is there.
    pub result: Option<String>,
    /// While queued, 1 for the next request the key service takes.
    pub queue_position: Option<u32>,
    /// Why the request failed, when it did.
    pub error: Option<RequestError>,
}

/// Why the key service failed a request, such as UnwrapFailed, or why the
/// service refused a call.
#[derive(Deserialize)]
pub struct RequestError {
    pub code: String,
}

/// The answer of a refused call.
#[derive(Deserialize)]
struct ErrorAnswer {
    error: RequestError,
}

/// The identifier of a request, which is the device's credential for it. It is
/// checked to be base64url, so it is safe to place in a path.
#[derive(Clone, Deserialize)]
#[serde(try_from = "String")]
pub struct RequestId(String);

impl RequestId {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl TryFrom<String> for RequestId {
    type Error = &'static str;

    fn try_from(text: String) -> Result<Self, Self::Error> {
        let base64url = text.bytes().all(|byte| {
            byte.is_ascii_alphanumeric() || byte == b'-' || byte == b'_'
        });
        if text.len() != REQUEST_ID_LENGTH || !base64url {
            return Err("malformed request identifier");
        }
        Ok(RequestId(text))
    }
}

/// The device in a join: what the bundle names it, the code of its
/// recovery, and what the key service needs.
#[derive(Serialize)]
struct Join<'a> {
    organisation_id: &'a str,
    serial_number: &'a str,
    code: &'a str,
    bundle: String,
    return_public_key: String,
}

/// The device a join names.
pub struct Device<'a> {
    pub organisation_id: &'a str,
    pub serial_number: &'a str,
}

/// A recovery service at one address.
pub struct RecoveryApi {
    agent: Agent,
    address: String,
}

impl RecoveryApi {
    /// A service at an address such as https://example.org, trusted when
    /// its certificate comes from one of the authorities in PEM form. The
    /// address is refused unless it is HTTPS with a host and nothing more.
    #[cfg(not(feature = "development"))]
    pub fn new(address: &str, authorities: &[u8]) -> Option<Self> {
        let address = parse_address(address, &[HTTPS])?;
        let authorities: Vec<Certificate<'static>> = parse_pem(authorities)
            .filter_map(|item| match item {
                Ok(PemItem::Certificate(certificate)) => Some(certificate),
                _ => None,
            })
            .collect();
        if authorities.is_empty() {
            return None;
        }

        let tls_configuration = TlsConfig::builder()
            .root_certs(RootCerts::Specific(Arc::new(authorities)))
            .unversioned_rustls_crypto_provider(Arc::new(
                rustls::crypto::ring::default_provider(),
            ))
            .build();
        Some(RecoveryApi { agent: new_agent(tls_configuration), address })
    }

    /// A service at an HTTPS or HTTP address, trusted without checking its
    /// certificate, for a development build and a test server.
    #[cfg(any(test, feature = "development"))]
    pub fn new_unverified(address: &str) -> Option<Self> {
        let address = parse_address(address, &[HTTPS, HTTP])?;
        let tls_configuration = TlsConfig::builder()
            .disable_verification(true)
            .unversioned_rustls_crypto_provider(Arc::new(
                rustls::crypto::ring::default_provider(),
            ))
            .build();
        Some(RecoveryApi { agent: new_agent(tls_configuration), address })
    }

    /// Joins the queue with the code of the recovery the owner opened for
    /// the device. The first join of a code wins, and the same join sent
    /// again gets the same request.
    pub fn join(
        &self,
        device: &Device,
        code: &RecoveryCode,
        bundle: &[u8],
        return_public_key: &[u8],
    ) -> Result<JoinedRequest, ApiFailure> {
        let body = Join {
            organisation_id: device.organisation_id,
            serial_number: device.serial_number,
            code: code.as_str(),
            bundle: BASE64.encode(bundle),
            return_public_key: BASE64.encode(return_public_key),
        };
        debug!("joining the queue");
        let response = self
            .agent
            .post(format!("{}{REQUESTS_PATH}", self.address))
            .config()
            .http_status_as_error(false)
            .build()
            .send_json(&body)
            .map_err(api_failure_of)?;

        let status = response.status().as_u16();
        match status {
            OK | CREATED => read_answer(response),
            CONFLICT => {
                let answer: Result<ErrorAnswer, _> = read_answer(response);
                if answer.is_ok_and(|answer| answer.error.code == CODE_IN_USE) {
                    return Err(ApiFailure::CodeInUse);
                }
                Err(ApiFailure::CodeEnded)
            }
            _ => Err(api_failure_of(ureq::Error::StatusCode(status))),
        }
    }

    pub fn read_request(
        &self,
        request_id: &RequestId,
    ) -> Result<RequestStatus, ApiFailure> {
        debug!("reading the request");
        let response = self
            .agent
            .get(self.request_path(request_id))
            .call()
            .map_err(api_failure_of)?;
        let status: RequestStatus = read_answer(response)?;
        if status.id != request_id.0 {
            return Err(ApiFailure::Refused);
        }
        Ok(status)
    }

    /// Ends a request, as the acknowledgement of its result or as a cancel.
    pub fn delete_request(
        &self,
        request_id: &RequestId,
    ) -> Result<(), ApiFailure> {
        debug!("deleting the request");
        self.agent
            .delete(self.request_path(request_id))
            .call()
            .map_err(api_failure_of)?;
        Ok(())
    }

    fn request_path(&self, request_id: &RequestId) -> String {
        format!("{}{REQUESTS_PATH}/{}", self.address, request_id.0)
    }
}

/// An agent that refuses plain HTTP, except in a development build and in
/// tests, which talk to a test server.
fn new_agent(tls_configuration: TlsConfig) -> Agent {
    Agent::config_builder()
        .tls_config(tls_configuration)
        .https_only(!cfg!(any(test, feature = "development")))
        .proxy(None)
        .max_redirects(0)
        .timeout_global(Some(CALL_TIMEOUT))
        .build()
        .new_agent()
}

/// Keeps the scheme and host of an address of one of the schemes and
/// refuses anything else, so a written address leads the calls only to a
/// host.
fn parse_address(address: &str, schemes: &[&str]) -> Option<String> {
    let uri: Uri = address.trim().parse().ok()?;
    let scheme = uri.scheme_str()?;
    if !schemes.contains(&scheme) || uri.query().is_some() {
        return None;
    }
    if !matches!(uri.path(), "" | "/") {
        return None;
    }
    let authority = uri.authority()?;
    if authority.as_str().contains('@') {
        return None;
    }
    Some(format!("{scheme}://{authority}"))
}

fn read_answer<T: serde::de::DeserializeOwned>(
    mut response: ureq::http::Response<ureq::Body>,
) -> Result<T, ApiFailure> {
    response
        .body_mut()
        .with_config()
        .limit(MAX_ANSWER_LENGTH)
        .read_json()
        .map_err(|_| ApiFailure::Refused)
}

fn api_failure_of(error: ureq::Error) -> ApiFailure {
    match error {
        ureq::Error::StatusCode(NOT_FOUND) => ApiFailure::NotFound,
        ureq::Error::StatusCode(BAD_REQUEST) => ApiFailure::BadInput,
        ureq::Error::StatusCode(status) if SERVER_ERRORS.contains(&status) => {
            ApiFailure::Unreachable
        }
        ureq::Error::StatusCode(_) => ApiFailure::Refused,
        ureq::Error::Tls(_) | ureq::Error::Rustls(_) => ApiFailure::Untrusted,
        ureq::Error::Io(error) if is_tls_error(&error) => ApiFailure::Untrusted,
        _ => ApiFailure::Unreachable,
    }
}

/// Whether a failed read or write was the certificate check of the
/// connection, which the TLS stream reports as an IO error.
fn is_tls_error(error: &std::io::Error) -> bool {
    error
        .get_ref()
        .is_some_and(|inner| inner.downcast_ref::<rustls::Error>().is_some())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn an_address_keeps_only_its_scheme_and_host() {
        assert_eq!(
            parse_address("https://example.org/\n", &[HTTPS]).as_deref(),
            Some("https://example.org")
        );
        assert_eq!(
            parse_address("https://example.org:8443", &[HTTPS]).as_deref(),
            Some("https://example.org:8443")
        );
    }

    #[test]
    fn an_address_with_more_than_a_host_is_refused() {
        assert_eq!(parse_address("http://example.org", &[HTTPS]), None);
        assert_eq!(parse_address("https://example.org/other", &[HTTPS]), None);
        assert_eq!(parse_address("https://example.org/?a=b", &[HTTPS]), None);
        assert_eq!(parse_address("https://user@example.org", &[HTTPS]), None);
    }

    #[test]
    fn a_test_server_may_have_a_plain_address() {
        let address = parse_address("http://example.org", &[HTTPS, HTTP]);
        assert_eq!(address.as_deref(), Some("http://example.org"));
        assert!(RecoveryApi::new_unverified("http://example.org").is_some());
        assert!(RecoveryApi::new_unverified("ftp://example.org").is_none());
    }

    #[test]
    fn a_request_id_that_could_change_the_path_is_refused() {
        let valid = "A".repeat(REQUEST_ID_LENGTH);
        assert!(RequestId::try_from(valid).is_ok());
        let path = format!("{}/..", "A".repeat(REQUEST_ID_LENGTH - 3));
        assert!(RequestId::try_from(path).is_err());
    }
}

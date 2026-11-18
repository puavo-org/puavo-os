//! Getting the recovery key of the device from the recovery service. An
//! owner opens a recovery for the device elsewhere and tells the person a
//! code. The device joins the queue of the key service with the code, and
//! the key arrives encrypted to a key pair made for the request. The first
//! join of a code wins. The request is saved on the EFI partition until it
//! ends, so the device may be off while it waits.
//!
//! ```text
//!   code ──> join ──> queued ──> key ──> vault repaired ──> ended
//!              │         │
//!            saved     cancel ──> the same code joins again
//! ```

mod api;
mod code;
mod key_recovery;
mod return_key;

use std::time::Duration;

use zeroize::Zeroizing;

pub use code::RecoveryCode;
pub use key_recovery::{read_saved_purpose, ServiceKeyRecovery};

/// Whether this build talks to its service without checking its
/// certificate. The interface marks such a build on every screen.
pub const DEVELOPMENT: bool = cfg!(feature = "development");

/// Where a request waits for the key service.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct QueuePlace {
    /// 1 for the next request the key service takes.
    pub position: u32,
}

/// How far the request for the key has come.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum KeyProgress {
    /// Another join holds the code of the saved request. The device joins
    /// when the code is free.
    WaitingForCode,
    /// The place in the queue, unknown until the first check.
    WaitingForKey(Option<QueuePlace>),
    /// The key is in memory.
    KeyReceived,
}

/// The key that opens the boot vault, kept out of debug output and wiped
/// when dropped.
#[derive(Clone, Default)]
pub struct RecoveryKey(Zeroizing<Vec<u8>>);

impl RecoveryKey {
    pub fn as_bytes(&self) -> &[u8] {
        &self.0
    }
}

/// How the request for the key stands, and when to check it again.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct KeyStatus {
    pub progress: KeyProgress,
    pub check_interval: Duration,
}

/// Why getting the key failed.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RecoveryFailure {
    /// The EFI partition has no readable recovery bundle.
    NoBundle,
    /// The build configured no usable service.
    NotConfigured,
    Unreachable,
    Untrusted,
    /// The service took no recovery of this device with the code.
    CodeNotAccepted,
    /// Another join of the code waits in the queue.
    CodeInUse,
    /// The recovery of the code is done.
    CodeEnded,
    /// The service found the device's call malformed or not for its
    /// organisation.
    DeviceRefused,
    /// The cancel did not reach the service, so the request stays.
    NotCancelled,
    /// The recovery ended at the service.
    Ended,
    /// The key service failed to give the key.
    KeyServiceFailed,
    Failed,
}

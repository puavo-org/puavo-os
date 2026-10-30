use std::{
    path::{Path, PathBuf},
    process::{Command, Stdio},
    sync::{Mutex, OnceLock},
    time::Duration,
};

use log::{info, warn};

use crate::system::process;

/// Program that collects the diagnostics and saves them
const MANAGER: &str =
    "/usr/lib/puavo-ltsp-install/puavo-manage-boot-diagnostics";

/// EFI partition the saves go to. Saving is off until it is set.
static EFI_MOUNTPOINT: OnceLock<PathBuf> = OnceLock::new();

/// The save requested to start in the finish function
static REQUESTED: Mutex<Option<DiagnosticsKind>> = Mutex::new(None);

/// A save during the boot, named by what triggered it
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DiagnosticsKind {
    /// After configurators changed the boot state
    Update,
    /// When the recovery prompt becomes visible
    Failure,
}

impl DiagnosticsKind {
    /// Arguments of the manager for this save.
    fn arguments(self) -> &'static [&'static str] {
        match self {
            DiagnosticsKind::Update => &["--name", "update"],
            DiagnosticsKind::Failure => &["--name", "failure", "--kernel-log"],
        }
    }
}

/// Turns saving on, to the EFI partition mounted at the given path.
pub fn enable(efi_mountpoint: &Path) {
    let _ = EFI_MOUNTPOINT.set(efi_mountpoint.to_path_buf());
}

/// Starts a save in the background. Does nothing while saving is off.
/// The finish function waits for it.
pub fn collect(kind: DiagnosticsKind) {
    let Some(efi_mountpoint) = EFI_MOUNTPOINT.get() else {
        return;
    };

    let spawned = Command::new(MANAGER)
        .args(kind.arguments())
        .arg(efi_mountpoint)
        .stdin(Stdio::null())
        .spawn();

    match spawned {
        Ok(child) => {
            info!("Saving {:?} diagnostics, process {}", kind, child.id())
        }
        Err(error) => warn!("Failed to run {}: {}", MANAGER, error),
    }
}

/// Requests a save to start in the finish function. A later request
/// replaces an earlier one, so repeats are saved once.
pub fn request(kind: DiagnosticsKind) {
    if let Ok(mut requested) = REQUESTED.lock() {
        *requested = Some(kind);
    }
}

/// Starts the requested save, then waits until every save has finished or
/// the timeout passes.
pub fn finish(timeout: Duration) {
    let requested =
        REQUESTED.lock().ok().and_then(|mut requested| requested.take());

    if let Some(kind) = requested {
        collect(kind);
    }

    process::wait_for_children(timeout);
}

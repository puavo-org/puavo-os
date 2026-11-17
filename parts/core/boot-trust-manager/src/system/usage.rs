use std::sync::OnceLock;

/// How the manager is used.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Usage {
    /// In the boot of the system whose disk it manages.
    Boot,
    /// By another system, on a disk of a system that is not running. The
    /// checks and records of the running system are skipped, the questions
    /// are answered on standard input, and a requested reboot is ignored.
    Tool,
}

static USAGE: OnceLock<Usage> = OnceLock::new();

/// Sets how the manager is used, once, before it does anything.
pub fn set(usage: Usage) {
    let _ = USAGE.set(usage);
}

/// How the manager is used, a boot until set.
pub fn current() -> Usage {
    USAGE.get().copied().unwrap_or(Usage::Boot)
}

//! Writes the log of the recovery to standard error, which the service of
//! the environment sends to the journal. Other libraries log their
//! warnings and errors only.

use log::{Level, LevelFilter, Log, Metadata, Record};

/// The start of the log targets of the recovery crates.
const RECOVERY_TARGETS: &str = "recovery_";

struct StandardErrorLogger;

impl Log for StandardErrorLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= Level::Warn
            || metadata.target().starts_with(RECOVERY_TARGETS)
    }

    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            eprintln!(
                "{} {}: {}",
                record.level(),
                record.target(),
                record.args()
            );
        }
    }

    fn flush(&self) {}
}

static LOGGER: StandardErrorLogger = StandardErrorLogger;

pub fn start_logging() {
    if log::set_logger(&LOGGER).is_ok() {
        log::set_max_level(LevelFilter::Debug);
    }
}

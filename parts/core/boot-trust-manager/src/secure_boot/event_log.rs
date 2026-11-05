//! Reads the firmware event log that the kernel publishes. The format is in
//! TCG PC Client Platform Firmware Profile 1.06 section 10.

use std::{collections::BTreeMap, fs, path::Path};

use crate::{bytes::ByteReader, error::PuavoError};

/// The log of this machine.
pub const EVENT_LOG: &str =
    "/sys/kernel/security/tpm0/binary_bios_measurements";

/// Signature of the first event, which lists the digest algorithms of the
/// log.
const SPEC_ID_SIGNATURE: &[u8] = b"Spec ID Event03\0";

/// Size of the fields before the data size in the first event, which has
/// the old format: PCR index, event type and a SHA-1 digest.
const FIRST_EVENT_BYTES: usize = 4 + 4 + 20;

/// Offset of numberOfAlgorithms in TCG_EfiSpecIDEvent.
const ALGORITHM_COUNT_OFFSET: usize = 24;

/// EV_NO_ACTION. These events are logged but not extended.
const NO_ACTION: u32 = 3;

/// TPM_ALG_SHA256.
const SHA256: u16 = 0x000B;

/// One event of the log that was extended into a PCR, with its SHA-256
/// digest.
#[derive(Debug, Clone, PartialEq)]
pub struct Event {
    pub register: u32,
    pub digest: Vec<u8>,
}

/// Reads the events of a log file.
pub fn read(path: &Path) -> Result<Vec<Event>, PuavoError> {
    parse(&fs::read(path)?)
}

/// Parses the events of a log.
pub fn parse(log: &[u8]) -> Result<Vec<Event>, PuavoError> {
    let mut reader = ByteReader::new(log);
    let sizes = read_digest_sizes(&mut reader)?;

    let mut events = Vec::new();
    while !reader.is_empty() {
        if let Some(event) = read_event(&mut reader, &sizes)? {
            events.push(event);
        }
    }

    Ok(events)
}

fn log_ends_early() -> PuavoError {
    PuavoError::MalformedEventLog("the log ends early".to_string())
}

/// Reads the first event and returns the digest size of each algorithm the
/// log uses.
fn read_digest_sizes(
    reader: &mut ByteReader,
) -> Result<BTreeMap<u16, usize>, PuavoError> {
    reader.take(FIRST_EVENT_BYTES).ok_or_else(log_ends_early)?;
    let size = reader.read_size().ok_or_else(log_ends_early)?;
    let data = reader.take(size).ok_or_else(log_ends_early)?;

    if !data.starts_with(SPEC_ID_SIGNATURE) {
        return Err(PuavoError::MalformedEventLog(
            "the log does not list its digest algorithms".to_string(),
        ));
    }

    let mut fields = ByteReader::new(data);
    fields.take(ALGORITHM_COUNT_OFFSET).ok_or_else(log_ends_early)?;
    let count = fields.read_u32().ok_or_else(log_ends_early)?;

    let mut sizes = BTreeMap::new();
    for _ in 0..count {
        let algorithm = fields.read_u16().ok_or_else(log_ends_early)?;
        let size = fields.read_u16().ok_or_else(log_ends_early)?;
        sizes.insert(algorithm, usize::from(size));
    }

    Ok(sizes)
}

/// Reads one TCG_PCR_EVENT2. Returns None for an event that was not
/// extended.
fn read_event(
    reader: &mut ByteReader,
    sizes: &BTreeMap<u16, usize>,
) -> Result<Option<Event>, PuavoError> {
    let register = reader.read_u32().ok_or_else(log_ends_early)?;
    let kind = reader.read_u32().ok_or_else(log_ends_early)?;
    let count = reader.read_u32().ok_or_else(log_ends_early)?;

    let mut digest = None;
    for _ in 0..count {
        let algorithm = reader.read_u16().ok_or_else(log_ends_early)?;
        let size = sizes.get(&algorithm).ok_or_else(|| {
            PuavoError::MalformedEventLog(format!(
                "digest of the undeclared algorithm {algorithm:#06x}"
            ))
        })?;
        let value = reader.take(*size).ok_or_else(log_ends_early)?;

        if algorithm == SHA256 {
            digest = Some(value.to_vec());
        }
    }

    let size = reader.read_size().ok_or_else(log_ends_early)?;
    reader.take(size).ok_or_else(log_ends_early)?;

    if kind == NO_ACTION {
        return Ok(None);
    }

    let digest = digest.ok_or_else(|| {
        PuavoError::MalformedEventLog(format!(
            "an event of PCR {register} has no SHA-256 digest"
        ))
    })?;

    Ok(Some(Event { register, digest }))
}

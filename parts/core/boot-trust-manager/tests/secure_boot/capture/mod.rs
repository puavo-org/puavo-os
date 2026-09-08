//! Reads a captured boot, the log the measurements binary printed and the
//! base the counter started from. Every variable and certificate in these
//! tests comes from the capture.

pub(super) mod slab;

use std::collections::BTreeMap;
use std::fs;
use std::path::Path;
use tempfile::TempDir;

use puavo_boot_trust_manager::error::PuavoError;
use puavo_boot_trust_manager::secure_boot::chain::{
    Device, variable_name_and_contents,
};
use uuid::Uuid;

/// Directory of the captures.
const CAPTURES: &str = "tests/fixtures/secure-boot";

/// The register these chains describe.
pub(super) const REGISTER: u32 = 7;

/// The digest bank read from the capture. The firmware logs several.
const BANK: &str = "SHA256";

/// The event type of a variable measurement.
const FIRMWARE_VARIABLE: &str = "EFI_VARIABLE_DRIVER_CONFIG";

/// The event type of an authority measurement. Its data has the layout of a
/// variable measurement, but holds the one database entry that verified the
/// image instead of the whole database.
const AUTHORITY: &str = "EFI_VARIABLE_AUTHORITY";

/// One event of the capture.
pub(super) struct Event {
    register: u32,
    kind: String,
    digest: String,
    data: Vec<u8>,
}

impl Event {
    /// The variable this event measured, or None for other events.
    pub(super) fn variable(&self) -> Option<(String, Vec<u8>)> {
        if ![FIRMWARE_VARIABLE, AUTHORITY].contains(&self.kind.as_str()) {
            return None;
        }

        variable_name_and_contents(&self.data)
    }
}

/// A captured boot.
pub(super) struct Capture {
    events: Vec<Event>,
    registers: BTreeMap<u32, String>,
    base: u64,
}

fn bytes(hex_text: &str) -> Vec<u8> {
    hex::decode(hex_text).expect("capture data is not hex")
}

impl Capture {
    /// Reads a capture by the name of its directory.
    pub(super) fn read(profile: &str) -> Self {
        let directory =
            Path::new(env!("CARGO_MANIFEST_DIR")).join(CAPTURES).join(profile);

        let log = fs::read_to_string(directory.join("measurements")).unwrap();
        let base = fs::read_to_string(directory.join("base"))
            .unwrap_or_else(|_| String::from("0"));

        let mut events: Vec<Event> = Vec::new();
        let mut registers = BTreeMap::new();

        for line in log.lines() {
            let words: Vec<&str> = line.split_whitespace().collect();

            match words.as_slice() {
                ["event", "pcr", register, "type", kind] => {
                    events.push(Event {
                        register: register.parse().unwrap(),
                        kind: kind.to_string(),
                        digest: String::new(),
                        data: Vec::new(),
                    })
                }
                ["digest", BANK, digest] => {
                    events.last_mut().unwrap().digest = digest.to_string()
                }
                ["data", data] => {
                    events.last_mut().unwrap().data.extend(bytes(data))
                }
                ["pcr", register, BANK, value] => {
                    registers
                        .insert(register.parse().unwrap(), value.to_string());
                }
                _ => (),
            }
        }

        Self { events, registers, base: base.trim().parse().unwrap() }
    }

    /// The events of one PCR, in order.
    pub(super) fn events_of(&self, register: u32) -> Vec<&Event> {
        self.events.iter().filter(|event| event.register == register).collect()
    }

    /// The variables the firmware measured, in order. Authority events are
    /// excluded, since they carry one entry rather than the whole variable.
    pub(super) fn measured_variables(&self) -> Vec<(String, Vec<u8>)> {
        self.events_of(REGISTER)
            .iter()
            .filter(|event| event.kind == FIRMWARE_VARIABLE)
            .filter_map(|event| event.variable())
            .collect()
    }

    /// The final value of a PCR.
    pub(super) fn register(&self, register: u32) -> &str {
        &self.registers[&register]
    }
}

/// A machine serving the variables, the base and the PCR value of the
/// captured boot, so that no test reads the machine running it.
pub(super) struct CapturedDevice {
    variables: BTreeMap<String, Vec<u8>>,
    base: u64,
    /// The PCR value, if any.
    register: Option<String>,
}

impl CapturedDevice {
    /// The machine of the capture.
    pub(super) fn of(capture: &Capture) -> Self {
        Self {
            variables: capture.measured_variables().into_iter().collect(),
            base: capture.base,
            register: Some(capture.register(REGISTER).to_string()),
        }
    }
}

impl Device for CapturedDevice {
    fn read_variable(
        &self,
        _vendor: Uuid,
        name: &str,
    ) -> Result<Vec<u8>, PuavoError> {
        self.variables
            .get(name)
            .cloned()
            .ok_or_else(|| PuavoError::NotFound(name.to_string()))
    }

    fn read_nv_index(&self, _index: u32) -> Result<u64, PuavoError> {
        Ok(self.base)
    }

    fn read_register(&self, index: u32) -> Result<String, PuavoError> {
        self.register
            .clone()
            .ok_or_else(|| PuavoError::NotFound(format!("register {index}")))
    }
}

/// Writes the measured variables into files named after the variables and
/// returns the directory with the names in measurement order.
pub(super) fn write_variables_into_directory(
    capture: &Capture,
) -> (TempDir, Vec<String>) {
    let directory = TempDir::new().unwrap();
    let mut names = Vec::new();

    for (name, value) in capture.measured_variables() {
        fs::write(directory.path().join(&name), value).unwrap();
        names.push(name);
    }

    (directory, names)
}

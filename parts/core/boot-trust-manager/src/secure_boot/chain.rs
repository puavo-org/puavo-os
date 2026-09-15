//! Computes the value of a PCR from a chain of measurements declared as data.
//! A change is predicted by replacing the contents a measurement reads.

use std::{collections::BTreeMap, fmt, fs, path::PathBuf};

use log::debug;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::{
    error::PuavoError,
    secure_boot::database::{self, SignatureDatabase},
    system::efi,
    tpm::{read_nv_u64, read_pcrs},
};

/// Vendor GUID of the global UEFI variables.
const GLOBAL_VARIABLES: Uuid =
    Uuid::from_u128(0x8be4df61_93ca_11d2_aa0d_00e098032b8c);

/// Vendor GUID of the signature database variables.
const SECURITY_DATABASES: Uuid =
    Uuid::from_u128(0xd719b2cb_3d3a_4596_a3bc_dad00e67656f);

/// Vendor GUID of the slab authority records.
const SLAB_AUTHORITY_OWNER: Uuid =
    Uuid::from_u128(0xaf20bc5d_65ab_4c7c_80b4_b4efbf5ba588);

/// Variable name of the slab authority records, which use the UEFI variable
/// measurement format.
const SLAB_AUTHORITY_RECORD: &str = "SlabAuthority";

/// NV index of the slab base value.
const SLAB_BASE_INDEX: u32 = 0x0151_4B01;

/// Event data of the separator.
const SEPARATOR: [u8; 4] = [0, 0, 0, 0];

/// A UEFI variable measured into PCR 7.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Variable {
    SecureBoot,
    PlatformKey,
    KeyExchangeKey,
    Database,
    Revocations,
    TimestampDatabase,
    RecoveryDatabase,
}

impl Variable {
    /// Parses a variable name.
    fn from_name(name: &str) -> Result<Self, PuavoError> {
        match name {
            "SecureBoot" => Ok(Variable::SecureBoot),
            "PK" => Ok(Variable::PlatformKey),
            "KEK" => Ok(Variable::KeyExchangeKey),
            "db" => Ok(Variable::Database),
            "dbx" => Ok(Variable::Revocations),
            "dbt" => Ok(Variable::TimestampDatabase),
            "dbr" => Ok(Variable::RecoveryDatabase),
            _ => Err(PuavoError::MalformedChain(format!(
                "'{name}' is not a Secure Boot variable"
            ))),
        }
    }

    /// Returns the vendor GUID, which is part of the measured record.
    fn vendor(self) -> Uuid {
        match self {
            Variable::SecureBoot
            | Variable::PlatformKey
            | Variable::KeyExchangeKey => GLOBAL_VARIABLES,
            Variable::Database
            | Variable::Revocations
            | Variable::TimestampDatabase
            | Variable::RecoveryDatabase => SECURITY_DATABASES,
        }
    }
}

/// The source of the contents of a variable.
#[derive(Debug, Clone, Default, Hash, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Source {
    #[default]
    Device,
    Path(PathBuf),
}

impl Source {
    /// Reads the contents from this source.
    fn contents(
        &self,
        vendor: Uuid,
        name: &str,
        device: &dyn Device,
    ) -> Result<Vec<u8>, PuavoError> {
        match self {
            Source::Device => device.read_variable(vendor, name),
            Source::Path(path) => fs::read(path).map_err(PuavoError::IoError),
        }
    }

    /// Describes the source for logging.
    fn described(&self, length: usize) -> String {
        match self {
            Source::Device => format!("{length} bytes from this machine"),
            Source::Path(path) => {
                format!("{length} bytes of {}", path.display())
            }
        }
    }
}

/// How an authority entry is looked up in its database.
#[derive(Debug, Clone, Hash, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Entry {
    /// By a glob pattern on the certificate subject common name.
    Subject(String),
    /// By the certificate in this file.
    Certificate(PathBuf),
}

/// One measurement in a chain.
#[derive(Debug, Clone, Hash, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Measurement {
    /// The Secure Boot database entry that verified an image. The firmware
    /// measures each authority once per boot, so a chain lists it once.
    Authority { database: String, entry: Entry },

    /// Secure Boot separator measurement.
    Separator,

    /// The base value slab extends, read from its NV index.
    SlabBase,

    /// The authority that verified an image in slab. Slab measures each
    /// authority once per boot, so a chain lists it once.
    SlabAuthority { identity: Uuid },

    /// EFI variable measurement.
    Variable {
        /// Name of the EFI variable.
        name: String,
        /// Source of the variable contents.
        #[serde(default)]
        value: Source,
    },
}

impl fmt::Display for Measurement {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Measurement::Variable { name, .. } => {
                write!(formatter, "variable {name}")
            }
            Measurement::Separator => formatter.write_str("separator"),
            Measurement::Authority { .. } => formatter.write_str("authority"),
            Measurement::SlabBase => formatter.write_str("slab base"),
            Measurement::SlabAuthority { .. } => {
                formatter.write_str("slab authority")
            }
        }
    }
}

impl Measurement {
    /// Returns the bytes hashed for this measurement and a description of
    /// their source. Variable contents are collected for future lookups.
    fn measured<'chain>(
        &'chain self,
        device: &dyn Device,
        variables: &mut BTreeMap<&'chain str, Vec<u8>>,
    ) -> Result<(Vec<u8>, String), PuavoError> {
        match self {
            Measurement::Variable { name, value } => {
                let vendor = Variable::from_name(name)?.vendor();
                let contents = value.contents(vendor, name, device)?;
                let source = value.described(contents.len());

                let record = VariableRecord::new(vendor, name, &contents);
                debug!("  {}", record);
                let bytes = record.bytes();

                variables.insert(name.as_str(), contents);
                Ok((bytes, source))
            }
            Measurement::Separator => {
                Ok((SEPARATOR.to_vec(), "separator event data".to_string()))
            }
            Measurement::Authority { database, entry } => {
                let contents = variables.get(database.as_str()).ok_or_else(|| {
                    PuavoError::MalformedChain(format!(
                        "authority measured before the measurement of required database '{database}'"
                    ))
                })?;
                let signature_database = SignatureDatabase::read(contents)?;

                let matched = match entry {
                    Entry::Subject(pattern) => {
                        signature_database.find_by_subject_pattern(pattern)?
                    }
                    Entry::Certificate(path) => {
                        let certificate =
                            database::read_certificate_file(path)?;
                        signature_database.find_by_certificate(&certificate)
                    }
                };
                let database_entry = matched.ok_or_else(|| {
                    PuavoError::NotFound(format!(
                        "'{database}' has no entry for {entry:?}"
                    ))
                })?;

                let common_name = database_entry.common_name().unwrap_or("-");
                let source = format!(
                    "certificate '{common_name}' from '{database}' ({} bytes)",
                    database_entry.certificate().len()
                );

                let vendor = Variable::from_name(database)?.vendor();
                let measured = database_entry.measured();
                Ok((
                    VariableRecord::new(vendor, database, &measured).bytes(),
                    source,
                ))
            }
            Measurement::SlabBase => {
                let base = device.read_nv_index(SLAB_BASE_INDEX)?;
                Ok((
                    base.to_be_bytes().to_vec(),
                    format!("NV index with value of {base}"),
                ))
            }
            Measurement::SlabAuthority { identity } => Ok((
                VariableRecord::new(
                    SLAB_AUTHORITY_OWNER,
                    SLAB_AUTHORITY_RECORD,
                    &identity.to_bytes_le(),
                )
                .bytes(),
                format!("authority GUID of {identity}"),
            )),
        }
    }
}

/// Reads input data for measurements from a machine.
pub trait Device {
    /// Reads a UEFI variable as the firmware measured it.
    fn read_variable(
        &self,
        vendor: Uuid,
        name: &str,
    ) -> Result<Vec<u8>, PuavoError>;

    /// Reads a value from a TPM NV index.
    fn read_nv_index(&self, index: u32) -> Result<u64, PuavoError>;

    /// Reads the current value of a PCR.
    fn read_register(&self, index: u32) -> Result<String, PuavoError>;
}

/// Reads input data for measurements from the local machine.
pub struct SystemDevice;

impl Device for SystemDevice {
    fn read_variable(
        &self,
        vendor: Uuid,
        name: &str,
    ) -> Result<Vec<u8>, PuavoError> {
        efi::read_variable(vendor, name)
    }

    fn read_nv_index(&self, index: u32) -> Result<u64, PuavoError> {
        read_nv_u64(index)
    }

    fn read_register(&self, index: u32) -> Result<String, PuavoError> {
        read_pcrs(&[index])?
            .into_iter()
            .find(|(read_index, _)| *read_index == index)
            .map(|(_, value)| value)
            .ok_or_else(|| PuavoError::NotFound(format!("register {index}")))
    }
}

/// Field sizes of UEFI_VARIABLE_DATA.
const VENDOR_BYTES: usize = size_of::<Uuid>();
const LENGTH_BYTES: usize = size_of::<u64>();
const CHARACTER_BYTES: usize = size_of::<u16>();

/// The format of every variable measurement in PCR 7, UEFI_VARIABLE_DATA of
/// TCG PC Client Platform Firmware Profile 1.06 section 10.2.6:
///
/// typedef struct UEFI_VARIABLE_DATA {
///     UEFI_GUID VariableName;
///     UINT64 UnicodeNameLength;
///     UINT64 VariableDataLength;
///     CHAR16 UnicodeName[];
///     INT8 VariableData[];
/// } UEFI_VARIABLE_DATA;
struct VariableRecord<'record> {
    vendor: Uuid,
    name: &'record str,
    contents: &'record [u8],
}

impl<'record> VariableRecord<'record> {
    fn new(vendor: Uuid, name: &'record str, contents: &'record [u8]) -> Self {
        Self { vendor, name, contents }
    }

    /// Serializes the record into the measured bytes.
    fn bytes(&self) -> Vec<u8> {
        let name: Vec<u16> = self.name.encode_utf16().collect();

        let mut record = self.vendor.to_bytes_le().to_vec();
        record.extend_from_slice(&(name.len() as u64).to_le_bytes());
        record.extend_from_slice(&(self.contents.len() as u64).to_le_bytes());
        for character in name {
            record.extend_from_slice(&character.to_le_bytes());
        }
        record.extend_from_slice(self.contents);

        record
    }
}

impl fmt::Display for VariableRecord<'_> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            formatter,
            "{} of {} with {} bytes",
            self.name,
            self.vendor,
            self.contents.len()
        )
    }
}

/// Splits the measured bytes of a variable into its name and contents.
/// Returns None when the bytes are not a UEFI_VARIABLE_DATA record.
pub fn variable_name_and_contents(record: &[u8]) -> Option<(String, Vec<u8>)> {
    let (_vendor, rest) = record.split_first_chunk::<VENDOR_BYTES>()?;
    let (name_length, rest) = rest.split_first_chunk::<LENGTH_BYTES>()?;
    let (contents_length, rest) = rest.split_first_chunk::<LENGTH_BYTES>()?;
    let name_length = usize::try_from(u64::from_le_bytes(*name_length)).ok()?;
    let contents_length =
        usize::try_from(u64::from_le_bytes(*contents_length)).ok()?;

    let (name, contents) =
        rest.split_at_checked(name_length.checked_mul(CHARACTER_BYTES)?)?;
    let name: Vec<u16> = name
        .chunks_exact(CHARACTER_BYTES)
        .map(|character| u16::from_le_bytes([character[0], character[1]]))
        .collect();
    let contents = contents.get(..contents_length)?;

    Some((String::from_utf16(&name).ok()?, contents.to_vec()))
}

/// The result of evaluating one measurement.
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct Step {
    pub measurement: String,
    pub source: String,
    pub digest: String,
}

impl Step {
    fn new(measurement: &Measurement, source: String, digest: &[u8]) -> Self {
        Self {
            measurement: measurement.to_string(),
            source,
            digest: hex::encode(digest),
        }
    }
}

/// The value a chain evaluates to, with the result of each measurement.
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct Prediction {
    pub value: String,
    pub steps: Vec<Step>,
}

/// A chain of measurements that predicts a PCR value.
pub struct Chain<'chain> {
    measurements: &'chain [Measurement],
}

impl<'chain> Chain<'chain> {
    pub fn new(measurements: &'chain [Measurement]) -> Self {
        Self { measurements }
    }

    /// Evaluates each measurement and extends the results into a PCR value
    /// as the firmware does. An empty chain predicts the initial value.
    pub fn predict(
        &self,
        device: &dyn Device,
    ) -> Result<Prediction, PuavoError> {
        let mut value = vec![0u8; <Sha256 as Digest>::output_size()];
        let mut variables: BTreeMap<&str, Vec<u8>> = BTreeMap::new();
        let mut steps = Vec::with_capacity(self.measurements.len());

        debug!("Evaluating {} measurements", self.measurements.len());

        for measurement in self.measurements {
            let (bytes, source) =
                measurement.measured(device, &mut variables)?;
            let digest = Sha256::digest(&bytes);

            steps.push(Step::new(measurement, source, &digest));

            let mut extended = Sha256::new();
            extended.update(&value);
            extended.update(digest);
            value = extended.finalize().to_vec();
        }

        let value = hex::encode(value);
        debug!("The chain predicts {}", value);

        Ok(Prediction { value, steps })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn variable_record_reads_back() {
        let record =
            VariableRecord::new(Uuid::nil(), "db", b"contents").bytes();

        assert_eq!(
            variable_name_and_contents(&record),
            Some(("db".to_string(), b"contents".to_vec()))
        );
    }

    #[test]
    fn short_record_reads_as_nothing() {
        assert_eq!(variable_name_and_contents(&[0; 8]), None);
    }
}

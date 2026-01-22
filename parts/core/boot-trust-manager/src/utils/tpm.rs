use log::debug;
use tss_esapi::{
    Context,
    interface_types::algorithm::HashingAlgorithm,
    structures::{PcrSelectionListBuilder, PcrSlot},
    tcti_ldr::TctiNameConf,
};

use crate::error::PuavoError;

/// Read PCR values from the TPM.
///
/// Parameters:
/// - `pcr_indices`: List of PCR indices to read (e.g., [7, 11]).
///
/// Returns:
/// A Vec of (index, hex-encoded value) pairs, sorted by index.
pub fn read_pcrs(
    pcr_indices_: &[u32],
) -> Result<Vec<(u32, String)>, PuavoError> {
    let mut pcr_indices = pcr_indices_.to_vec();
    pcr_indices.sort();

    if pcr_indices.is_empty() {
        return Ok(Vec::new());
    }

    debug!("Reading TPM PCRs: {:?}", pcr_indices);

    let tcti = TctiNameConf::from_environment_variable()
        .unwrap_or(TctiNameConf::Device(Default::default()));

    let mut context = Context::new(tcti).map_err(|error| {
        PuavoError::TpmError(format!("Failed to create TPM context: {}", error))
    })?;

    let pcr_slots: Vec<PcrSlot> = pcr_indices
        .iter()
        .map(|&index| {
            PcrSlot::try_from(1u32 << index).map_err(|_| {
                PuavoError::TpmError(format!("Invalid PCR index {}", index))
            })
        })
        .collect::<Result<Vec<_>, _>>()?;

    let pcr_selection = PcrSelectionListBuilder::new()
        .with_selection(HashingAlgorithm::Sha256, &pcr_slots)
        .build()
        .map_err(|error| {
            PuavoError::TpmError(format!(
                "Failed to build PCR selection: {}",
                error
            ))
        })?;

    let (_, _, pcr_data) =
        context.pcr_read(pcr_selection).map_err(|error| {
            PuavoError::TpmError(format!("Failed to read PCRs: {}", error))
        })?;

    let pcrs: Vec<(u32, String)> = pcr_indices
        .iter()
        .zip(pcr_data.value().iter())
        .map(|(&pcr_index, pcr_value)| {
            (pcr_index, hex::encode(pcr_value.value()))
        })
        .collect();

    Ok(pcrs)
}

/// Read PCR values and return them as a simple line-separated string.
///
/// Format is "<index>=<hex>\n" for each PCR.
/// Example:
/// ```text
/// 7=1234567890abcdef...
/// 11=fedcba9876543210...
/// ```
///
/// Parameters:
/// - `pcr_indices`: List of PCR indices to read (e.g., [7, 11]).
///
/// Returns:
/// A string containing line-separated PCR index and value pairs.
pub fn read_pcrs_as_string(pcr_indices: &[u32]) -> Result<String, PuavoError> {
    let pcrs = read_pcrs(pcr_indices)?;

    let lines: Vec<String> = pcrs
        .iter()
        .map(|(index, value)| format!("{}={}", index, value))
        .collect();

    Ok(lines.join("\n"))
}

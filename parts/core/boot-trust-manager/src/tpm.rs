use std::{path::Path, process::Command};

use log::{debug, info};
use tss_esapi::{
    Context,
    abstraction::nv,
    constants::{CapabilityType, PropertyTag},
    handles::NvIndexTpmHandle,
    interface_types::algorithm::HashingAlgorithm,
    interface_types::resource_handles::NvAuth,
    structures::{
        CapabilityData::TpmProperties, PcrSelectionListBuilder, PcrSlot,
    },
    tcti_ldr::TctiNameConf,
};

use crate::error::PuavoError;

/// Number of PCRs in a PC Client TPM.
pub const PCR_COUNT: u32 = 24;

const IN_LOCKOUT_FLAG: u32 = 1 << 9;

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
            let invalid_pcr_index_error =
                || PuavoError::TpmError(format!("Invalid PCR index {}", index));

            // Use checked shift to prevent overflow panic
            let slot_mask =
                1u32.checked_shl(index).ok_or_else(invalid_pcr_index_error)?;

            PcrSlot::try_from(slot_mask).map_err(|_| invalid_pcr_index_error())
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

/// Reads the contents of an NV index.
fn read_nv<const SIZE: usize>(index: u32) -> Result<[u8; SIZE], PuavoError> {
    debug!("Reading TPM NV index {:#010x}", index);

    let tcti = TctiNameConf::from_environment_variable()
        .unwrap_or(TctiNameConf::Device(Default::default()));

    let mut context = Context::new(tcti).map_err(|error| {
        PuavoError::TpmError(format!("Failed to create TPM context: {}", error))
    })?;

    let handle = NvIndexTpmHandle::new(index).map_err(|error| {
        PuavoError::TpmError(format!(
            "Failed to address index {:#010x}: {}",
            index, error
        ))
    })?;

    let contents = context
        .execute_with_nullauth_session(|context| {
            let index = context.tr_from_tpm_public(handle.into())?;
            nv::read_full(context, NvAuth::NvIndex(index.into()), handle)
        })
        .map_err(|error| {
            PuavoError::TpmError(format!(
                "Failed to read index {:#010x}: {}",
                index, error
            ))
        })?;

    let bytes: [u8; SIZE] = contents.as_slice().try_into().map_err(|_| {
        PuavoError::TpmError(format!(
            "Index {:#010x} holds {} bytes, where {} were expected",
            index,
            contents.len(),
            SIZE
        ))
    })?;

    Ok(bytes)
}

/// Reads an NV index that holds a big endian u64.
pub fn read_nv_u64(index: u32) -> Result<u64, PuavoError> {
    Ok(u64::from_be_bytes(read_nv::<8>(index)?))
}

/// Clear the TPM dictionary attack lockout using the lockout authorization file.
///
/// Parameters:
/// - `lockout_auth_path`: Path to the lockout authorization file.
///
/// Returns:
/// - `Ok(())` if the lockout was cleared successfully or if the auth file does not exist.
/// - `Err(PuavoError)` if the command fails.
pub fn clear_dictionary_lockout<P: AsRef<Path>>(
    lockout_auth_path: P,
) -> Result<(), PuavoError> {
    let path = lockout_auth_path.as_ref();

    if !path.exists() {
        info!(
            "TPM lockout auth file not found at {:?}, skipping lockout clear",
            path
        );
        return Ok(());
    }

    debug!(
        "Clearing TPM dictionary attack lockout using auth file: {:?}",
        path
    );

    let auth_argument = format!("file:{}", path.display());
    let output = Command::new("tpm2_dictionarylockout")
        .arg("--clear-lockout")
        .arg("--auth")
        .arg(&auth_argument)
        .output()
        .map_err(|error| {
            PuavoError::TpmError(format!(
                "Failed to execute tpm2_dictionarylockout: {}",
                error
            ))
        })?;

    if output.status.success() {
        Ok(())
    } else {
        Err(PuavoError::TpmError(format!(
            "Failed to clear TPM dictionary lockout (exit code {:?}): {}",
            output.status.code(),
            String::from_utf8_lossy(&output.stderr)
        )))
    }
}

/// Check if the TPM is currently in dictionary attack lockout mode.
///
/// Returns:
/// - `Ok(true)` if the TPM is in lockout mode.
/// - `Ok(false)` if the TPM is not in lockout mode.
/// - `Err(PuavoError)` if checking the status fails.
pub fn is_in_lockout() -> Result<bool, PuavoError> {
    let tcti = TctiNameConf::from_environment_variable()
        .unwrap_or(TctiNameConf::Device(Default::default()));

    let mut context = Context::new(tcti).map_err(|error| {
        PuavoError::TpmError(format!("Failed to create TPM context: {}", error))
    })?;

    let (capability_data, _more_data) = context
        .get_capability(
            CapabilityType::TpmProperties,
            PropertyTag::Permanent.into(),
            1,
        )
        .map_err(|error| {
            PuavoError::TpmError(format!(
                "Failed to get TPM permanent flags: {}",
                error
            ))
        })?;

    if let TpmProperties(props) = capability_data {
        return Ok(props
            .iter()
            .find(|property| property.property() == PropertyTag::Permanent)
            .map(|property| (property.value() & IN_LOCKOUT_FLAG) != 0)
            .unwrap_or(false));
    }

    // If we fail to find the permanent flags, assume not locked out
    Ok(false)
}

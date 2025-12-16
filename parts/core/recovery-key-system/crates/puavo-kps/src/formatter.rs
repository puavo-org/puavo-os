use anyhow::Result;
use puavo_ipc::{
    DaemonResponseData, OrganizationKeyListing, OrganizationPublicKey,
    OutputFormat, RecoveryBundle, RecoveryKeyData,
};
use serde_json;

/// Format daemon response data according to specified output format
///
/// Parameters:
/// * `data` - Response data to format
/// * `format` - Desired output format
///
/// Returns:
/// Formatted string ready for output
///
/// Errors:
/// Returns error if JSON serialization fails
pub fn format(
    response_data: &DaemonResponseData,
    format: OutputFormat,
) -> Result<String> {
    match format {
        OutputFormat::Text => format_as_text(response_data),
        OutputFormat::Json => format_as_json(response_data),
    }
}

/// Format response data as human-readable text
fn format_as_text(response_data: &DaemonResponseData) -> Result<String> {
    let output = match response_data {
        DaemonResponseData::Status { uptime_seconds, version } => {
            format!("Version: {}\nUptime: {}s", version, uptime_seconds)
        }
        DaemonResponseData::OrganizationKeyListings(listings) => {
            format_organization_key_listings_text(listings)
        }
        DaemonResponseData::OrganizationPublicKey(key) => {
            format_organization_public_key_text(key)
        }
        DaemonResponseData::RecoveryBundles(bundles) => {
            format_recovery_bundles_text(bundles)
        }
        DaemonResponseData::RecoveryKeyDatas(data) => {
            format_recovery_key_datas_text(data)
        }
    };
    Ok(output)
}

/// Format organization key listings as text
fn format_organization_key_listings_text(
    listings: &[OrganizationKeyListing],
) -> String {
    if listings.is_empty() {
        return "No organization keys found.".to_string();
    }

    let mut output = String::new();

    for listing in listings {
        output
            .push_str(&format!("Organization: {}\n", listing.organization_id));
        if listing.versions.is_empty() {
            output.push_str("  No keys found.\n");
        } else {
            for version in &listing.versions {
                output.push_str(&format!(
                    "  Key Version {}: {}\n",
                    version.version, version.fingerprint
                ));
            }
        }
        output.push('\n');
    }

    output.trim_end().to_string()
}

/// Format organization public key as text
fn format_organization_public_key_text(key: &OrganizationPublicKey) -> String {
    key.public_key_pem.trim_end().to_string()
}

/// Format recovery bundles as text
fn format_recovery_bundles_text(bundles: &[RecoveryBundle]) -> String {
    if bundles.is_empty() {
        return "No recovery bundles generated.".to_string();
    }

    let mut output = String::new();
    for bundle in bundles {
        output.push_str(&format!(
            concat!(
                "Device: {}\n",
                "  Organization: {}\n",
                "  Key Version: {}\n",
                "  Encrypted Key Data: {}\n\n"
            ),
            bundle.serial_number,
            bundle.organization_id,
            bundle.organization_key_version,
            bundle.encrypted_key_data
        ));
    }
    output.trim_end().to_string()
}

/// Format recovery key data as text
fn format_recovery_key_datas_text(key_datas: &[RecoveryKeyData]) -> String {
    if key_datas.is_empty() {
        return "No recovery keys unwrapped.".to_string();
    }

    let mut output = String::new();
    for key_data in key_datas {
        output.push_str(&format!(
            concat!(
                "Device: {}\n",
                "  Organization: {}\n",
                "  Recovery Key: {}\n\n"
            ),
            key_data.serial_number,
            key_data.organization_id,
            String::from_utf8_lossy(&key_data.recovery_key[..])
        ));
    }
    output.trim_end().to_string()
}

/// Format response data as JSON
fn format_as_json(response_data: &DaemonResponseData) -> Result<String> {
    let json = serde_json::to_string_pretty(response_data)?;
    Ok(json)
}

//! Where a person gets help with a recovery, as the build of the recovery
//! environment names it.

/// The addresses of the support sites, separated by spaces.
const SUPPORT_ADDRESSES: Option<&str> =
    option_env!("RECOVERY_SUPPORT_ADDRESSES");

/// The addresses of the support sites, or none when the build names none.
pub fn support_addresses() -> Vec<String> {
    SUPPORT_ADDRESSES
        .unwrap_or_default()
        .split_whitespace()
        .map(String::from)
        .collect()
}

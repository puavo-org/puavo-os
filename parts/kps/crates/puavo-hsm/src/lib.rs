pub mod key_management;
pub mod session;
pub mod tests;

use std::{path::Path, sync::OnceLock};

use cryptoki::context::{CInitializeArgs, Pkcs11};
pub use key_management::{HsmKeyManager, KeyLabel};
pub use session::{HsmSession, HsmSessionError};
pub use tests::TestHsmSession;

/// Default PKCS#11 software module path
pub const DEFAULT_SOFTWARE_MODULE: &str = "/usr/lib/softhsm/libsofthsm2.so";

/// Default token label for HSM operations
pub const DEFAULT_TOKEN_LABEL: &str = "puavo-kps";

/// Default PIN for HSM authentication
pub const DEFAULT_PIN: &str = "123456";

/// Global PKCS#11 context
static PKCS11: OnceLock<Pkcs11> = OnceLock::new();

/// Initialize the PKCS#11 context
///
/// Parameters:
/// * `module_path` - Path to PKCS#11 module library
///
/// Returns:
/// Initialized PKCS#11 context
///
/// Errors:
/// Panics if the library cannot be found or initialized
fn initialize_pkcs11(module_path: &Path) -> Pkcs11 {
    // Check if module exists
    if !module_path.exists() {
        panic!("PKCS#11 library not found at {}", module_path.display());
    }

    // Initialize PKCS#11 library once
    let pkcs11 = Pkcs11::new(module_path).unwrap();
    pkcs11.initialize(CInitializeArgs::OsThreads).unwrap();

    tracing::debug!(
        "PKCS#11 library initialized from {}",
        module_path.display()
    );

    pkcs11
}

/// Get the global PKCS#11 context
///
/// Parameters:
/// * `module_path` - Path to PKCS#11 module library
///
/// Returns:
/// Reference to the global PKCS#11 context
///
/// Errors:
/// Panics if the library cannot be found or initialized
pub fn pkcs11(module_path: &Path) -> &'static Pkcs11 {
    PKCS11.get_or_init(|| initialize_pkcs11(module_path))
}

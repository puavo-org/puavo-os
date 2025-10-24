pub mod key_management;
pub mod mechanisms;
pub mod session;

pub use key_management::{HsmKeyManager, KeyLabel};
pub use session::{HsmSession, HsmSessionError};

/// Default PKCS#11 software module path
pub const DEFAULT_SOFTWARE_MODULE: &str = "/usr/lib/softhsm/libsofthsm2.so";

/// Default slot number for HSM operations
pub const DEFAULT_SLOT: u64 = 0;

/// Default PIN for HSM authentication
pub const DEFAULT_PIN: &str = "123456";

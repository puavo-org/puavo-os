use libcryptsetup_rs::LibcryptErr;
use std::{io, num::ParseIntError};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum PuavoError {
    #[error("Boot vault is already open")]
    BootVaultOpen,

    #[error("Boot vault is not mounted at {0}")]
    BootVaultNotMounted(String),

    #[error("{0} not found")]
    NotFound(String),

    #[error("Stored recovery key is invalid and cannot control LUKS devices")]
    InvalidRecoveryKey,

    #[error("Recovery key does not exist")]
    NoRecoveryKey,

    #[error(transparent)]
    IoError(#[from] io::Error),

    #[error(transparent)]
    LibcryptError(#[from] LibcryptErr),

    #[error("Enrollment state error: {0}")]
    EnrollmentStateError(serde_json::Error),

    #[error("{0}")]
    ShellError(String),

    #[error("LUKS error: {0}")]
    LuksError(String),

    #[error("Boot vault is not installed")]
    NoBootVault,

    #[error("Failed to find the current boot EFI device")]
    NoEFIBootDisk(String),

    #[error("Failed to find the booted EFI partition")]
    NoEFIPartition,

    #[error("Failed to find the primary LUKS partition")]
    NoPrimaryLuksPartition,

    #[error("Failed to unlock device")]
    UnlockError,

    #[error("Plymouth exited with code {0}")]
    PlymouthError(i32),

    #[error(transparent)]
    ParseIntError(#[from] ParseIntError),

    #[error("Failed to parse property '{0}'")]
    PropertyParseError(String),

    #[error("TPM error: {0}")]
    TpmError(String),

    #[error(
        "Host type '{actual}' does not match the expected value of '{expected}'"
    )]
    HostTypeMismatch { expected: String, actual: String },

    #[error("Multiple host type values specified in the kernel command-line")]
    MultipleHostTypes,

    #[error("PIN configuration error: {0}")]
    PinConfigurationError(String),

    #[error("Recovery QR error: {0}")]
    RecoveryQrError(String),
}

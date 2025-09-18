use libcryptsetup_rs::LibcryptErr;
use std::{io, num::ParseIntError};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum PuavoError {
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

    #[error("Configuration error: {0}")]
    ConfigurationError(serde_json::Error),

    #[error("Enrollment state error: {0}")]
    EnrollmentStateError(serde_json::Error),

    #[error("{0}")]
    ShellError(String),

    #[error("Boot vault is not mounted")]
    VaultNotMounted,

    #[error("LUKS error: {0}")]
    LuksError(String),

    #[error("Invalid data: {0}")]
    InvalidData(String),

    #[error("Failed to find the booted EFI partition")]
    NoEFIPartition,

    #[error("Failed to find the primary LUKS partition")]
    NoPrimaryLuksPartition,

    #[error("Plymouth exited with code {0}")]
    PlymouthError(i32),
    #[error(transparent)]
    ParseIntError(#[from] ParseIntError),
}

use libcryptsetup_rs::LibcryptErr;
use std::io;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum PuavoError {
    #[error(transparent)]
    IoError(#[from] io::Error),
    #[error(transparent)]
    LibcryptError(#[from] LibcryptErr),
    #[error("{0}")]
    ShellError(String),
    #[error("Boot vault is not mounted")]
    VaultNotMounted,
    #[error("LUKS error: {0}")]
    LuksError(String),
    #[error("Invalid data: {0}")]
    InvalidData(String),
    #[error("Failed to find the primary LUKS partition")]
    NoPrimaryLuksPartition,
    #[error("Plymouth exited with code {0}")]
    PlymouthError(i32),
}

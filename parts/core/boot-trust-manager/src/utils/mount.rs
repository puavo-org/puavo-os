use std::os::unix::ffi::OsStrExt;
use std::{
    ffi::CString,
    io,
    path::{Path, PathBuf},
};

use log::{debug, warn};
use nix::libc::{self, MNT_DETACH};

/// Attempt to unmount the specified mountpoint.
///
/// This first tries a lazy unmount (`MNT_DETACH`) to reduce EBUSY errors,
/// and falls back to a regular unmount. Returns the last OS error if both
/// attempts fail.
pub fn unmount(mountpoint: &PathBuf) -> io::Result<()> {
    let path =
        CString::new(mountpoint.as_os_str().as_bytes()).map_err(|_| {
            io::Error::new(io::ErrorKind::InvalidInput, "Invalid mountpoint")
        })?;

    unsafe {
        // Attempt lazy unmount to avoid EBUSY issues
        if libc::umount2(path.as_ptr(), MNT_DETACH) == 0
            || libc::umount2(path.as_ptr(), 0) == 0
        {
            return Ok(());
        }
    }

    Err(io::Error::last_os_error())
}

/// Guard object that unmounts the given mountpoint when dropped.
pub struct MountGuard {
    mountpoint: PathBuf,
}

impl MountGuard {
    /// Create a new guard object that will unmount the specified mountpoint when dropped.
    pub fn new<P: AsRef<Path>>(mountpoint: P) -> Self {
        Self { mountpoint: mountpoint.as_ref().to_path_buf() }
    }

    /// Explicitly unmount the guarded mount point.
    pub fn unmount(&self) -> io::Result<()> {
        unmount(&self.mountpoint)
    }
}

impl Drop for MountGuard {
    fn drop(&mut self) {
        if let Err(error) = self.unmount() {
            warn!("Failed to unmount {}: {}", self.mountpoint.display(), error);
        } else {
            debug!("Unmounted {}", self.mountpoint.display());
        }
    }
}

use std::process::Command;

use log::{debug, warn};

use crate::utils::efi;

const LOADKEYS: &str = "/usr/bin/loadkeys";

/// Where the keymaps built for the boot environment are.
const KEYMAP_DIRECTORY: &str = "/usr/share/puavo/keymaps";

const KEYMAPS: &[&str] = &["us", "fi", "se", "de", "gb"];

/// Load the keyboard layout this device is configured to use.
/// Fallback is the first supported layout.
///
/// Returns:
/// The applied layout upon success.
pub fn load_configured_keymap() -> Option<&'static str> {
    // Anything that loads is better than a prompt nobody can type into.
    configured_keymap()
        .into_iter()
        .chain(KEYMAPS.iter().copied())
        .find(|keymap| load(keymap))
}

/// The keymap this device is set to use, if it is one we have.
fn configured_keymap() -> Option<&'static str> {
    let configured = efi::read_boot_keymap()?;

    KEYMAPS.iter().copied().find(|keymap| *keymap == configured).or_else(|| {
        warn!("Unsupported keymap {}", configured);
        None
    })
}

/// Load a keymap into the console.
///
/// Returns:
/// Whether the console now reads keys with it.
fn load(keymap: &str) -> bool {
    let path = format!("{}/{}.kmap.gz", KEYMAP_DIRECTORY, keymap);

    let status = Command::new(LOADKEYS).arg(&path).status();

    match status {
        Ok(status) if status.success() => {
            debug!("Keymap is {}", keymap);
            true
        }
        Ok(status) => {
            warn!("loadkeys {} failed ({})", path, status);
            false
        }
        Err(error) => {
            warn!("Failed to execute {}: {}", LOADKEYS, error);
            false
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::utils::efi::{self, testing::FakeEfiProvider};
    use serial_test::serial;

    fn with_configured_keymap(keymap: Option<&str>) {
        efi::set_provider(Box::new(FakeEfiProvider {
            boot_keymap: keymap.map(|keymap| keymap.to_string()),
            ..Default::default()
        }));
    }

    #[test]
    #[serial]
    fn a_keymap_we_have_is_used() {
        with_configured_keymap(Some("se"));
        assert_eq!(configured_keymap(), Some("se"));
        efi::reset_provider();
    }

    #[test]
    #[serial]
    fn anything_else_is_refused() {
        for configured in
            ["", "nosuchkeymap", "../../etc/passwd", "--option", "us; reboot"]
        {
            with_configured_keymap(Some(configured));
            assert_eq!(configured_keymap(), None);
        }

        with_configured_keymap(None);
        assert_eq!(configured_keymap(), None);
        efi::reset_provider();
    }
}

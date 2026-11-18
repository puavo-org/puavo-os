//! Wireless networks. Their names come from anyone in radio range, so they
//! are shown only after characters that could mislead are replaced, and a
//! network is joined by the address of the access point that was listed.

mod dbus;
mod network_manager;

use std::fmt;

use zeroize::Zeroizing;

pub use network_manager::{connect, is_connected, scan};

/// What a network asks of the person who joins it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Security {
    Open,
    /// A passphrase shared by everyone.
    Personal,
    /// A user name and password of one's own.
    Enterprise,
}

/// A wireless network seen in a scan.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct WirelessNetwork {
    /// The name, safe to show.
    pub name: String,
    /// The hardware address of the strongest access point of the network.
    pub access_point_address: String,
    pub signal: u8,
    pub security: Security,
}

/// A passphrase, kept out of debug output and wiped from memory when
/// dropped.
#[derive(Clone, PartialEq, Eq)]
pub struct Passphrase(Zeroizing<String>);

impl Passphrase {
    pub fn new(text: String) -> Self {
        Passphrase(Zeroizing::new(text))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Debug for Passphrase {
    fn fmt(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str("Passphrase(hidden)")
    }
}

/// Why a scan or a connection failed. The message of NetworkManager stays
/// off the screen, since it can carry a network name from anyone in radio
/// range.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum NetworkFailure {
    /// The network refused the connection, most often for a wrong
    /// passphrase.
    Refused,
    /// The network did not answer in time.
    NoAnswer,
    Failed,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_passphrase_stays_out_of_debug_output() {
        let text = format!("{:?}", Passphrase::new("secret".into()));
        assert!(!text.contains("secret"));
    }
}

//! The parts of the D-Bus interface of NetworkManager the recovery uses,
//! with the names and values of its documentation.

use std::collections::HashMap;

use zbus::{proxy, ObjectPath, OwnedObjectPath, OwnedVariant, Variant};

/// The settings of a connection, by setting and property name.
pub type Settings<'a> = HashMap<&'a str, HashMap<&'a str, Variant<'a>>>;

pub const DEVICE_TYPE_WIFI: u32 = 2;

pub const DEVICE_STATE_ACTIVATED: u32 = 100;
pub const DEVICE_STATE_FAILED: u32 = 120;

pub const REASON_IP_CONFIG_UNAVAILABLE: u32 = 5;
pub const REASON_NO_SECRETS: u32 = 7;
pub const REASON_SUPPLICANT_TIMEOUT: u32 = 11;

pub const STATE_CONNECTING: u32 = 40;
/// The first state in which the device reaches at least its own site.
pub const STATE_CONNECTED_SITE: u32 = 60;

pub const AP_FLAGS_PRIVACY: u32 = 0x1;
pub const KEY_MGMT_PSK: u32 = 0x100;
pub const KEY_MGMT_802_1X: u32 = 0x200;
pub const KEY_MGMT_SAE: u32 = 0x400;
pub const KEY_MGMT_OWE: u32 = 0x800;
pub const KEY_MGMT_OWE_TM: u32 = 0x1000;
pub const KEY_MGMT_EAP_SUITE_B_192: u32 = 0x2000;

#[proxy(
    interface = "org.freedesktop.NetworkManager",
    default_service = "org.freedesktop.NetworkManager",
    default_path = "/org/freedesktop/NetworkManager"
)]
pub trait Manager {
    fn get_devices(&self) -> zbus::Result<Vec<OwnedObjectPath>>;

    #[zbus(name = "AddAndActivateConnection2")]
    fn add_and_activate_connection(
        &self,
        connection: Settings<'_>,
        device: &ObjectPath<'_>,
        specific_object: &ObjectPath<'_>,
        options: HashMap<&str, Variant<'_>>,
    ) -> zbus::Result<(
        OwnedObjectPath,
        OwnedObjectPath,
        HashMap<String, OwnedVariant>,
    )>;

    #[zbus(property)]
    fn state(&self) -> zbus::Result<u32>;

    /// Whether NetworkManager is still activating the connections it
    /// starts with.
    #[zbus(property)]
    fn startup(&self) -> zbus::Result<bool>;
}

#[proxy(
    interface = "org.freedesktop.NetworkManager.Device",
    default_service = "org.freedesktop.NetworkManager"
)]
pub trait Device {
    #[zbus(property)]
    fn device_type(&self) -> zbus::Result<u32>;

    #[zbus(signal)]
    fn state_changed(
        &self,
        new_state: u32,
        old_state: u32,
        reason: u32,
    ) -> zbus::Result<()>;
}

#[proxy(
    interface = "org.freedesktop.NetworkManager.Device.Wireless",
    default_service = "org.freedesktop.NetworkManager"
)]
pub trait Wireless {
    fn request_scan(
        &self,
        options: HashMap<&str, Variant<'_>>,
    ) -> zbus::Result<()>;

    fn get_all_access_points(&self) -> zbus::Result<Vec<OwnedObjectPath>>;

    #[zbus(property)]
    fn last_scan(&self) -> zbus::Result<i64>;
}

#[proxy(
    interface = "org.freedesktop.NetworkManager.AccessPoint",
    default_service = "org.freedesktop.NetworkManager"
)]
pub trait AccessPoint {
    #[zbus(property)]
    fn ssid(&self) -> zbus::Result<Vec<u8>>;

    #[zbus(property)]
    fn hw_address(&self) -> zbus::Result<String>;

    #[zbus(property)]
    fn strength(&self) -> zbus::Result<u8>;

    #[zbus(property)]
    fn flags(&self) -> zbus::Result<u32>;

    #[zbus(property)]
    fn wpa_flags(&self) -> zbus::Result<u32>;

    #[zbus(property)]
    fn rsn_flags(&self) -> zbus::Result<u32>;
}

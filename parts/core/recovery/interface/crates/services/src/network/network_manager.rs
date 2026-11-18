//! Networking through the D-Bus interface of NetworkManager.

use std::collections::HashMap;
use std::thread;
use std::time::{Duration, Instant};

use futures_lite::StreamExt;
use log::{debug, warn};
use zbus::proxy::CacheProperties;
use zbus::{Connection, OwnedObjectPath, Variant};
use zruntime::SharedRuntime;

use super::dbus::{
    AccessPointProxy, DeviceProxy, ManagerProxy, Settings, WirelessProxy,
    AP_FLAGS_PRIVACY, DEVICE_STATE_ACTIVATED, DEVICE_STATE_FAILED,
    DEVICE_TYPE_WIFI, KEY_MGMT_802_1X, KEY_MGMT_EAP_SUITE_B_192, KEY_MGMT_OWE,
    KEY_MGMT_OWE_TM, KEY_MGMT_PSK, KEY_MGMT_SAE, REASON_IP_CONFIG_UNAVAILABLE,
    REASON_NO_SECRETS, REASON_SUPPLICANT_TIMEOUT, STATE_CONNECTED_SITE,
    STATE_CONNECTING,
};
use super::{NetworkFailure, Passphrase, Security, WirelessNetwork};

/// The name of the connections the recovery makes. They live only while
/// they are active, so a failed attempt never leaves one that a later
/// attempt would reuse without its passphrase.
const PROFILE: &str = "recovery-wireless";
const WIRELESS_TYPE: &str = "802-11-wireless";
const VOLATILE: &str = "volatile";
const CONNECT_TIMEOUT: Duration = Duration::from_secs(40);
const SCAN_TIMEOUT: Duration = Duration::from_secs(15);
/// How long the check waits for a connection NetworkManager is still
/// making, such as an address for a cable.
const SETTLE_TIMEOUT: Duration = Duration::from_secs(30);
const SETTLE_INTERVAL: Duration = Duration::from_millis(500);
const REPLACEMENT: char = '?';

/// An access point as NetworkManager lists it.
struct AccessPoint {
    path: OwnedObjectPath,
    name: Vec<u8>,
    address: String,
    signal: u8,
    privacy: bool,
    key_management: u32,
}

/// How far NetworkManager has come.
#[derive(Debug)]
struct ManagerState {
    state: u32,
    starting: bool,
}

/// Whether the device is connected already, such as by a cable. Waits a
/// while when NetworkManager is still starting or connecting, so a cable
/// whose address is still coming is not missed.
pub fn is_connected() -> bool {
    let deadline = Instant::now() + SETTLE_TIMEOUT;
    loop {
        let state = zbus::block_on(read_manager_state());
        debug!("NetworkManager is {state:?}");
        let state_settled = match state {
            Ok(state) if state.state >= STATE_CONNECTED_SITE => return true,
            Ok(state) => !state.starting && state.state != STATE_CONNECTING,
            // NetworkManager may not be on the bus yet.
            Err(_) => false,
        };
        if state_settled || Instant::now() >= deadline {
            return false;
        }
        thread::sleep(SETTLE_INTERVAL);
    }
}

async fn read_manager_state() -> zbus::Result<ManagerState> {
    let connection = Connection::system().await?;
    let manager = ManagerProxy::builder(&connection)
        .cache_properties(CacheProperties::No)
        .build()
        .await?;
    Ok(ManagerState {
        state: manager.state().await?,
        starting: manager.startup().await?,
    })
}

/// Scans for networks, strongest first, one entry for each name and
/// security.
pub fn scan() -> Result<Vec<WirelessNetwork>, NetworkFailure> {
    let access_points =
        zbus::block_on(scan_access_points()).map_err(network_failure)?;
    debug!("the scan found {} access points", access_points.len());
    Ok(list_networks(access_points))
}

/// Joins the network of an access point, with a passphrase when the
/// network has personal security.
pub fn connect(
    access_point_address: &str,
    passphrase: Option<&Passphrase>,
) -> Result<(), NetworkFailure> {
    let result = zbus::block_on(join_network(access_point_address, passphrase));
    debug!("joining the network ended with {result:?}");
    result
}

/// Scans and lists the access points the scan found.
async fn scan_access_points() -> zbus::Result<Vec<AccessPoint>> {
    let connection = Connection::system().await?;
    let device = wireless_device(&connection).await?;
    let wireless =
        WirelessProxy::builder(&connection).path(&device).build().await?;

    // NetworkManager refuses a scan right after another one, and then the
    // results of that one serve.
    let last_scan = wireless.last_scan().await?;
    let mut scans = wireless.receive_last_scan_changed().await;
    if wireless.request_scan(HashMap::new()).await.is_ok() {
        let finished = async {
            while let Some(scan) = scans.next().await {
                if scan.get().await.is_ok_and(|time| time != last_scan) {
                    return;
                }
            }
        };
        let _ = SharedRuntime::current()?.timeout(SCAN_TIMEOUT, finished).await;
    }

    read_access_points(&connection, &device).await
}

/// Joins the network of an access point and waits until the connection is
/// up or has failed.
async fn join_network(
    address: &str,
    passphrase: Option<&Passphrase>,
) -> Result<(), NetworkFailure> {
    let connection = Connection::system().await.map_err(network_failure)?;
    let device = wireless_device(&connection).await.map_err(network_failure)?;
    let access_point = read_access_points(&connection, &device)
        .await
        .map_err(network_failure)?
        .into_iter()
        .find(|access_point| access_point.address == address)
        .ok_or(NetworkFailure::Failed)?;

    // Listening starts before the activation, so no change is missed.
    let mut state_changes = DeviceProxy::builder(&connection)
        .path(&device)
        .build()
        .await
        .map_err(network_failure)?
        .receive_state_changed()
        .await
        .map_err(network_failure)?;
    ManagerProxy::new(&connection)
        .await
        .map_err(network_failure)?
        .add_and_activate_connection(
            settings(&access_point, passphrase),
            &device.as_ref(),
            &access_point.path.as_ref(),
            HashMap::from([("persist", Variant::from(VOLATILE))]),
        )
        .await
        .map_err(network_failure)?;

    let connection_outcome = async {
        while let Some(change) = state_changes.next().await {
            let Ok(change) = change.args() else {
                continue;
            };
            match *change.new_state() {
                DEVICE_STATE_ACTIVATED => return Ok(()),
                DEVICE_STATE_FAILED => {
                    return Err(connect_failure(*change.reason()));
                }
                _ => {}
            }
        }
        Err(NetworkFailure::Failed)
    };
    SharedRuntime::current()
        .map_err(network_failure)?
        .timeout(CONNECT_TIMEOUT, connection_outcome)
        .await
        .unwrap_or(Err(NetworkFailure::NoAnswer))
}

/// The first wireless device NetworkManager knows.
async fn wireless_device(
    connection: &Connection,
) -> zbus::Result<OwnedObjectPath> {
    let manager = ManagerProxy::new(connection).await?;
    for path in manager.get_devices().await? {
        let device =
            DeviceProxy::builder(connection).path(&path).build().await?;
        if device.device_type().await? == DEVICE_TYPE_WIFI {
            return Ok(path);
        }
    }
    Err(zbus::Error::Failure("no wireless device".into()))
}

/// The access points of a device. One that goes away while it is read is
/// left out.
async fn read_access_points(
    connection: &Connection,
    device: &OwnedObjectPath,
) -> zbus::Result<Vec<AccessPoint>> {
    let wireless =
        WirelessProxy::builder(connection).path(device).build().await?;
    let mut access_points = Vec::new();
    for path in wireless.get_all_access_points().await? {
        if let Ok(access_point) = read_access_point(connection, path).await {
            access_points.push(access_point);
        }
    }
    Ok(access_points)
}

async fn read_access_point(
    connection: &Connection,
    path: OwnedObjectPath,
) -> zbus::Result<AccessPoint> {
    let proxy = AccessPointProxy::builder(connection)
        .path(&path)
        .cache_properties(CacheProperties::Yes)
        .build()
        .await?;
    Ok(AccessPoint {
        name: proxy.ssid().await?,
        address: proxy.hw_address().await?,
        signal: proxy.strength().await?,
        privacy: proxy.flags().await? & AP_FLAGS_PRIVACY != 0,
        key_management: proxy.wpa_flags().await? | proxy.rsn_flags().await?,
        path,
    })
}

/// The settings of a connection to one access point, such as:
///
/// ```text
///   connection                  id recovery-wireless, type 802-11-wireless
///   802-11-wireless             ssid School, bssid AA:BB:CC:DD:EE:FF
///   802-11-wireless-security    key-mgmt wpa-psk, psk the passphrase
/// ```
fn settings<'a>(
    access_point: &'a AccessPoint,
    passphrase: Option<&'a Passphrase>,
) -> Settings<'a> {
    let mut settings = Settings::from([
        (
            "connection",
            HashMap::from([
                ("id", Variant::from(PROFILE)),
                ("type", Variant::from(WIRELESS_TYPE)),
            ]),
        ),
        (
            WIRELESS_TYPE,
            HashMap::from([
                ("ssid", Variant::from(access_point.name.clone())),
                ("bssid", Variant::from(parse_address(&access_point.address))),
            ]),
        ),
    ]);

    let Some(key_management) = key_management(access_point.key_management)
    else {
        return settings;
    };
    let mut security =
        HashMap::from([("key-mgmt", Variant::from(key_management))]);
    if let Some(passphrase) = passphrase {
        security.insert("psk", Variant::from(passphrase.as_str()));
    }
    settings.insert("802-11-wireless-security", security);
    settings
}

/// The key management setting for the flags of an access point, or none
/// for an open one.
fn key_management(flags: u32) -> Option<&'static str> {
    if flags & KEY_MGMT_PSK != 0 {
        return Some("wpa-psk");
    }
    if flags & KEY_MGMT_SAE != 0 {
        return Some("sae");
    }
    if flags & (KEY_MGMT_OWE | KEY_MGMT_OWE_TM) != 0 {
        return Some("owe");
    }
    None
}

/// The bytes of a hardware address such as `AA:BB:CC:DD:EE:FF`.
fn parse_address(address: &str) -> Vec<u8> {
    address
        .split(':')
        .filter_map(|byte| u8::from_str_radix(byte, 16).ok())
        .collect()
}

/// Any failure of D-Bus or the runtime. Its message goes to the log only.
fn network_failure<E: std::fmt::Debug>(error: E) -> NetworkFailure {
    warn!("the network call failed: {error:?}");
    NetworkFailure::Failed
}

fn connect_failure(reason: u32) -> NetworkFailure {
    match reason {
        REASON_NO_SECRETS => NetworkFailure::Refused,
        REASON_SUPPLICANT_TIMEOUT | REASON_IP_CONFIG_UNAVAILABLE => {
            NetworkFailure::NoAnswer
        }
        _ => NetworkFailure::Failed,
    }
}

/// The networks of the access points: strongest first, one entry for each
/// name and security. Hidden networks are left out, and so are those with
/// the long broken WEP security.
fn list_networks(access_points: Vec<AccessPoint>) -> Vec<WirelessNetwork> {
    let mut networks: Vec<WirelessNetwork> = Vec::new();
    for access_point in access_points {
        if access_point.name.is_empty() {
            continue;
        }
        let Some(security) =
            security(access_point.privacy, access_point.key_management)
        else {
            continue;
        };
        let network = WirelessNetwork {
            name: safe_name(&access_point.name),
            access_point_address: access_point.address,
            signal: access_point.signal,
            security,
        };
        // Access points of one name merge only when their security is the
        // same, so an open one never stands in for a secured one.
        let listed_network = networks.iter_mut().find(|listed_network| {
            listed_network.name == network.name
                && listed_network.security == network.security
        });
        match listed_network {
            Some(listed_network) if listed_network.signal < network.signal => {
                *listed_network = network
            }
            Some(_) => {}
            None => networks.push(network),
        }
    }
    networks.sort_by_key(|network| std::cmp::Reverse(network.signal));
    networks
}

/// The security of an access point, or none for WEP.
fn security(privacy: bool, key_management: u32) -> Option<Security> {
    if key_management & (KEY_MGMT_802_1X | KEY_MGMT_EAP_SUITE_B_192) != 0 {
        return Some(Security::Enterprise);
    }
    if key_management & (KEY_MGMT_PSK | KEY_MGMT_SAE) != 0 {
        return Some(Security::Personal);
    }
    if privacy && key_management == 0 {
        return None;
    }
    Some(Security::Open)
}

/// The name with only letters, digits, ASCII punctuation and spaces kept,
/// since other characters such as direction marks can change how the rest
/// of the screen reads.
fn safe_name(name: &[u8]) -> String {
    String::from_utf8_lossy(name)
        .chars()
        .map(
            |character| {
                if is_safe(character) {
                    character
                } else {
                    REPLACEMENT
                }
            },
        )
        .collect()
}

fn is_safe(character: char) -> bool {
    character.is_alphanumeric()
        || character.is_ascii_punctuation()
        || character == ' '
}

#[cfg(test)]
mod tests {
    use super::*;

    fn access_point(
        name: &str,
        address: &str,
        signal: u8,
        key_management: u32,
    ) -> AccessPoint {
        AccessPoint {
            path: OwnedObjectPath::try_from("/access/point").unwrap(),
            name: name.as_bytes().to_vec(),
            address: address.to_string(),
            signal,
            privacy: key_management != 0,
            key_management,
        }
    }

    #[test]
    fn an_open_access_point_does_not_merge_into_a_secured_one() {
        let networks = list_networks(vec![
            access_point("School", "AA:01", 40, KEY_MGMT_PSK),
            access_point("School", "AA:02", 90, 0),
        ]);
        assert_eq!(networks.len(), 2);
        assert_eq!(networks[0].security, Security::Open);
        assert_eq!(networks[1].security, Security::Personal);
    }

    #[test]
    fn access_points_of_one_name_and_security_keep_the_strongest() {
        let networks = list_networks(vec![
            access_point("School", "AA:01", 40, KEY_MGMT_PSK),
            access_point("School", "AA:02", 90, KEY_MGMT_PSK),
        ]);
        assert_eq!(networks.len(), 1);
        assert_eq!(networks[0].access_point_address, "AA:02");
    }

    #[test]
    fn hidden_and_wep_networks_are_left_out() {
        let mut wep = access_point("Old", "AA:02", 60, 0);
        wep.privacy = true;
        let networks = list_networks(vec![
            access_point("", "AA:01", 80, KEY_MGMT_PSK),
            wep,
            access_point("School", "AA:03", 50, KEY_MGMT_PSK),
        ]);
        assert_eq!(networks.len(), 1);
        assert_eq!(networks[0].name, "School");
    }

    #[test]
    fn enterprise_personal_and_enhanced_open_are_told_apart() {
        let enterprise = KEY_MGMT_802_1X;
        assert_eq!(security(true, enterprise), Some(Security::Enterprise));
        assert_eq!(security(true, KEY_MGMT_SAE), Some(Security::Personal));
        assert_eq!(security(true, KEY_MGMT_OWE), Some(Security::Open));
        assert_eq!(security(false, 0), Some(Security::Open));
    }

    #[test]
    fn a_mixed_wpa2_and_wpa3_network_joins_with_a_preshared_key() {
        assert_eq!(
            key_management(KEY_MGMT_PSK | KEY_MGMT_SAE),
            Some("wpa-psk")
        );
        assert_eq!(key_management(KEY_MGMT_SAE), Some("sae"));
        assert_eq!(key_management(0), None);
    }

    #[test]
    fn control_and_direction_characters_are_replaced_in_names() {
        // "a", a newline, a right to left override and "b".
        assert_eq!(safe_name("a\n\u{202e}b".as_bytes()), "a??b");
    }

    #[test]
    fn letters_digits_punctuation_and_spaces_stay_in_names() {
        assert_eq!(safe_name("Café 2.4G".as_bytes()), "Café 2.4G");
    }

    #[test]
    fn a_failed_connection_is_told_by_its_reason() {
        let refused = connect_failure(REASON_NO_SECRETS);
        assert_eq!(refused, NetworkFailure::Refused);
        let late = connect_failure(REASON_SUPPLICANT_TIMEOUT);
        assert_eq!(late, NetworkFailure::NoAnswer);
        assert_eq!(connect_failure(0), NetworkFailure::Failed);
    }

    #[test]
    fn a_hardware_address_is_read_as_bytes() {
        let bytes = parse_address("AA:BB:CC:DD:EE:0F");
        assert_eq!(bytes, [0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0x0f]);
    }
}

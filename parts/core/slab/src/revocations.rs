//! The revocation list compiled in.
//!
//! The list is carried rather than read from a signed file, so the firmware
//! Secure Boot check on this image vouches for it and no signature code is
//! needed. Bumping revocation means a new build with a higher `LIST_VERSION`
//! and shipping it.

/// Fixed width of a component name, matching the version section.
pub const NAME_LENGTH: usize = 128;

/// The PE section that carries a component identity.
pub const VERSION_SECTION_NAME: &[u8; 8] = b".version";

/// The fleet wide logical revocation version this build enforces.
pub const LIST_VERSION: u64 = 1;

/// One component floor: the component name and its minimum allowed version.
pub struct Component {
    pub name: &'static [u8],
    pub minimum_version: u64,
}

/// The per component minimum versions enforced on the next stage.
pub const COMPONENTS: &[Component] = &[
    Component { name: b"grub", minimum_version: 1 },
    Component { name: b"puavo", minimum_version: 1 },
    Component { name: b"puavo-command-line", minimum_version: 1 },
];

/// Splits a version section into the component name and its version.
/// Returns `None` when the section is too short to hold them.
pub fn parse_identity(section: &[u8]) -> Option<(&[u8; NAME_LENGTH], u64)> {
    let name = section.get(0..NAME_LENGTH)?.try_into().ok()?;
    let version = section.get(NAME_LENGTH..NAME_LENGTH + 8)?;
    let version = u64::from_be_bytes(version.try_into().ok()?);
    Some((name, version))
}

/// The minimum allowed version for the component named by a padded name, if
/// the list mentions it. A component the list does not name has no floor.
pub fn minimum_version(padded_name: &[u8; NAME_LENGTH]) -> Option<u64> {
    COMPONENTS
        .iter()
        .find(|component| name_matches(padded_name, component.name))
        .map(|component| component.minimum_version)
}

/// Returns whether a fixed width padded name equals a component name zero
/// padded to the same width.
fn name_matches(padded_name: &[u8; NAME_LENGTH], name: &[u8]) -> bool {
    if name.len() > NAME_LENGTH {
        return false;
    }
    padded_name[..name.len()] == *name
        && padded_name[name.len()..].iter().all(|&byte| byte == 0)
}

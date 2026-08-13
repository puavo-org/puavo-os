//! The revocation list compiled into slab.
//!
//! Slab carries the list rather than reading a signed file, so the firmware
//! Secure Boot check on slab vouches for it and slab needs no signature code.
//! Bumping revocation means building a new slab with a higher `LIST_VERSION`
//! and shipping it.

/// Fixed width of a component name, matching the next stage version section.
pub const NAME_LENGTH: usize = 128;

/// The fleet wide logical revocation version this slab enforces. It is
/// compared against the counter minus base floor.
pub const LIST_VERSION: u64 = 1;

/// One component floor: the component name and its minimum allowed version.
pub struct Component {
    pub name: &'static [u8],
    pub minimum_version: u64,
}

/// The per component minimum versions this slab enforces on the next stage.
pub const COMPONENTS: &[Component] = &[
    Component { name: b"grub", minimum_version: 1 },
];

/// The minimum allowed version for the component named by a padded name, if
/// the list mentions it. A component the list does not name has no floor.
pub fn minimum_version(padded_name: &[u8; NAME_LENGTH]) -> Option<u64> {
    COMPONENTS
        .iter()
        .find(|component| name_matches(padded_name, component.name))
        .map(|component| component.minimum_version)
}

/// Returns whether a fixed width padded name equals a component name zero padded to the same width.
fn name_matches(padded_name: &[u8; NAME_LENGTH], name: &[u8]) -> bool {
    if name.len() > NAME_LENGTH {
        return false;
    }
    padded_name[..name.len()] == *name
        && padded_name[name.len()..].iter().all(|&byte| byte == 0)
}

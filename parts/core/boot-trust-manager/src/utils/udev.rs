use std::{fs, io, path::Path};

use udev::{Device, Enumerator};

pub fn device_from_device_node_path<P: AsRef<Path>>(
    device_node_path: P,
) -> io::Result<Device> {
    let target = fs::canonicalize(device_node_path)?;

    let mut enumerator = Enumerator::new()?;
    enumerator.match_subsystem("block")?;

    let device = enumerator
        .scan_devices()?
        .into_iter()
        .find(|device| {
            device
                .devnode()
                .and_then(|node| fs::canonicalize(node).ok())
                .map_or(false, |node_canonical| node_canonical == target)
        })
        .ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::NotFound,
                format!(
                    "No udev device found for device node {}",
                    target.display()
                ),
            )
        })?;

    Ok(device)
}

pub fn filesystem_type(device: &Device) -> Option<&str> {
    device
        .property_value("ID_FS_TYPE")
        .map(|property| property.to_str())
        .flatten()
}

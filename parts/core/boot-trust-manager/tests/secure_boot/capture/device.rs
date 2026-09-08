//! A chain reads a variable either from a file or from the machine. The same
//! bytes must measure the same from either source, so the captured variables
//! are served as a machine here and compared with the chain reading them from
//! files.

use std::path::Path;

use puavo_boot_trust_manager::error::PuavoError;
use puavo_boot_trust_manager::secure_boot::chain::{
    Chain, Measurement, Source,
};

use super::slab;
use super::{
    Capture, CapturedDevice, REGISTER, write_variables_into_directory,
};

/// The chain of the captured boot with every variable read from the machine.
fn chain_that_reads_from_machine() -> Vec<Measurement> {
    slab::chain(Path::new("/nowhere"))
        .into_iter()
        .map(|measurement| match measurement {
            Measurement::Variable { name, .. } => {
                Measurement::Variable { name, value: Source::Device }
            }
            other => other,
        })
        .collect()
}

#[test]
fn variable_from_machine_measures_as_from_file() {
    let capture = Capture::read(slab::PROFILE);
    let (directory, _) = write_variables_into_directory(&capture);
    let device = CapturedDevice::of(&capture);

    let from_files =
        Chain::new(&slab::chain(directory.path())).predict(&device).unwrap();
    let from_machine =
        Chain::new(&chain_that_reads_from_machine()).predict(&device).unwrap();

    assert_eq!(from_machine.value, from_files.value);
    assert_eq!(from_machine.value, capture.register(REGISTER));
}

#[test]
fn variable_machine_lacks_refused() {
    let capture = Capture::read(slab::PROFILE);
    let mut device = CapturedDevice::of(&capture);
    device.variables.remove("db");

    let error = Chain::new(&chain_that_reads_from_machine())
        .predict(&device)
        .err()
        .unwrap();

    assert!(
        matches!(&error, PuavoError::NotFound(name) if name == "db"),
        "{error}"
    );
}

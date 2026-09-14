//! Generates the components from the floors file, and one entry per
//! authority from the authority directory.
//!
//! The floors file lists one component per line, its name and the oldest
//! accepted version:
//!
//!     grub 20260101
//!
//! generates:
//!
//!     pub const COMPONENTS: &[Component] =
//!         &[Component { name: b"grub", minimum_version: 20260101 }];
//!
//! An authority entry holds the authority identity and its public keys. Each
//! key is parsed at build time to detect invalid keys early.
//!
//! The directory the build is pointed at holds one subdirectory per authority.
//! Anything else kept in one, such as what signs with a key, is ignored:
//!
//!     authorities
//!     `-- example
//!         |-- authority.guid   who this authority is
//!         |-- first.der        a public key it signs with
//!         `-- second.der       the key replacing it
//!
//! Adding another DER file is how a key is replaced, and leaves the authority
//! unchanged. That directory generates:
//!
//!     static AUTHORITIES: &[Authority] = &[Authority {
//!         identity: [
//!             1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
//!         ],
//!         keys: &[
//!             include_bytes!("authorities/example/first.der"),
//!             include_bytes!("authorities/example/second.der"),
//!         ],
//!     }];

use std::env;
use std::fs;
use std::path::{Path, PathBuf};

use proc_macro2::{Literal, TokenStream};
use quote::quote;
use rsa::RsaPublicKey;
use rsa::pkcs1::DecodeRsaPublicKey;
use time::macros::format_description;
use time::{Date, OffsetDateTime};

/// Where the authorities come from, and what the files in one are called.
const DIRECTORY_VARIABLE: &str = "SLAB_VERIFIER_KEYS";
const IDENTITY_FILE: &str = "authority.guid";
const KEY_EXTENSION: &str = "der";

/// Where the floors come from, how a floor is written, and how old one may
/// get.
const FLOORS_FILE: &str = "floors";
const FLOOR_FORMAT: &[time::format_description::BorrowedFormatItem<'_>] =
    format_description!("[year][month][day]");
const FLOOR_MAXIMUM_AGE_YEARS: u64 = 2;
const YEAR_IN_FLOOR: u64 = 10000;

fn main() {
    println!("cargo:rerun-if-env-changed={DIRECTORY_VARIABLE}");

    generate_floors();

    if env::var_os("CARGO_FEATURE_VERIFIER").is_some() {
        generate_verifier_data();
    }
}

/// Generates the components from the floors file.
fn generate_floors() {
    let file = Path::new(FLOORS_FILE);
    watch(file);
    let written = fs::read_to_string(file)
        .unwrap_or_else(|error| panic!("failed to read {file:?}: {error}"));

    let today: u64 = OffsetDateTime::now_utc()
        .format(FLOOR_FORMAT)
        .unwrap()
        .parse()
        .unwrap();
    let components: Vec<TokenStream> = written
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty())
        .map(|line| generate_floor(line, today))
        .collect();
    if components.is_empty() {
        panic!("no floors listed in {file:?}");
    }

    let table = quote! {
        pub const COMPONENTS: &[Component] = &[#(#components),*];
    };

    let output = PathBuf::from(env::var("OUT_DIR").unwrap()).join("floors.rs");
    fs::write(&output, table.to_string())
        .unwrap_or_else(|error| panic!("failed to write {output:?}: {error}"));
}

/// Generates one floor entry from a line of the floors file, refusing a
/// version that is not a date or has gone stale.
fn generate_floor(line: &str, today: u64) -> TokenStream {
    let (name, version) = line
        .split_once(char::is_whitespace)
        .unwrap_or_else(|| panic!("malformed floor '{line}'"));
    let version = version.trim();
    Date::parse(version, FLOOR_FORMAT).unwrap_or_else(|error| {
        panic!("floor '{name}' version {version} is not a date: {error}")
    });

    let version: u64 = version.parse().unwrap();
    if version < today - FLOOR_MAXIMUM_AGE_YEARS * YEAR_IN_FLOOR {
        panic!(
            "floor '{name}' is over {FLOOR_MAXIMUM_AGE_YEARS} years old, raise it in {FLOORS_FILE}"
        );
    }

    let name = Literal::byte_string(name.as_bytes());
    quote! {
        Component { name: #name, minimum_version: #version }
    }
}

/// Generates data structures for the verifier feature.
fn generate_verifier_data() {
    let directory = env::var(DIRECTORY_VARIABLE).unwrap_or_else(|_| {
        panic!("{DIRECTORY_VARIABLE} must name the directory of authorities")
    });
    watch(Path::new(&directory));

    let authorities: Vec<TokenStream> = directories_in(Path::new(&directory))
        .iter()
        .map(|authority| generate_authority(authority))
        .collect();
    if authorities.is_empty() {
        panic!("{directory} contains no authority directories");
    }

    let table = quote! {
        static AUTHORITIES: &[Authority] = &[#(#authorities),*];
    };

    let file =
        PathBuf::from(env::var("OUT_DIR").unwrap()).join("authorities.rs");
    fs::write(&file, table.to_string())
        .unwrap_or_else(|error| panic!("cannot write {file:?}: {error}"));
}

/// Generates a data structure for the specified authority directory.
/// Returns the tokens of the data structure as a stream.
fn generate_authority(authority: &Path) -> TokenStream {
    watch(authority);

    let identity_file = authority.join(IDENTITY_FILE);
    watch(&identity_file);
    let identity =
        identity_of(&identity_file).map(Literal::u8_unsuffixed).into_iter();

    let keys: Vec<String> = keys_in(authority)
        .iter()
        .map(|key| {
            watch(key);
            test_key(key);
            key.display().to_string()
        })
        .collect();
    if keys.is_empty() {
        panic!("{authority:?} holds no {KEY_EXTENSION} key");
    }

    quote! {
        Authority {
            identity: [#(#identity),*],
            keys: &[#(include_bytes!(#keys)),*],
        }
    }
}

/// Returns the GUID from the specified file as bytes.
fn identity_of(file: &Path) -> [u8; 16] {
    let written = fs::read_to_string(file)
        .unwrap_or_else(|error| panic!("cannot read {file:?}: {error}"));
    let identity =
        written.trim().parse::<uuid::Uuid>().unwrap_or_else(|error| {
            panic!("{file:?} does not name anyone: {error}")
        });
    identity.to_bytes_le()
}

/// Tests the specified key by trying to parse it.
fn test_key(file: &Path) {
    let written = fs::read(file)
        .unwrap_or_else(|error| panic!("cannot read {file:?}: {error}"));
    RsaPublicKey::from_pkcs1_der(&written).unwrap_or_else(|error| {
        panic!("{file:?} is not a public key: {error}")
    });
}

/// Returns subdirectory paths in sorted order.
fn directories_in(directory: &Path) -> Vec<PathBuf> {
    let mut found: Vec<PathBuf> =
        entries_of(directory).filter(|path| path.is_dir()).collect();
    found.sort();
    found
}

/// Returns the paths to the keys of one authority in sorted order.
fn keys_in(authority: &Path) -> Vec<PathBuf> {
    let mut found: Vec<PathBuf> = entries_of(authority)
        .filter(|path| {
            path.extension().is_some_and(|name| name == KEY_EXTENSION)
        })
        .collect();
    found.sort();
    found
}

/// Returns sorted paths to the entries in the specified directory.
fn entries_of(directory: &Path) -> impl Iterator<Item = PathBuf> {
    let entries = fs::read_dir(directory)
        .unwrap_or_else(|error| panic!("cannot read {directory:?}: {error}"));
    entries.filter_map(|entry| Some(entry.ok()?.path()))
}

/// Asks for another build when this changes.
fn watch(path: &Path) {
    println!("cargo:rerun-if-changed={}", path.display());
}

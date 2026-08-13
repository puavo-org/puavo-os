//! Generates one entry per authority from the authority directory. An entry
//! holds who the authority is and the keys it signs with, and every key is read
//! here too, since a key slab cannot read would otherwise only be found out on
//! a machine that refuses to boot.
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

/// Where the authorities come from, and what the files in one are called.
const DIRECTORY_VARIABLE: &str = "SLAB_VERIFIER_KEYS";
const IDENTITY_FILE: &str = "authority.guid";
const KEY_EXTENSION: &str = "der";

fn main() {
    println!("cargo:rerun-if-env-changed={DIRECTORY_VARIABLE}");

    if env::var_os("CARGO_FEATURE_VERIFIER").is_some() {
        generate_verifier_data();
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

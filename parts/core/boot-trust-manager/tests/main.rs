mod common;
mod configurators;
mod devices;
mod utils;

use std::sync::Once;

static INITIALIZATION: Once = Once::new();
static CLEANUP: Once = Once::new();

/// Initialize test environment once before all tests.
pub fn setup() {
    INITIALIZATION.call_once(|| {
        common::luks::clean_all();
    });
}

/// Register cleanup to run after all tests.
pub fn teardown() {
    CLEANUP.call_once(|| {
        common::luks::clean_all();
    });
}

#[ctor::ctor]
fn init() {
    setup();
}

#[ctor::dtor]
fn cleanup() {
    common::luks::clean_all();
}

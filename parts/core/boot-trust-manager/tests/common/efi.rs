use std::sync::atomic::{AtomicBool, Ordering};

use puavo_boot_trust_manager::utils::efi::{self, EfiProvider};

/// Test EFI provider for mocking EFI variables in tests.
pub struct TestEfiProvider {
    secure_boot_enabled: bool,
    pin_change_requested: AtomicBool,
}

impl TestEfiProvider {
    pub fn new() -> Self {
        Self {
            secure_boot_enabled: false,
            pin_change_requested: AtomicBool::new(false),
        }
    }

    pub fn with_secure_boot(mut self, enabled: bool) -> Self {
        self.secure_boot_enabled = enabled;
        self
    }

    pub fn with_pin_change_requested(self, requested: bool) -> Self {
        self.pin_change_requested.store(requested, Ordering::SeqCst);
        self
    }
}

impl EfiProvider for TestEfiProvider {
    fn is_secure_boot_enabled(&self) -> bool {
        self.secure_boot_enabled
    }

    fn is_pin_change_requested(&self) -> bool {
        self.pin_change_requested.load(Ordering::SeqCst)
    }

    fn clear_pin_change_request(&self) {
        self.pin_change_requested.store(false, Ordering::SeqCst);
    }

    fn read_recovery_bundle(&self) -> Option<String> {
        None
    }

    fn read_boot_keymap(&self) -> Option<String> {
        None
    }
}

/// Set up the test EFI provider with default state (no secure boot, no PIN change requested).
pub fn reset() {
    efi::set_provider(Box::new(TestEfiProvider::new()));
}

/// Set up test EFI with secure boot enabled.
pub fn with_secure_boot() {
    efi::set_provider(Box::new(TestEfiProvider::new().with_secure_boot(true)));
}

/// Set up test EFI with PIN change requested.
pub fn with_pin_change_requested() {
    efi::set_provider(Box::new(
        TestEfiProvider::new().with_pin_change_requested(true),
    ));
}

/// Set up test EFI with both secure boot and PIN change requested.
pub fn with_secure_boot_and_pin_change_requested() {
    efi::set_provider(Box::new(
        TestEfiProvider::new()
            .with_secure_boot(true)
            .with_pin_change_requested(true),
    ));
}

use std::sync::atomic::{AtomicBool, Ordering};

use boot_trust_manager::system::efi::{self, EfiProvider};

/// Test EFI provider for mocking EFI variables in tests.
pub struct TestEfiProvider {
    pin_change_requested: AtomicBool,
    secure_boot_enabled: AtomicBool,
}

impl TestEfiProvider {
    pub fn new() -> Self {
        Self {
            pin_change_requested: AtomicBool::new(false),
            secure_boot_enabled: AtomicBool::new(false),
        }
    }

    pub fn with_pin_change_requested(self, requested: bool) -> Self {
        self.pin_change_requested.store(requested, Ordering::SeqCst);
        self
    }

    pub fn with_secure_boot_enabled(self, enabled: bool) -> Self {
        self.secure_boot_enabled.store(enabled, Ordering::SeqCst);
        self
    }
}

impl EfiProvider for TestEfiProvider {
    fn is_secure_boot_enabled(&self) -> bool {
        self.secure_boot_enabled.load(Ordering::SeqCst)
    }

    fn is_secure_boot_update_allowed(&self) -> bool {
        false
    }

    fn clear_secure_boot_update_request(&self) {}

    fn is_in_setup_mode(&self) -> bool {
        false
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

/// Set up test EFI with PIN change requested.
pub fn with_pin_change_requested() {
    efi::set_provider(Box::new(
        TestEfiProvider::new().with_pin_change_requested(true),
    ));
}

/// Set up test EFI with Secure Boot enabled.
pub fn with_secure_boot_enabled() {
    efi::set_provider(Box::new(
        TestEfiProvider::new().with_secure_boot_enabled(true),
    ));
}

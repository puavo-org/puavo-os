//! Secure Boot database updates, prepared before the enrollments and applied
//! after them.

pub mod prepare;

use std::{cell::RefCell, rc::Rc};

use crate::secure_boot::update::PreparedSecureBootUpdate;

pub use prepare::PrepareSecureBootUpdateConfigurator;

/// Directory of the databases installed in the image.
const DATABASE_DIRECTORY: &str = "/etc/puavo-secure-boot";

/// State shared between the configurator that prepares a Secure Boot update
/// and the one that applies it. The enrollments run between the two.
#[derive(Clone, Default)]
pub struct SecureBootUpdateContext(
    Rc<RefCell<Option<PreparedSecureBootUpdate>>>,
);

impl SecureBootUpdateContext {
    /// Stores the prepared update.
    fn set_prepared(&self, prepared: PreparedSecureBootUpdate) {
        *self.0.borrow_mut() = Some(prepared);
    }

    /// The update prepared during this boot, if any.
    fn prepared(&self) -> Option<PreparedSecureBootUpdate> {
        self.0.borrow().clone()
    }
}

#[cfg(test)]
pub mod testing;

use serde::{Deserialize, Serialize};

use crate::{error::PuavoError, utils::kernel_commandline};

#[derive(Serialize, Deserialize, Debug, Clone, Default, PartialEq, Eq)]
pub struct UnlockRestrictions {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub host_type: Option<String>,
}

impl UnlockRestrictions {
    /// Create restrictions from the current system state.
    pub fn from_current_state() -> Self {
        Self { host_type: kernel_commandline::get_host_type() }
    }

    /// Check that all restrictions are satisfied by the current system state.
    pub fn check(&self) -> Result<(), PuavoError> {
        let current = Self::from_current_state();

        if let Some(expected) = &self.host_type {
            let actual = current.host_type.as_deref().unwrap_or_default();
            if expected != actual {
                return Err(PuavoError::HostTypeMismatch {
                    expected: expected.clone(),
                    actual: actual.to_string(),
                });
            }
        }

        Ok(())
    }
}

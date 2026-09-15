//! Checks chains against the PCRs of a machine.

use std::collections::BTreeMap;

use log::{debug, info};
use serde::Serialize;

use crate::{
    error::PuavoError,
    secure_boot::chain::{Chain, Device, Measurement, Step},
    tpm::PCR_COUNT,
};

/// The prediction of a chain and the current PCR value. The current value is
/// None when reading the TPM failed.
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct Comparison {
    pub register: String,
    pub predicted: String,
    pub current: Option<String>,
    /// Whether the PCR has the predicted value. None when reading the PCR
    /// failed.
    pub matches: Option<bool>,
    pub steps: Vec<Step>,
}

impl Comparison {
    /// Logs whether the PCR matches, and each measurement when it does not.
    pub fn log_result(&self) {
        match self.matches {
            Some(true) => info!("{} has the predicted value", self.register),
            Some(false) => {
                info!(
                    "{} current value {}, predicted {}",
                    self.register,
                    self.current.as_deref().unwrap_or("-"),
                    self.predicted
                );
                for step in &self.steps {
                    info!(
                        "  {} from {} as {}",
                        step.measurement, step.source, step.digest
                    );
                }
            }
            None => info!("failed to read {}", self.register),
        }
    }
}

/// Checks chains against the PCRs of a machine.
pub struct Validator<'device> {
    device: &'device dyn Device,
}

impl<'device> Validator<'device> {
    pub fn new(device: &'device dyn Device) -> Self {
        Self { device }
    }

    /// Evaluates a chain and compares the prediction with the PCR.
    pub fn check(
        &self,
        register: &str,
        chain: &[Measurement],
    ) -> Result<Comparison, PuavoError> {
        let prediction = Chain::new(chain).predict(self.device)?;

        let index = register
            .split(':')
            .next()
            .and_then(|index| index.parse::<u32>().ok())
            .filter(|index| *index < PCR_COUNT)
            .ok_or_else(|| {
                PuavoError::MalformedChain(format!(
                    "'{register}' is not a PCR name"
                ))
            })?;

        let current = match self.device.read_register(index) {
            Ok(value) => Some(value),
            Err(error) => {
                debug!("Failed to read PCR {}: {}", index, error);
                None
            }
        };

        let matches = current.as_ref().map(|value| *value == prediction.value);

        Ok(Comparison {
            register: register.to_string(),
            predicted: prediction.value,
            current,
            matches,
            steps: prediction.steps,
        })
    }

    /// Evaluates every chain of a policy.
    pub fn check_policy(
        &self,
        policy: &BTreeMap<String, Option<Vec<Measurement>>>,
    ) -> Vec<Result<Comparison, PuavoError>> {
        policy
            .iter()
            .filter_map(|(register, chain)| {
                let chain = chain.as_ref()?;
                Some(self.check(register, chain))
            })
            .collect()
    }
}

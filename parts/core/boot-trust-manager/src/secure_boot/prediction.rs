//! Reports what a policy predicts for the PCRs it binds.

use std::{collections::BTreeMap, path::Path};

use serde::Serialize;

use crate::{
    configurators::enrollment::EnrollmentItemConfiguration,
    error::PuavoError,
    secure_boot::{
        chain::{Device, Measurement, SystemDevice},
        validator::{Comparison, Validator},
    },
};

/// The result for one PCR, or the error that prevented it.
#[derive(Debug, Serialize)]
#[serde(untagged)]
pub enum Register {
    Predicted(Comparison),
    Failed { error: String },
}

/// A policy's predictions, serialized as JSON.
#[derive(Debug, Serialize)]
pub struct Report {
    pub policy: String,
    pub registers: Vec<Register>,
}

impl Report {
    /// Evaluates every chain of a policy against the specified machine.
    pub fn new(
        policy: &str,
        chains: &BTreeMap<String, Option<Vec<Measurement>>>,
        device: &dyn Device,
    ) -> Self {
        let registers = Validator::new(device)
            .check_policy(chains)
            .into_iter()
            .map(|outcome| match outcome {
                Ok(outcome) => Register::Predicted(outcome),
                Err(error) => Register::Failed { error: error.to_string() },
            })
            .collect();

        Self { policy: policy.to_string(), registers }
    }

    /// Returns true when every chain was evaluated. A PCR value that differs
    /// from the prediction is not a failure.
    pub fn all_chains_predicted(&self) -> bool {
        !self
            .registers
            .iter()
            .any(|register| matches!(register, Register::Failed { .. }))
    }
}

/// Prints the predicted values of the PCRs bound by the policy in the
/// specified file, as JSON. Fails when a chain could not be evaluated.
pub fn predict(policy: &Path) -> Result<(), PuavoError> {
    let configuration = EnrollmentItemConfiguration::read(policy)?;
    let chains = configuration.policy.specific_pcrs.unwrap_or_default();
    let report = Report::new(&configuration.name, &chains, &SystemDevice);

    println!(
        "{}",
        serde_json::to_string_pretty(&report)
            .map_err(PuavoError::EnrollmentStateError)?
    );

    if !report.all_chains_predicted() {
        return Err(PuavoError::ChainNotEvaluated);
    }

    Ok(())
}

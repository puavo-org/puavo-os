//! Finds the configured measurements that a firmware adds to a register in
//! this boot, and places them into the chains of a policy.
//!
//! A quirk is a measurement that a firmware logs after one of the listed
//! named measurements. Its variants are other forms the same quirk may take.
//! When the event log shows the measurement, it and each variant get a chain:
//!
//!   quirk:      A with variant B, after first or second
//!
//!   declared:   first  second     third
//!   logged:     first  second  A  third
//!   chains:     first  second  A  third
//!               first  second  B  third

use std::{
    collections::{BTreeMap, BTreeSet},
    fs,
    path::Path,
};

use log::{debug, info, warn};
use serde::{Deserialize, Serialize};

use crate::{
    error::PuavoError,
    luks::tokens::LuksTpmEnrollmentPolicy,
    secure_boot::{
        chain::{Chain, Device, Measurement},
        event_log::{self, EVENT_LOG, Event},
    },
    tpm::pcr_index,
};

/// The quirks that a firmware may have.
pub const CONFIGURATION_FILE: &str = "/etc/puavo/quirks.json";

/// The most chains that one policy expands into. Each chain is enrolled as
/// a token of its own.
const MAX_CHAINS: usize = 4;

/// A measurement that a firmware may add directly after one of the named
/// declared measurements. The variants are other forms it may take.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Quirk {
    pub after: Vec<String>,
    pub measurement: Measurement,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub variants: Vec<Measurement>,
}

impl Quirk {
    /// Returns true when the quirk may appear after the named measurement.
    fn may_appear_after(&self, name: &str) -> bool {
        self.after.iter().any(|after| after == name)
    }

    /// Returns the measurement followed by its variants.
    fn measurement_and_variants(&self) -> Vec<Measurement> {
        let mut measurements = vec![self.measurement.clone()];
        measurements.extend(self.variants.iter().cloned());
        measurements
    }
}

/// The quirks that a firmware may have, for each register.
pub type Configuration = BTreeMap<String, Vec<Quirk>>;

/// The quirks found in a boot for each register, each with the one
/// measurement it was found after.
#[derive(Debug, Default, PartialEq, Serialize)]
pub struct Quirks(BTreeMap<String, Vec<Quirk>>);

impl Quirks {
    /// Finds the quirks active in this boot for the chains of the policies.
    /// On failure the reason is logged and no quirks are returned.
    pub fn find_active(
        policies: &[&LuksTpmEnrollmentPolicy],
        device: &impl Device,
    ) -> Self {
        let quirks = match Self::find_in_event_log(policies, device) {
            Ok(quirks) => quirks,
            Err(error) => {
                warn!("Enrolling without quirks: {error}");
                return Self::default();
            }
        };

        if quirks.0.is_empty() {
            debug!("This boot has no quirks");
            return quirks;
        }

        info!(
            "This boot has quirks: {}",
            serde_json::to_string(&quirks).unwrap_or_default()
        );
        quirks
    }

    /// Reads the configuration and the event log of this boot and finds the
    /// quirks in them.
    fn find_in_event_log(
        policies: &[&LuksTpmEnrollmentPolicy],
        device: &impl Device,
    ) -> Result<Self, PuavoError> {
        debug!("Reading quirks from {CONFIGURATION_FILE} and {EVENT_LOG}");
        let configuration = read_configuration(Path::new(CONFIGURATION_FILE))?;
        let events = event_log::read(Path::new(EVENT_LOG))?;

        Self::find(policies, &events, &configuration, device)
    }

    /// Finds the configured quirks that the events show. A quirk is found
    /// when its measurement, not a variant, is logged directly after a
    /// measurement it may appear after. The digests come from the chains of
    /// the policies.
    pub fn find(
        policies: &[&LuksTpmEnrollmentPolicy],
        events: &[Event],
        configuration: &Configuration,
        device: &impl Device,
    ) -> Result<Self, PuavoError> {
        let mut found_by_register = BTreeMap::new();

        for (register, quirks) in configuration {
            debug!("Looking for {} quirks of {register}", quirks.len());

            let index = pcr_index(register).ok_or_else(|| {
                PuavoError::MalformedChain(format!(
                    "'{register}' is not a PCR name"
                ))
            })?;

            let chains: Vec<&[Measurement]> = policies
                .iter()
                .filter_map(|policy| {
                    policy.specific_pcrs.as_ref()?.get(register)?.as_deref()
                })
                .collect();
            let names_by_digest = find_names_by_digest(&chains, device);

            let logged_digests: Vec<String> = events
                .iter()
                .filter(|event| event.register == index)
                .map(|event| hex::encode(&event.digest))
                .collect();
            debug!("The log has {} events of {register}", logged_digests.len());

            let active_quirks: Vec<Quirk> = quirks
                .iter()
                .filter_map(|quirk| {
                    let digests =
                        find_measurement_digests(quirk, &chains, device);
                    let after = find_logged_position(
                        quirk,
                        &names_by_digest,
                        &digests,
                        &logged_digests,
                    )?;
                    Some(Quirk { after: vec![after], ..quirk.clone() })
                })
                .collect();

            if !active_quirks.is_empty() {
                found_by_register.insert(register.clone(), active_quirks);
            }
        }

        let quirks = Self(found_by_register);
        let needed_chains = quirks.count_chains();
        debug!("The quirks expand each policy into {needed_chains} chains");
        if needed_chains > MAX_CHAINS {
            return Err(PuavoError::TooManyQuirkChains {
                needed: needed_chains,
                allowed: MAX_CHAINS,
            });
        }

        Ok(quirks)
    }

    /// Returns one copy of the policy for each combination of the
    /// measurements and variants of the quirks, with the quirks placed into
    /// its chains.
    pub fn expand(
        &self,
        policy: &LuksTpmEnrollmentPolicy,
    ) -> Vec<LuksTpmEnrollmentPolicy> {
        let Some(pcrs) = &policy.specific_pcrs else {
            return vec![policy.clone()];
        };

        // Each register multiplies the copies by the number of its chains.
        let mut copies = vec![BTreeMap::new()];
        for (register, chain) in pcrs {
            let chains = match (chain, self.0.get(register)) {
                (Some(chain), Some(quirks)) => {
                    place_quirks(chain, quirks).into_iter().map(Some).collect()
                }
                _ => vec![chain.clone()],
            };

            let mut extended = Vec::with_capacity(copies.len() * chains.len());
            for copy in &copies {
                for chain in &chains {
                    let mut copy = copy.clone();
                    copy.insert(register.clone(), chain.clone());
                    extended.push(copy);
                }
            }
            copies = extended;
        }

        debug!("The quirks expand the policy into {} copies", copies.len());
        copies
            .into_iter()
            .map(|pcrs| LuksTpmEnrollmentPolicy {
                specific_pcrs: Some(pcrs),
                ..policy.clone()
            })
            .collect()
    }

    /// Counts the chains the quirks expand a policy into.
    fn count_chains(&self) -> usize {
        self.0
            .values()
            .flatten()
            .map(|quirk| quirk.measurement_and_variants().len())
            .product()
    }
}

/// Reads the quirks that a firmware may have from a file. Fails when a
/// measurement triggers more than one quirk of a register.
pub fn read_configuration(path: &Path) -> Result<Configuration, PuavoError> {
    let contents = fs::read(path)?;

    let configuration: Configuration = serde_json::from_slice(&contents)
        .map_err(|error| {
            PuavoError::MalformedChain(format!("{}: {error}", path.display()))
        })?;

    for (register, quirks) in &configuration {
        let Some(shared) = find_trigger_of_two_quirks(quirks) else {
            continue;
        };

        return Err(PuavoError::MalformedChain(format!(
            "{}: {shared} triggers more than one quirk of {register}",
            path.display()
        )));
    }

    debug!(
        "{} configures quirks for {:?}",
        path.display(),
        configuration.keys()
    );
    Ok(configuration)
}

/// Finds a measurement that triggers more than one of the quirks.
fn find_trigger_of_two_quirks(quirks: &[Quirk]) -> Option<&Measurement> {
    quirks.iter().enumerate().find_map(|(index, quirk)| {
        quirks[..index]
            .iter()
            .any(|earlier| earlier.measurement == quirk.measurement)
            .then_some(&quirk.measurement)
    })
}

/// Evaluates the chains and returns the name of each named measurement by
/// its digest. A name has several digests when the chains measure it from
/// different contents, such as a database before and after an update.
fn find_names_by_digest(
    chains: &[&[Measurement]],
    device: &impl Device,
) -> BTreeMap<String, String> {
    let mut names_by_digest = BTreeMap::new();

    for chain in chains {
        let prediction = match Chain::new(chain).predict(device) {
            Ok(prediction) => prediction,
            Err(error) => {
                debug!("A chain cannot be evaluated: {error}");
                continue;
            }
        };

        for (measurement, step) in chain.iter().zip(prediction.steps) {
            if let Some(name) = measurement.name() {
                names_by_digest.insert(step.digest, name.to_string());
            }
        }
    }

    debug!("The chains have {} named digests", names_by_digest.len());
    names_by_digest
}

/// Evaluates the measurement of the quirk and returns its digests. It is
/// evaluated after each chain, so it can read the variables the chain
/// measures.
fn find_measurement_digests(
    quirk: &Quirk,
    chains: &[&[Measurement]],
    device: &impl Device,
) -> BTreeSet<String> {
    let measurement = &quirk.measurement;
    let mut digests = BTreeSet::new();

    for chain in chains {
        let mut probe = chain.to_vec();
        probe.push(measurement.clone());

        match Chain::new(&probe).predict(device) {
            Ok(prediction) => {
                let Some(step) = prediction.steps.last() else {
                    continue;
                };
                debug!("{measurement} measures as {}", step.digest);
                digests.insert(step.digest.clone());
            }
            Err(error) => {
                debug!("{measurement} cannot be evaluated: {error}");
            }
        }
    }

    digests
}

/// Finds the named measurement logged directly before one of the digests of
/// the quirk's measurement. None when the quirk is not in the log.
fn find_logged_position(
    quirk: &Quirk,
    names_by_digest: &BTreeMap<String, String>,
    digests: &BTreeSet<String>,
    logged_digests: &[String],
) -> Option<String> {
    for pair in logged_digests.windows(2) {
        let [before, current] = pair else {
            continue;
        };

        if !digests.contains(current) {
            continue;
        }

        let Some(name) = names_by_digest.get(before) else {
            debug!(
                "{current} is logged after {before}, which is no named measurement"
            );
            continue;
        };

        if !quirk.may_appear_after(name) {
            debug!(
                "{current} is logged after {name}, which the quirk does not list"
            );
            continue;
        }

        debug!("{current} is logged after {name}");
        return Some(name.clone());
    }

    debug!("{} is not logged after {:?}", quirk.measurement, quirk.after);
    None
}

/// Places each quirk after the measurement it was found after and returns one
/// chain for each combination of their measurements and variants. A quirk
/// whose position is not in the chain is left out.
fn place_quirks(
    chain: &[Measurement],
    quirks: &[Quirk],
) -> Vec<Vec<Measurement>> {
    let mut chains = vec![Vec::new()];
    let mut is_placed = vec![false; quirks.len()];

    for measurement in chain {
        for expanded in &mut chains {
            expanded.push(measurement.clone());
        }

        let Some(name) = measurement.name() else {
            continue;
        };

        for (index, quirk) in quirks.iter().enumerate() {
            if !quirk.may_appear_after(name) {
                continue;
            }

            debug!(
                "Placing {} and {} variants after {name}",
                quirk.measurement,
                quirk.variants.len()
            );
            chains = branch_chains(&chains, &quirk.measurement_and_variants());
            is_placed[index] = true;
        }
    }

    for (quirk, is_placed) in quirks.iter().zip(is_placed) {
        if !is_placed {
            warn!(
                "The chain has none of {:?}, a quirk is left out",
                quirk.after
            );
        }
    }

    chains
}

/// Returns a copy of each chain for each measurement, with the measurement
/// appended:
///
///   chains [x, y], measurements [A, B]  ->  [xA, xB, yA, yB]
fn branch_chains(
    chains: &[Vec<Measurement>],
    measurements: &[Measurement],
) -> Vec<Vec<Measurement>> {
    let mut branched = Vec::with_capacity(chains.len() * measurements.len());

    for chain in chains {
        for measurement in measurements {
            let mut copy = chain.clone();
            copy.push(measurement.clone());
            branched.push(copy);
        }
    }

    branched
}

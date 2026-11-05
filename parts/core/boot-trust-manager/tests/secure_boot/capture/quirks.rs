//! Finds configured quirks in the captured slab boot. The capture measures
//! this chain into PCR 7, each measurement with the name the tests give it:
//!
//!   secure-boot  platform-key  key-exchange-keys  signature-database
//!   revocations  separator  first-authority  base  second-authority
//!
//! A quirk is a measurement the firmware adds after one of the named
//! measurements it lists, as a firmware logs the authority of an option
//! ROM it verifies. The tests insert such events into the captured log:
//!
//!   captured:  ... revocations  separator  first-authority ...
//!   inserted:  ... revocations  separator  A  first-authority ...
//!
//! The quirk is the measurement A with the variant B. Any measurement the
//! capture can evaluate serves, so the tests use the authorities of the
//! certificates the capture holds:
//!
//!   A  the platform key certificate
//!   B  the key exchange key certificate
//!   C  the slab certificate in the signature database
//!
//! A found quirk expands the chain into one chain for the measurement and
//! one for each variant:
//!
//!   ... separator  A  first-authority ...    the boot as logged
//!   ... separator  B  first-authority ...    the boot after A becomes B

use std::{collections::BTreeMap, fs};

use boot_trust_manager::error::PuavoError;
use boot_trust_manager::luks::tokens::LuksTpmEnrollmentPolicy;
use boot_trust_manager::secure_boot::chain::{Chain, Entry, Measurement};
use boot_trust_manager::secure_boot::event_log::{self, Event};
use boot_trust_manager::secure_boot::quirks::{
    self, Configuration, Quirk, Quirks,
};
use serde_json::json;
use sha2::{Digest, Sha256};
use tempfile::TempDir;

use super::{
    Capture, CapturedDevice, INITIAL_REGISTER_VALUE, REGISTER, extend_register,
    slab, write_variables_into_directory,
};

/// The PCR of the chain, as written in a policy.
const REGISTER_NAME: &str = "7:sha256";

/// Names of the captured chain, in its order.
const CHAIN_NAMES: [&str; 9] = [
    "secure-boot",
    "platform-key",
    "key-exchange-keys",
    "signature-database",
    "revocations",
    "separator",
    "first-authority",
    "base",
    "second-authority",
];

/// The measurements the configured quirk may appear after: before the
/// separator on some firmware, after it on others.
const QUIRK_POSITIONS: [&str; 2] = ["revocations", "separator"];

/// The authority of the certificate in a database variable.
fn authority_of_certificate(database: &str, subject: &str) -> Measurement {
    Measurement::Authority {
        database: database.to_string(),
        entry: Entry::Subject(subject.to_string()),
    }
}

/// The measurement A.
fn platform_key_authority() -> Measurement {
    authority_of_certificate("PK", "Capture PK")
}

/// The measurement B.
fn key_exchange_key_authority() -> Measurement {
    authority_of_certificate("KEK", "Capture KEK")
}

/// The measurement C.
fn signature_database_authority() -> Measurement {
    authority_of_certificate("db", "Capture Slab")
}

/// A quirk that may appear after the named measurements.
fn quirk_after(
    after: &[&str],
    measurement: Measurement,
    variants: &[Measurement],
) -> Quirk {
    Quirk {
        after: after.iter().map(|name| name.to_string()).collect(),
        measurement,
        variants: variants.to_vec(),
    }
}

/// Configures the quirks for the register of the chain.
fn configure_for_register(quirks: Vec<Quirk>) -> Configuration {
    BTreeMap::from([(REGISTER_NAME.to_string(), quirks)])
}

/// Configures the quirk A with the variant B at the quirk positions.
fn configure_a_with_variant_b() -> Configuration {
    configure_for_register(vec![quirk_after(
        &QUIRK_POSITIONS,
        platform_key_authority(),
        &[key_exchange_key_authority()],
    )])
}

/// The captured slab boot with its chain named.
struct CapturedBoot {
    capture: Capture,
    _directory: TempDir,
    named_chain: Vec<Measurement>,
    device: CapturedDevice,
}

impl CapturedBoot {
    fn read() -> Self {
        let capture = Capture::read(slab::PROFILE);
        let (directory, _) = write_variables_into_directory(&capture);
        let device = CapturedDevice::of(&capture);

        let named_chain = slab::chain(directory.path())
            .into_iter()
            .zip(CHAIN_NAMES)
            .map(|(measurement, name)| Measurement::Named {
                name: name.to_string(),
                measurement: Box::new(measurement),
            })
            .collect();

        Self { capture, _directory: directory, named_chain, device }
    }

    /// An enrollment policy that binds the named chain.
    fn enrollment_policy(&self) -> LuksTpmEnrollmentPolicy {
        LuksTpmEnrollmentPolicy {
            specific_pcrs: Some(BTreeMap::from([(
                REGISTER_NAME.to_string(),
                Some(self.named_chain.clone()),
            )])),
            public_key_pcrs_expressions: Vec::new(),
            public_key_directory: None,
            public_keys: Vec::new(),
        }
    }

    /// The digest of the measurement, measured after the chain so that it can
    /// read the variables.
    fn digest_after_chain(&self, measurement: Measurement) -> String {
        let mut probe = self.named_chain.clone();
        probe.push(measurement);

        let prediction = Chain::new(&probe).predict(&self.device).unwrap();
        prediction.steps.last().unwrap().digest.clone()
    }

    /// The captured log with an event of the given digest inserted directly
    /// after each given named measurement.
    fn log_with_inserted_events(
        &self,
        inserted: &[(&str, &str)],
    ) -> Vec<Event> {
        let prediction =
            Chain::new(&self.named_chain).predict(&self.device).unwrap();
        let names_by_digest: BTreeMap<String, &str> = prediction
            .steps
            .iter()
            .zip(CHAIN_NAMES)
            .map(|(step, name)| (step.digest.clone(), name))
            .collect();

        let mut events = Vec::new();
        for event in event_log::parse(self.capture.stored_event_log()).unwrap()
        {
            let name = match event.register {
                REGISTER => {
                    names_by_digest.get(&hex::encode(&event.digest)).copied()
                }
                _ => None,
            };
            events.push(event);

            for (after, digest) in inserted {
                if name == Some(*after) {
                    events.push(Event {
                        register: REGISTER,
                        digest: hex::decode(digest).unwrap(),
                    });
                }
            }
        }

        events
    }

    /// Finds the configured quirks that the events show for the chain.
    fn find_quirks(
        &self,
        events: &[Event],
        configuration: &Configuration,
    ) -> Result<Quirks, PuavoError> {
        let policies = [&self.enrollment_policy()];
        Quirks::find(&policies, events, configuration, &self.device)
    }

    /// Predicts each chain the quirks expand the chain into.
    fn try_predict_expanded_chains(
        &self,
        quirks: &Quirks,
    ) -> Vec<Result<String, PuavoError>> {
        quirks
            .expand(&self.enrollment_policy())
            .iter()
            .map(|policy| {
                let pcrs = policy.specific_pcrs.as_ref().unwrap();
                let chain = pcrs[REGISTER_NAME].as_ref().unwrap();
                Chain::new(chain)
                    .predict(&self.device)
                    .map(|prediction| prediction.value)
            })
            .collect()
    }

    /// Predicts each chain the quirks expand the chain into, and expects
    /// every prediction to succeed.
    fn predict_expanded_chains(&self, quirks: &Quirks) -> Vec<String> {
        self.try_predict_expanded_chains(quirks)
            .into_iter()
            .map(|prediction| prediction.unwrap())
            .collect()
    }
}

/// The value of the register after the events, as the TPM extends it.
fn replay_register(events: &[Event]) -> String {
    events
        .iter()
        .filter(|event| event.register == REGISTER)
        .fold(hex::encode(INITIAL_REGISTER_VALUE), |value, event| {
            extend_register(&value, &hex::encode(&event.digest))
        })
}

#[test]
fn captured_log_without_inserted_events_has_no_quirk() {
    // captured:  ... revocations  separator  first-authority ...
    let boot = CapturedBoot::read();
    let log = boot.log_with_inserted_events(&[]);

    let quirks = boot.find_quirks(&log, &configure_a_with_variant_b());

    assert_eq!(quirks.unwrap(), Quirks::default());
    assert_eq!(
        boot.predict_expanded_chains(&Quirks::default()),
        [replay_register(&log)]
    );
    assert_eq!(replay_register(&log), boot.capture.register(REGISTER));
}

#[test]
fn quirk_is_placed_after_the_measurement_it_is_logged_after() {
    // before the separator:  ... revocations  A  separator ...
    // after the separator:   ... separator  A  first-authority ...
    let boot = CapturedBoot::read();
    let digest_of_a = boot.digest_after_chain(platform_key_authority());

    for after in QUIRK_POSITIONS {
        let log = boot.log_with_inserted_events(&[(after, &digest_of_a)]);

        let quirks =
            boot.find_quirks(&log, &configure_a_with_variant_b()).unwrap();

        let found = serde_json::to_value(&quirks).unwrap();
        assert_eq!(found[REGISTER_NAME][0]["after"], json!([after]));
        assert_eq!(
            boot.predict_expanded_chains(&quirks)[0],
            replay_register(&log)
        );
    }
}

#[test]
fn quirk_gives_a_chain_for_its_measurement_and_for_each_variant() {
    // logged:  ... separator  A  first-authority ...
    // chains:  ... separator  A  first-authority ...   this boot
    //          ... separator  B  first-authority ...   the boot after
    let boot = CapturedBoot::read();
    let log_with_a = boot.log_with_inserted_events(&[(
        "separator",
        &boot.digest_after_chain(platform_key_authority()),
    )]);
    let log_with_b = boot.log_with_inserted_events(&[(
        "separator",
        &boot.digest_after_chain(key_exchange_key_authority()),
    )]);

    let quirks =
        boot.find_quirks(&log_with_a, &configure_a_with_variant_b()).unwrap();

    assert_eq!(
        boot.predict_expanded_chains(&quirks),
        [replay_register(&log_with_a), replay_register(&log_with_b)]
    );
}

#[test]
fn logged_variant_does_not_trigger_its_quirk() {
    // quirk:   A with variant B
    // logged:  ... separator  B  first-authority ...
    let boot = CapturedBoot::read();
    let log = boot.log_with_inserted_events(&[(
        "separator",
        &boot.digest_after_chain(key_exchange_key_authority()),
    )]);

    let quirks = boot.find_quirks(&log, &configure_a_with_variant_b());

    assert_eq!(quirks.unwrap(), Quirks::default());
}

#[test]
fn quirk_without_variants_gives_a_single_chain() {
    // quirks:  A with variant B, and B without variants
    // logged:  ... separator  B  first-authority ...
    // chains:  ... separator  B  first-authority ...
    let boot = CapturedBoot::read();
    let configuration = configure_for_register(vec![
        quirk_after(
            &QUIRK_POSITIONS,
            platform_key_authority(),
            &[key_exchange_key_authority()],
        ),
        quirk_after(&QUIRK_POSITIONS, key_exchange_key_authority(), &[]),
    ]);
    let log = boot.log_with_inserted_events(&[(
        "separator",
        &boot.digest_after_chain(key_exchange_key_authority()),
    )]);

    let quirks = boot.find_quirks(&log, &configuration).unwrap();

    assert_eq!(boot.predict_expanded_chains(&quirks), [replay_register(&log)]);
}

#[test]
fn configuration_where_two_quirks_share_a_measurement_is_refused() {
    // quirks:  A with variant B, and A without variants
    let directory = TempDir::new().unwrap();
    let path = directory.path().join("quirks.json");
    let configuration = configure_for_register(vec![
        quirk_after(
            &QUIRK_POSITIONS,
            platform_key_authority(),
            &[key_exchange_key_authority()],
        ),
        quirk_after(&QUIRK_POSITIONS, platform_key_authority(), &[]),
    ]);
    fs::write(&path, serde_json::to_vec(&configuration).unwrap()).unwrap();

    let result = quirks::read_configuration(&path);

    assert!(matches!(result, Err(PuavoError::MalformedChain(_))));
}

#[test]
fn quirk_logged_after_an_unlisted_measurement_is_ignored() {
    // ... base  A  second-authority ...   base is not a listed position
    let boot = CapturedBoot::read();
    let log = boot.log_with_inserted_events(&[(
        "base",
        &boot.digest_after_chain(platform_key_authority()),
    )]);

    let quirks = boot.find_quirks(&log, &configure_a_with_variant_b());

    assert_eq!(quirks.unwrap(), Quirks::default());
}

#[test]
fn event_that_no_quirk_describes_is_ignored() {
    // ... separator  X  first-authority ...   X is no measurement of a quirk
    let boot = CapturedBoot::read();
    let unknown = hex::encode(Sha256::digest(b"an unknown event"));
    let log = boot.log_with_inserted_events(&[("separator", &unknown)]);

    let quirks = boot.find_quirks(&log, &configure_a_with_variant_b());

    assert_eq!(quirks.unwrap(), Quirks::default());
}

#[test]
fn two_quirks_logged_in_one_boot_are_both_found() {
    // quirks:  A with variant B after separator, B with variant A after base
    // logged:  ... separator  A  first-authority  base  B  second-authority
    // chains:  2 x 2, one for each pair of their measurements and variants
    let boot = CapturedBoot::read();
    let log = boot.log_with_inserted_events(&[
        ("separator", &boot.digest_after_chain(platform_key_authority())),
        ("base", &boot.digest_after_chain(key_exchange_key_authority())),
    ]);
    let configuration = configure_for_register(vec![
        quirk_after(
            &["separator"],
            platform_key_authority(),
            &[key_exchange_key_authority()],
        ),
        quirk_after(
            &["base"],
            key_exchange_key_authority(),
            &[platform_key_authority()],
        ),
    ]);

    let quirks = boot.find_quirks(&log, &configuration).unwrap();

    let predicted = boot.predict_expanded_chains(&quirks);
    assert_eq!(predicted.len(), 4);
    assert_eq!(predicted[0], replay_register(&log));
}

#[test]
fn quirks_needing_more_chains_than_the_bound_are_refused() {
    // Three quirks with a variant each would need 2 x 2 x 2 chains, more
    // than the bound of four tokens.
    let boot = CapturedBoot::read();
    let log = boot.log_with_inserted_events(&[
        ("revocations", &boot.digest_after_chain(platform_key_authority())),
        ("separator", &boot.digest_after_chain(key_exchange_key_authority())),
        ("base", &boot.digest_after_chain(signature_database_authority())),
    ]);
    let configuration = configure_for_register(vec![
        quirk_after(
            &["revocations"],
            platform_key_authority(),
            &[key_exchange_key_authority()],
        ),
        quirk_after(
            &["separator"],
            key_exchange_key_authority(),
            &[signature_database_authority()],
        ),
        quirk_after(
            &["base"],
            signature_database_authority(),
            &[platform_key_authority()],
        ),
    ]);

    let result = boot.find_quirks(&log, &configuration);

    assert!(matches!(result, Err(PuavoError::TooManyQuirkChains { .. })));
}

#[test]
fn chain_of_a_variant_missing_from_the_database_fails_to_predict() {
    // The variant names a certificate the KEK does not hold, as a db without
    // the successor certificate would. Only the chain with A is predicted.
    let boot = CapturedBoot::read();
    let log = boot.log_with_inserted_events(&[(
        "separator",
        &boot.digest_after_chain(platform_key_authority()),
    )]);
    let missing = authority_of_certificate("KEK", "Not In The Capture");
    let configuration = configure_for_register(vec![quirk_after(
        &QUIRK_POSITIONS,
        platform_key_authority(),
        &[missing],
    )]);

    let quirks = boot.find_quirks(&log, &configuration).unwrap();

    let is_predicted: Vec<bool> = boot
        .try_predict_expanded_chains(&quirks)
        .iter()
        .map(|prediction| prediction.is_ok())
        .collect();
    assert_eq!(is_predicted, [true, false]);
}

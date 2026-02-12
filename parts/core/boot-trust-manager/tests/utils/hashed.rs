use puavo_boot_trust_manager::utils::hashed::Hashed;

#[test]
fn hashed_returns_consistent_value_for_same_input() {
    let value = "test string";
    assert_eq!(value.hashed(), value.hashed());
}

#[test]
fn hashed_returns_different_values_for_different_inputs() {
    assert_ne!("first".hashed(), "second".hashed());
}

#[test]
fn hashed_works_with_structs() {
    #[derive(Hash)]
    struct Config {
        name: String,
        version: u32,
    }

    let config1 = Config { name: "test".to_string(), version: 1 };
    let config2 = Config { name: "test".to_string(), version: 1 };
    let config3 = Config { name: "test".to_string(), version: 2 };

    assert_eq!(config1.hashed(), config2.hashed());
    assert_ne!(config1.hashed(), config3.hashed());
}

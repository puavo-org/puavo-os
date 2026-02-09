pub mod display;
pub mod efi;
pub mod luks;
pub mod tpm;

pub const TEST_ROOT: &str = "/tmp/boot-trust-manager-test-root";

pub fn tests_directory() -> String {
    let current_directory =
        std::env::current_dir().expect("Failed to get current directory");
    format!("{}/tests", current_directory.display())
}

pub fn fixture_directory(fixture_category: &str) -> String {
    format!("{}/fixtures/{}", tests_directory(), fixture_category)
}

pub fn script(script_name: &str) -> String {
    format!("{}/scripts/{}", tests_directory(), script_name)
}

use std::fs;

use serial_test::serial;
use tempfile::TempDir;

use puavo_boot_trust_manager::utils::locale::{
    Locale, Strings, read_locale_from_grub_environment, reset_strings,
    set_strings, strings,
};

fn write_grub_environment(directory: &std::path::Path, contents: &str) {
    let grub_directory = directory.join("EFI/puavo/grub");
    fs::create_dir_all(&grub_directory).unwrap();
    fs::write(grub_directory.join("grubenv"), contents).unwrap();
}

#[test]
#[serial]
fn finnish_language_resolves_to_finnish_catalog() {
    let directory = TempDir::new().unwrap();
    write_grub_environment(
        directory.path(),
        "# GRUB Environment Block\nlang=fi_FI.UTF-8\n",
    );

    let locale = read_locale_from_grub_environment(directory.path());
    assert_eq!(locale, Locale::Finnish);

    let installed = Strings::for_locale(locale);
    set_strings(installed);
    let active = strings();
    assert_eq!(active.pin_prompt, installed.pin_prompt);
    assert_ne!(
        active.recovery_key_prompt,
        Strings::for_locale(Locale::English).recovery_key_prompt,
        "Finnish catalog should differ from English",
    );

    reset_strings();
}

#[test]
#[serial]
fn missing_grub_environment_falls_back_to_english_catalog() {
    let directory = TempDir::new().unwrap();

    let locale = read_locale_from_grub_environment(directory.path());
    assert_eq!(locale, Locale::English);

    reset_strings();
    let english = Strings::for_locale(Locale::English);
    assert_eq!(strings().pin_prompt, english.pin_prompt);
    assert_eq!(strings().recovery_key_prompt, english.recovery_key_prompt);
    assert_eq!(strings().unlock_failed, english.unlock_failed);
    assert_eq!(
        strings().configuration_failed_prefix,
        english.configuration_failed_prefix,
    );
}

#[test]
#[serial]
fn empty_language_value_falls_back_to_english_catalog() {
    let directory = TempDir::new().unwrap();
    write_grub_environment(
        directory.path(),
        "# GRUB Environment Block\nlang=\n",
    );

    let locale = read_locale_from_grub_environment(directory.path());
    assert_eq!(locale, Locale::English);
}

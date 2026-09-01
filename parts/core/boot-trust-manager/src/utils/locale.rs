use std::{fs, path::Path, sync::RwLock};

use log::debug;

const GRUB_ENVIRONMENT_RELATIVE_PATH: &str = "EFI/puavo/grub/grubenv";

/// A language in which prompts and messages can be shown to the user.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Locale {
    English,
    Finnish,
    Swedish,
    German,
}

impl Locale {
    /// Identify the language from a configured locale string such as
    /// `fi_FI.UTF-8`. Unrecognized or malformed input falls back to
    /// English so the user still gets a readable prompt.
    pub fn from_language_value(value: &str) -> Locale {
        let trimmed = value.trim();
        let base = trimmed.strip_suffix(".UTF-8").unwrap_or(trimmed);
        match base {
            "en_GB" | "en_US" => Locale::English,
            "fi_FI" => Locale::Finnish,
            "sv_FI" | "sv_SE" => Locale::Swedish,
            "de_DE" => Locale::German,
            _ => Locale::English,
        }
    }
}

/// The full set of prompts and status messages in a single language.
pub struct Strings {
    pub pin_prompt: &'static str,
    pub recovery_key_prompt: &'static str,
    pub pin_or_recovery_key_prompt: &'static str,
    pub unlock_failed: &'static str,
    pub change_pin_question: &'static str,
    pub enter_new_pin: &'static str,
    pub remove_pin_question: &'static str,
    pub confirm_new_pin: &'static str,
    pub pins_do_not_match: &'static str,
    pub pin_too_short: &'static str,
    pub pin_invalid_characters: &'static str,
    pub configuring_disk_encryption: &'static str,
    pub updating_secure_boot: &'static str,
    pub rebooting: &'static str,
    pub configuration_failed_prefix: &'static str,
    pub keymap_hint: &'static str,
}

impl Strings {
    pub fn for_locale(locale: Locale) -> &'static Strings {
        match locale {
            Locale::English => &ENGLISH_STRINGS,
            Locale::Finnish => &FINNISH_STRINGS,
            Locale::Swedish => &SWEDISH_STRINGS,
            Locale::German => &GERMAN_STRINGS,
        }
    }
}

static ENGLISH_STRINGS: Strings = Strings {
    pin_prompt: "PIN",
    recovery_key_prompt: "Recovery Key",
    pin_or_recovery_key_prompt: "PIN or Recovery Key",
    unlock_failed: "Unlocking failed",
    change_pin_question: "Change PIN?",
    enter_new_pin: "Enter new PIN (empty to remove)",
    remove_pin_question: "Remove PIN protection?",
    confirm_new_pin: "Confirm new PIN",
    pins_do_not_match: "PINs do not match",
    pin_too_short: "PIN is too short, use at least 4 characters",
    pin_invalid_characters: "PIN may only contain letters and digits",
    configuring_disk_encryption: "Configuring disk encryption...",
    updating_secure_boot: "Updating Secure Boot configuration...",
    rebooting: "Rebooting...",
    configuration_failed_prefix: "Configuration failed",
    keymap_hint: "Keymap",
};

static FINNISH_STRINGS: Strings = Strings {
    pin_prompt: "PIN",
    recovery_key_prompt: "Palautusavain",
    pin_or_recovery_key_prompt: "PIN tai palautusavain",
    unlock_failed: "Avaaminen epäonnistui",
    change_pin_question: "Vaihda PIN-koodi?",
    enter_new_pin: "Anna uusi PIN-koodi (tyhjä poistaa)",
    remove_pin_question: "Poista PIN-suojaus?",
    confirm_new_pin: "Vahvista uusi PIN-koodi",
    pins_do_not_match: "PIN-koodit eivät täsmää",
    pin_too_short: "PIN-koodi on liian lyhyt, käytä vähintään 4 merkkiä",
    pin_invalid_characters: "PIN-koodi voi sisältää vain kirjaimia ja numeroita",
    configuring_disk_encryption: "Määritetään levyn salausta...",
    updating_secure_boot: "Päivitetään Secure Boot -asetuksia...",
    rebooting: "Käynnistetään uudelleen...",
    configuration_failed_prefix: "Määritys epäonnistui",
    keymap_hint: "Näppäimistöasettelu",
};

static SWEDISH_STRINGS: Strings = Strings {
    pin_prompt: "PIN",
    recovery_key_prompt: "Återställningsnyckel",
    pin_or_recovery_key_prompt: "PIN eller återställningsnyckel",
    unlock_failed: "Upplåsning misslyckades",
    change_pin_question: "Ändra PIN-kod?",
    enter_new_pin: "Ange ny PIN-kod (tom för att ta bort)",
    remove_pin_question: "Ta bort PIN-skydd?",
    confirm_new_pin: "Bekräfta ny PIN-kod",
    pins_do_not_match: "PIN-koderna stämmer inte överens",
    pin_too_short: "PIN-koden är för kort, använd minst 4 tecken",
    pin_invalid_characters: "PIN-koden får endast innehålla bokstäver och siffror",
    configuring_disk_encryption: "Konfigurerar diskkryptering...",
    updating_secure_boot: "Uppdaterar Secure Boot-konfiguration...",
    rebooting: "Startar om...",
    configuration_failed_prefix: "Konfigurationen misslyckades",
    keymap_hint: "Tangentbordslayout",
};

static GERMAN_STRINGS: Strings = Strings {
    pin_prompt: "PIN",
    recovery_key_prompt: "Wiederherstellungsschlüssel",
    pin_or_recovery_key_prompt: "PIN oder Wiederherstellungsschlüssel",
    unlock_failed: "Entsperren fehlgeschlagen",
    change_pin_question: "PIN ändern?",
    enter_new_pin: "Neue PIN eingeben (leer zum Entfernen)",
    remove_pin_question: "PIN-Schutz entfernen?",
    confirm_new_pin: "Neue PIN bestätigen",
    pins_do_not_match: "PINs stimmen nicht überein",
    pin_too_short: "PIN ist zu kurz, mindestens 4 Zeichen verwenden",
    pin_invalid_characters: "PIN darf nur Buchstaben und Ziffern enthalten",
    configuring_disk_encryption: "Festplattenverschlüsselung wird konfiguriert...",
    updating_secure_boot: "Secure Boot-Konfiguration wird aktualisiert...",
    rebooting: "Neustart...",
    configuration_failed_prefix: "Konfiguration fehlgeschlagen",
    keymap_hint: "Tastaturbelegung",
};

static INSTALLED_STRINGS: RwLock<Option<&'static Strings>> = RwLock::new(None);

/// Choose the language used for prompts and messages from now on.
pub fn set_strings(strings: &'static Strings) {
    *INSTALLED_STRINGS.write().unwrap() = Some(strings);
}

/// Forget the chosen language and fall back to English.
pub fn reset_strings() {
    *INSTALLED_STRINGS.write().unwrap() = None;
}

/// Return the prompts and messages in the chosen language, or in
/// English when no language has been chosen.
pub fn strings() -> &'static Strings {
    INSTALLED_STRINGS.read().unwrap().unwrap_or(&ENGLISH_STRINGS)
}

/// Read the configured language from the GRUB environment on the
/// mounted EFI partition. Returns English when the file is missing
/// or names a language that is not supported.
pub fn read_locale_from_grub_environment(efi_mount_path: &Path) -> Locale {
    let grub_environment_path =
        efi_mount_path.join(GRUB_ENVIRONMENT_RELATIVE_PATH);

    let contents = match fs::read_to_string(&grub_environment_path) {
        Ok(contents) => contents,
        Err(error) => {
            debug!("Failed to read GRUB environment: {}", error);
            return Locale::English;
        }
    };

    let language_value = find_language_value(&contents).unwrap_or("");
    let locale = Locale::from_language_value(language_value);
    debug!("Resolved locale {:?} from GRUB environment", locale);
    locale
}

fn find_language_value(contents: &str) -> Option<&str> {
    contents
        .lines()
        .filter(|line| !line.starts_with('#'))
        .filter_map(|line| line.split_once('='))
        .find(|(key, _)| *key == "lang")
        .map(|(_, value)| value)
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn from_language_value_resolves_known_locales() {
        assert_eq!(Locale::from_language_value("en_GB.UTF-8"), Locale::English);
        assert_eq!(Locale::from_language_value("fi_FI.UTF-8"), Locale::Finnish);
        assert_eq!(Locale::from_language_value("sv_SE.UTF-8"), Locale::Swedish);
        assert_eq!(Locale::from_language_value("de_DE.UTF-8"), Locale::German);
    }

    #[test]
    fn from_language_value_accepts_optional_codeset_suffix() {
        assert_eq!(Locale::from_language_value("fi_FI"), Locale::Finnish);
        assert_eq!(Locale::from_language_value("fi_FI.UTF-8"), Locale::Finnish);
    }

    #[test]
    fn from_language_value_trims_surrounding_whitespace() {
        assert_eq!(
            Locale::from_language_value("  fi_FI.UTF-8\n"),
            Locale::Finnish,
        );
    }

    #[test]
    fn from_language_value_is_case_sensitive() {
        assert_eq!(Locale::from_language_value("FI_FI"), Locale::English);
    }

    #[test]
    fn from_language_value_falls_back_for_unsupported_input() {
        assert_eq!(Locale::from_language_value(""), Locale::English);
        assert_eq!(Locale::from_language_value("   "), Locale::English);
        assert_eq!(Locale::from_language_value("fr_FR.UTF-8"), Locale::English);
    }

    fn write_grub_environment(directory: &Path, contents: &str) {
        let grub_directory = directory.join("EFI/puavo/grub");
        fs::create_dir_all(&grub_directory).unwrap();
        fs::write(grub_directory.join("grubenv"), contents).unwrap();
    }

    #[test]
    fn read_locale_returns_value_from_language_entry() {
        let directory = TempDir::new().unwrap();
        write_grub_environment(
            directory.path(),
            "# GRUB Environment Block\nlang=fi_FI.UTF-8\n",
        );
        assert_eq!(
            read_locale_from_grub_environment(directory.path()),
            Locale::Finnish,
        );
    }

    #[test]
    fn read_locale_falls_back_when_file_missing() {
        let directory = TempDir::new().unwrap();
        assert_eq!(
            read_locale_from_grub_environment(directory.path()),
            Locale::English,
        );
    }

    #[test]
    fn read_locale_falls_back_when_language_entry_missing() {
        let directory = TempDir::new().unwrap();
        write_grub_environment(
            directory.path(),
            "# GRUB Environment Block\nfoo=bar\n",
        );
        assert_eq!(
            read_locale_from_grub_environment(directory.path()),
            Locale::English,
        );
    }

    #[test]
    fn read_locale_ignores_commented_language_line() {
        let directory = TempDir::new().unwrap();
        write_grub_environment(
            directory.path(),
            "# GRUB Environment Block\n#lang=fi_FI.UTF-8\n",
        );
        assert_eq!(
            read_locale_from_grub_environment(directory.path()),
            Locale::English,
        );
    }

    #[test]
    fn read_locale_picks_first_language_line_when_duplicates_exist() {
        let directory = TempDir::new().unwrap();
        write_grub_environment(
            directory.path(),
            "# GRUB Environment Block\nlang=fi_FI.UTF-8\nlang=de_DE.UTF-8\n",
        );
        assert_eq!(
            read_locale_from_grub_environment(directory.path()),
            Locale::Finnish,
        );
    }

    #[test]
    fn read_locale_falls_back_when_file_is_not_utf8() {
        let directory = TempDir::new().unwrap();
        let grub_directory = directory.path().join("EFI/puavo/grub");
        fs::create_dir_all(&grub_directory).unwrap();
        fs::write(grub_directory.join("grubenv"), [0xffu8, 0xfeu8]).unwrap();
        assert_eq!(
            read_locale_from_grub_environment(directory.path()),
            Locale::English,
        );
    }

    #[test]
    fn strings_global_reflects_install_and_reset() {
        reset_strings();
        assert_eq!(strings().pin_prompt, ENGLISH_STRINGS.pin_prompt);

        set_strings(Strings::for_locale(Locale::Finnish));
        assert_eq!(strings().pin_prompt, FINNISH_STRINGS.pin_prompt);

        reset_strings();
        assert_eq!(strings().pin_prompt, ENGLISH_STRINGS.pin_prompt);
    }
}

//! The code an owner gets when opening a recovery, as the person types it.

use std::fmt;

const ALPHABET: &str = "23456789ABCDEFGHJKLMNPQRSTUVWX";
const LENGTH: usize = 8;

/// A code in the form the service takes: eight characters of its alphabet
/// in upper case. Debug output leaves it out.
#[derive(Clone, PartialEq, Eq)]
pub struct RecoveryCode(String);

impl RecoveryCode {
    /// The code in a text as typed, in any case and with any spaces, such
    /// as abcd efgh. Nothing when it is not a code.
    pub fn parse(text: &str) -> Option<Self> {
        let code: String = text
            .chars()
            .filter(|character| !character.is_whitespace())
            .map(|character| character.to_ascii_uppercase())
            .collect();
        let is_code = code.chars().count() == LENGTH
            && code.chars().all(|character| ALPHABET.contains(character));
        is_code.then_some(RecoveryCode(code))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Debug for RecoveryCode {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("RecoveryCode(..)")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_code_is_taken_in_any_case_and_with_spaces() {
        let code = RecoveryCode::parse(" abcd 2345\n").unwrap();
        assert_eq!(code.as_str(), "ABCD2345");
        let code = RecoveryCode::parse("A B C D 2 3 4 5").unwrap();
        assert_eq!(code.as_str(), "ABCD2345");
    }

    #[test]
    fn a_code_outside_the_alphabet_or_of_another_length_is_refused() {
        assert_eq!(RecoveryCode::parse("ABCD1234"), None);
        assert_eq!(RecoveryCode::parse("ABCDWXYZ"), None);
        assert_eq!(RecoveryCode::parse("ABCD234"), None);
        assert_eq!(RecoveryCode::parse("ABCD23456"), None);
        assert_eq!(RecoveryCode::parse("ÄBCD2345"), None);
    }

    #[test]
    fn debug_output_leaves_the_code_out() {
        let code = RecoveryCode::parse("ABCD2345").unwrap();
        assert!(!format!("{code:?}").contains("ABCD"));
    }
}

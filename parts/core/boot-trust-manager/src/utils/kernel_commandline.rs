use std::fs;

const COMMANDLINE_PATH: &str = "/proc/cmdline";

/// Kernel parameter name for Puavo host type.
pub const PUAVO_HOST_TYPE: &str = "puavo.hosttype";

/// Read the kernel command line from `/proc/cmdline`.
pub fn read() -> Option<String> {
    fs::read_to_string(COMMANDLINE_PATH)
        .ok()
        .map(|string| string.trim().to_string())
        .filter(|string| !string.is_empty())
}

/// Parse a parameter value from a kernel command line string.
///
/// Returns an error if the parameter is specified more than once.
pub fn parse_parameter(
    commandline: &str,
    key: &str,
) -> Result<Option<String>, String> {
    let prefix = format!("{}=", key);
    let mut values = commandline
        .split_whitespace()
        .filter_map(|section| section.strip_prefix(&prefix));

    let value = values.next();

    if values.next().is_some() {
        Err(format!(
            "Multiple values specified for '{}'",
            key
        ))
    } else {
        Ok(value.map(|string| string.to_string()))
    }
}

/// Get a kernel parameter from the current system's command line.
///
/// Returns an error if the parameter is specified more than once.
pub fn get_parameter(key: &str) -> Result<Option<String>, String> {
    match read() {
        Some(commandline) => parse_parameter(&commandline, key),
        None => Ok(None),
    }
}

/// Get the current Puavo host type from the kernel command line.
///
/// Returns an error if the host type is specified more than once.
pub fn get_host_type() -> Result<Option<String>, String> {
    get_parameter(PUAVO_HOST_TYPE)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_parameter_found() {
        let commandline = "root=/dev/sda1 puavo.hosttype=laptop quiet splash";
        assert_eq!(
            parse_parameter(commandline, "puavo.hosttype"),
            Ok(Some("laptop".to_string()))
        );
    }

    #[test]
    fn test_parse_parameter_not_found() {
        let commandline = "root=/dev/sda1 quiet splash";
        assert_eq!(
            parse_parameter(commandline, "puavo.hosttype"),
            Ok(None)
        );
    }

    #[test]
    fn test_parse_parameter_multiple_values_errors() {
        let commandline = "puavo.hosttype=first puavo.hosttype=second";
        assert!(parse_parameter(commandline, "puavo.hosttype").is_err());
    }

    #[test]
    fn test_parse_parameter_similar_names() {
        let commandline = "puavo.hosttype2=wrong puavo.hosttype=correct";
        assert_eq!(
            parse_parameter(commandline, "puavo.hosttype"),
            Ok(Some("correct".to_string()))
        );
    }

    #[test]
    fn test_parse_parameter_empty_value() {
        let commandline = "puavo.hosttype= other=value";
        assert_eq!(
            parse_parameter(commandline, "puavo.hosttype"),
            Ok(Some("".to_string()))
        );
    }

    #[test]
    fn test_parse_parameter_with_special_chars() {
        let commandline = "root=UUID=abc-123 puavo.hosttype=laptop-v2";
        assert_eq!(
            parse_parameter(commandline, "puavo.hosttype"),
            Ok(Some("laptop-v2".to_string()))
        );
        assert_eq!(
            parse_parameter(commandline, "root"),
            Ok(Some("UUID=abc-123".to_string()))
        );
    }
}

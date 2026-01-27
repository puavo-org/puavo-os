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
pub fn parse_parameter(commandline: &str, key: &str) -> Option<String> {
    let prefix = format!("{}=", key);

    for part in commandline.split_whitespace() {
        if let Some(value) = part.strip_prefix(&prefix) {
            return Some(value.to_string());
        }
    }

    None
}

/// Get a kernel parameter from the current system's command line.
pub fn get_parameter(key: &str) -> Option<String> {
    read().and_then(|commandline| parse_parameter(&commandline, key))
}

/// Get the current Puavo host type from the kernel command line.
pub fn get_host_type() -> Option<String> {
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
            Some("laptop".to_string())
        );
    }

    #[test]
    fn test_parse_parameter_not_found() {
        let commandline = "root=/dev/sda1 quiet splash";
        assert_eq!(parse_parameter(commandline, "puavo.hosttype"), None);
    }

    #[test]
    fn test_parse_parameter_first_match() {
        let commandline = "puavo.hosttype=first puavo.hosttype=second";
        assert_eq!(
            parse_parameter(commandline, "puavo.hosttype"),
            Some("first".to_string())
        );
    }

    #[test]
    fn test_parse_parameter_similar_names() {
        let commandline = "puavo.hosttype2=wrong puavo.hosttype=correct";
        assert_eq!(
            parse_parameter(commandline, "puavo.hosttype"),
            Some("correct".to_string())
        );
    }

    #[test]
    fn test_parse_parameter_empty_value() {
        let commandline = "puavo.hosttype= other=value";
        assert_eq!(
            parse_parameter(commandline, "puavo.hosttype"),
            Some("".to_string())
        );
    }

    #[test]
    fn test_parse_parameter_with_special_chars() {
        let commandline = "root=UUID=abc-123 puavo.hosttype=laptop-v2";
        assert_eq!(
            parse_parameter(commandline, "puavo.hosttype"),
            Some("laptop-v2".to_string())
        );
        assert_eq!(
            parse_parameter(commandline, "root"),
            Some("UUID=abc-123".to_string())
        );
    }
}

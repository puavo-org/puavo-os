use std::process::Command;

use crate::common::script;

/// Reset TPM to fresh state.
pub fn reset() {
    let setup_script = script("tpm.sh");
    let status = Command::new(setup_script.as_str())
        .status()
        .unwrap_or_else(|_| panic!("Failed to execute '{}'", setup_script));
    assert!(status.success(), "TPM reset failed");
}

/// Read a PCR value as lowercase hex string.
pub fn read(pcr: u32) -> String {
    let output = Command::new("tpm2")
        .arg("pcrread")
        .arg(format!("sha256:{}", pcr))
        .output()
        .expect("Failed to execute 'tpm2 pcrread'");
    assert!(output.status.success(), "Command 'tpm2 pcrread' failed");

    let standard_output = String::from_utf8_lossy(&output.stdout);
    standard_output
        .lines()
        .find(|line| line.contains(':') && line.contains("0x"))
        .and_then(|line| line.split("0x").nth(1))
        .map(|hex| hex.trim().to_lowercase())
        .expect("Failed to parse output of 'tpm2 pcrread'")
}

/// Extend a PCR with a SHA256 hash value.
pub fn extend(pcr: u32, hash: &str) {
    let output = Command::new("tpm2")
        .arg("pcrextend")
        .arg(format!("{}:sha256={}", pcr, hash))
        .output()
        .expect("Failed to execute 'tpm2 pcrextend'");
    assert!(
        output.status.success(),
        "Command 'tpm2 pcrextend' failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

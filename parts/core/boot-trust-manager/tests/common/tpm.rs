use std::process::Command;

const SETUP_SCRIPT: &str = "/project/tests/scripts/tpm.sh";

/// Reset TPM to fresh state.
pub fn reset() {
    let status = Command::new(SETUP_SCRIPT)
        .status()
        .expect(format!("Failed to execute '{}'", SETUP_SCRIPT).as_str());
    assert!(status.success(), "TPM reset failed");
}

/// Read a PCR value as lowercase hex string.
pub fn read(pcr: u32) -> String {
    let output = Command::new("tpm2_pcrread")
        .arg(format!("sha256:{}", pcr))
        .output()
        .expect("Failed to execute 'tpm2_pcrread'");
    assert!(output.status.success(), "Command 'tpm2_pcrread' failed");

    let standard_output = String::from_utf8_lossy(&output.stdout);
    standard_output
        .lines()
        .find(|line| line.contains(':') && line.contains("0x"))
        .and_then(|line| line.split("0x").nth(1))
        .map(|hex| hex.trim().to_lowercase())
        .expect("Failed to parse output of 'tpm2_pcrread'")
}

/// Extend a PCR with a SHA256 hash value.
pub fn extend(pcr: u32, hash: &str) {
    let output = Command::new("tpm2_pcrextend")
        .arg(format!("{}:sha256={}", pcr, hash))
        .output()
        .expect("Failed to execute 'tpm2_pcrextend'");
    assert!(
        output.status.success(),
        "Command 'tpm2_pcrextend' failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

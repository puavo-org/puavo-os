use std::{
    thread,
    time::{Duration, Instant},
};

use log::warn;
use nix::libc::{WNOHANG, waitpid};

/// How often the children are checked
const POLL_INTERVAL: Duration = Duration::from_millis(50);

/// Waits until every child process has exited, or the timeout passes.
pub fn wait_for_children(timeout: Duration) {
    let deadline = Instant::now() + timeout;

    loop {
        let mut status = 0;
        // SAFETY: waitpid writes only into the given status.
        let pid = unsafe { waitpid(-1, &mut status, WNOHANG) };

        // One exited, there may be more.
        if pid > 0 {
            continue;
        }

        // None are left.
        if pid < 0 {
            return;
        }

        if Instant::now() >= deadline {
            warn!("Child processes still running after {:?}", timeout);
            return;
        }

        thread::sleep(POLL_INTERVAL);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;
    use std::process::Command;

    const TIMEOUT: Duration = Duration::from_secs(5);

    #[test]
    #[serial]
    fn waits_for_children_to_exit() {
        let started = Instant::now();
        let mut child = Command::new("sleep").arg("0.2").spawn().unwrap();

        wait_for_children(TIMEOUT);

        assert!(started.elapsed() < TIMEOUT);
        // The child was reaped, so it is no longer there to wait for.
        assert!(child.wait().is_err());
    }

    #[test]
    #[serial]
    fn stops_waiting_at_the_timeout() {
        let short = Duration::from_millis(200);
        let mut child = Command::new("sleep").arg("10").spawn().unwrap();

        let started = Instant::now();
        wait_for_children(short);
        let waited = started.elapsed();

        child.kill().unwrap();
        child.wait().unwrap();
        assert!(waited >= short && waited < TIMEOUT);
    }
}

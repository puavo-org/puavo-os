//! Records TPM event log during boot. Used for generating test data.
//!
//! Prints the event log and the PCR values between two marker lines and then
//! shuts the machine down.

#![no_main]
#![no_std]

extern crate alloc;

use alloc::string::String;
use core::fmt::Write;
use core::ops::{Range, RangeInclusive};

use uefi::proto::tcg::v2::Tcg;
use uefi::runtime::{self, ResetType};
use uefi::{Status, boot, entry, println};

/// Bytes of hex per line, short enough for the console width.
const BYTES_PER_LINE: usize = 32;

/// PCRs to read after the log.
const REGISTERS: RangeInclusive<u32> = 0..=15;

/// Marker lines around the capture, for extraction from the console
/// output.
const BEGIN: &str = "measurements begin";
const COMPLETE: &str = "measurements complete";

// TPM 2.0 Library Specification, Part 2 and Part 3.
const NO_SESSIONS: u16 = 0x8001;
const PCR_READ: u32 = 0x0000_017E;
const SHA256: u16 = 0x000B;
const SUCCESS: u32 = 0x0000_0000;
const SELECTIONS: u32 = 1;
const SELECT_BYTES: usize = 3;
const COMMAND_SIZE: usize = 20;
const RESPONSE_SIZE: usize = 64;
const RESPONSE_CODE: Range<usize> = 6..10;
const RESPONSE_DIGEST: Range<usize> = 30..62;

fn hex(bytes: &[u8]) -> String {
    let mut text = String::with_capacity(bytes.len() * 2);

    for byte in bytes {
        let _ = write!(text, "{byte:02x}");
    }

    text
}

/// Reads the SHA256 value of one PCR, or None when the TPM rejects the
/// command.
fn read_register(tcg: &mut Tcg, register: u32) -> Option<[u8; 32]> {
    // TPM2_PCR_Read, Part 3 section 22.4: the command header, then a
    // TPML_PCR_SELECTION holding one TPMS_PCR_SELECTION that names the SHA256
    // bank and sets the register's bit. The response holds a TPML_DIGEST whose
    // one TPM2B_DIGEST starts at RESPONSE_DIGEST.
    let mut command = [0u8; COMMAND_SIZE];
    command[..2].copy_from_slice(&NO_SESSIONS.to_be_bytes());
    command[2..6].copy_from_slice(&(COMMAND_SIZE as u32).to_be_bytes());
    command[6..10].copy_from_slice(&PCR_READ.to_be_bytes());
    command[10..14].copy_from_slice(&SELECTIONS.to_be_bytes());
    command[14..16].copy_from_slice(&SHA256.to_be_bytes());
    command[16] = SELECT_BYTES as u8;
    command[17 + register as usize / 8] |= 1 << (register % 8);

    let mut response = [0u8; RESPONSE_SIZE];
    tcg.submit_command(&command, &mut response).ok()?;

    let code = u32::from_be_bytes(response[RESPONSE_CODE].try_into().ok()?);
    if code != SUCCESS {
        return None;
    }

    response.get(RESPONSE_DIGEST)?.try_into().ok()
}

/// Prints one block per event in measurement order.
fn print_log(tcg: &mut Tcg) {
    let log = match tcg.get_event_log_v2() {
        Ok(log) => log,
        Err(error) => {
            println!("error: failed to read the event log: {error:?}");
            return;
        }
    };

    for event in log.iter() {
        println!(
            "event pcr {} type {:?}",
            event.pcr_index().0,
            event.event_type()
        );

        for (algorithm, digest) in event.digests() {
            println!("digest {algorithm:?} {}", hex(digest));
        }

        for line in event.event_data().chunks(BYTES_PER_LINE) {
            println!("data {}", hex(line));
        }
    }
}

/// Prints the value of each PCR.
fn print_registers(tcg: &mut Tcg) {
    for register in REGISTERS {
        match read_register(tcg, register) {
            Some(value) => println!("pcr {register} SHA256 {}", hex(&value)),
            None => println!("error: failed to read pcr {register}"),
        }
    }
}

#[entry]
fn main() -> Status {
    if uefi::helpers::init().is_err() {
        return Status::ABORTED;
    }

    let handle = match boot::get_handle_for_protocol::<Tcg>() {
        Ok(handle) => handle,
        Err(error) => {
            println!("error: failed to find a TPM: {error:?}");
            return Status::UNSUPPORTED;
        }
    };

    let mut tcg = match boot::open_protocol_exclusive::<Tcg>(handle) {
        Ok(tcg) => tcg,
        Err(error) => {
            println!("error: failed to open the TPM: {error:?}");
            return Status::UNSUPPORTED;
        }
    };

    println!("{BEGIN}");
    print_log(&mut tcg);
    print_registers(&mut tcg);
    println!("{COMPLETE}");

    runtime::reset(ResetType::SHUTDOWN, Status::SUCCESS, None);
}

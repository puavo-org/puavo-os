//! Minimal TPM 2.0 commands over the EFI TCG2 protocol, enough
//! for the revocation counter. Authorization is empty throughout.
//! No TPM crate is used, they need the standard library or
//! pull the whole TPM2 interface for the few commands we use.
//!
//! Offsets and layouts reference the TPM 2.0 Library Specification, Part 2
//! (Structures) and Part 3 (Commands):
//! <https://trustedcomputinggroup.org/resource/tpm-library-specification/>

use core::mem::size_of;
use uefi::Status;
use uefi::proto::tcg::v2::{HashLogExtendEventFlags, PcrEventInputs, Tcg};
use uefi::proto::tcg::{EventType, PcrIndex};
use zerocopy::byteorder::network_endian::{U16, U32, U64};
use zerocopy::{FromBytes, Immutable, IntoBytes, KnownLayout};

// Part 2, structure tags (TPM_ST): whether a command carries an auth session.
const TPM_ST_SESSIONS: u16 = 0x8002;
const TPM_ST_NO_SESSIONS: u16 = 0x8001;
// Part 2, reserved handles: the password session and the owner hierarchy.
const TPM_RS_PASSWORD: u32 = 0x4000_0009;
const TPM_RH_OWNER: u32 = 0x4000_0001;
// Part 2, response code TPM_RC_SUCCESS.
const TPM_RC_SUCCESS: u32 = 0x0000_0000;

// Part 3, command codes (TPM_CC).
const NV_DEFINE_SPACE: u32 = 0x0000_012A;
const NV_INCREMENT: u32 = 0x0000_0134;
const NV_READ: u32 = 0x0000_014E;
const NV_WRITE: u32 = 0x0000_0137;
const NV_WRITE_LOCK: u32 = 0x0000_0138;
const NV_READ_PUBLIC: u32 = 0x0000_0169;
const PCR_READ: u32 = 0x0000_017E;

// Part 2, counter index attributes (TPMA_NV). COUNTER makes the value only
// ever increase, so the floor cannot be rolled back. WRITE_STCLEAR allows
// locking writes until the next TPM reset, blocking further raises in a boot.
// NO_DA keeps failed access from tripping the dictionary attack lockout.
// AUTHWRITE and AUTHREAD allow access with the empty index authorization.
const COUNTER_ATTRIBUTES: u32 = 0x0204_4014;
// Part 2, base index attributes (TPMA_NV). The base is an ordinary index, not
// a counter, so it can be written once to the counter's start value. Same
// AUTHWRITE, AUTHREAD and NO_DA as the counter.
const BASE_ATTRIBUTES: u32 = 0x0204_0004;

const WRITE_STCLEAR_BIT: u32 = 0x0000_4000;
const NO_DA_BIT: u32 = 0x0200_0000;

// TPM_NT value for a counter, carried in attribute bits four to seven.
const TPM_NT_COUNTER: u32 = 1;

const NV_TYPE_SHIFT: u32 = 4;
const NV_TYPE_MASK: u32 = 0xF;

const NAME_ALGORITHM_SHA256: u16 = 0x000B;

// Both the counter and the base hold an eight byte value.
const NV_DATA_SIZE: u16 = 8;

// PCR that the machine records the images it loads into. Only something that
// decides about images has anything to record there.
#[cfg(feature = "verifier")]
pub const PCR_4: u32 = 4;

// PCR that the disk binds and the base is extended into.
pub const PCR_7: u32 = 7;

// The log data of the base extension event.
const BASE_EVENT_DATA: &[u8] = b"slab-base";

// Length of the TPMS_NV_PUBLIC body: index, name algorithm, attributes,
// empty auth policy, data size.
const PUBLIC_AREA_LENGTH: u16 = 14;

/// Command header shared by every command: tag (TPM_ST), command size, and
/// command code (TPM_CC). Part 1, command processing; field types in Part 2.
#[derive(IntoBytes, Immutable)]
#[repr(C)]
struct Header {
    tag: U16,
    command_size: U32,
    command_code: U32,
}

impl Header {
    fn new(command_code: u32, command_size: usize) -> Self {
        Self {
            tag: U16::new(TPM_ST_SESSIONS),
            command_size: U32::new(command_size as u32),
            command_code: U32::new(command_code),
        }
    }
}

/// Empty password authorization session: a TPMS_AUTH_COMMAND (Part 2) using
/// the password session handle TPM_RS_PW, with no nonce and no HMAC.
#[derive(IntoBytes, Immutable)]
#[repr(C)]
struct PasswordSession {
    authorization_size: U32,
    session_handle: U32,
    nonce_size: U16,
    session_attributes: u8,
    hmac_size: U16,
}

impl PasswordSession {
    fn empty() -> Self {
        Self {
            authorization_size: U32::new(9),
            session_handle: U32::new(TPM_RS_PASSWORD),
            nonce_size: U16::new(0),
            session_attributes: 0,
            hmac_size: U16::new(0),
        }
    }
}

/// TPM2_NV_DefineSpace, authorized by the owner hierarchy (Part 3). The public
/// area is a TPMS_NV_PUBLIC and the attribute bits are TPMA_NV, both in Part 2.
/// The attributes decide whether the index is a counter or an ordinary index.
#[derive(IntoBytes, Immutable)]
#[repr(C)]
struct DefineCommand {
    header: Header,
    owner_handle: U32,
    session: PasswordSession,
    index_auth_size: U16,
    public_size: U16,
    nv_index: U32,
    name_algorithm: U16,
    attributes: U32,
    auth_policy_size: U16,
    data_size: U16,
}

impl DefineCommand {
    fn new(index: u32, attributes: u32) -> Self {
        Self {
            header: Header::new(NV_DEFINE_SPACE, size_of::<Self>()),
            owner_handle: U32::new(TPM_RH_OWNER),
            session: PasswordSession::empty(),
            index_auth_size: U16::new(0),
            public_size: U16::new(PUBLIC_AREA_LENGTH),
            nv_index: U32::new(index),
            name_algorithm: U16::new(NAME_ALGORITHM_SHA256),
            attributes: U32::new(attributes),
            auth_policy_size: U16::new(0),
            data_size: U16::new(NV_DATA_SIZE),
        }
    }
}

/// TPM2_NV_Write of an eight byte value at offset zero (Part 3). Used to set
/// the base to the counter's initial value.
#[derive(IntoBytes, Immutable)]
#[repr(C)]
struct WriteCommand {
    header: Header,
    auth_handle: U32,
    nv_index: U32,
    session: PasswordSession,
    data_size: U16,
    data: [u8; 8],
    offset: U16,
}

impl WriteCommand {
    fn new(index: u32, value: u64) -> Self {
        Self {
            header: Header::new(NV_WRITE, size_of::<Self>()),
            auth_handle: U32::new(index),
            nv_index: U32::new(index),
            session: PasswordSession::empty(),
            data_size: U16::new(NV_DATA_SIZE),
            data: value.to_be_bytes(),
            offset: U16::new(0),
        }
    }
}

/// A command authorized by the index itself with no parameters, used for
/// TPM2_NV_Increment and TPM2_NV_WriteLock (Part 3).
#[derive(IntoBytes, Immutable)]
#[repr(C)]
struct IndexCommand {
    header: Header,
    auth_handle: U32,
    nv_index: U32,
    session: PasswordSession,
}

impl IndexCommand {
    fn new(command_code: u32, index: u32) -> Self {
        Self {
            header: Header::new(command_code, size_of::<Self>()),
            auth_handle: U32::new(index),
            nv_index: U32::new(index),
            session: PasswordSession::empty(),
        }
    }
}

/// TPM2_NV_Read of the eight byte value at offset zero (Part 3), used for both
/// the counter and the base.
#[derive(IntoBytes, Immutable)]
#[repr(C)]
struct ReadCommand {
    header: Header,
    auth_handle: U32,
    nv_index: U32,
    session: PasswordSession,
    read_size: U16,
    offset: U16,
}

impl ReadCommand {
    fn new(index: u32) -> Self {
        Self {
            header: Header::new(NV_READ, size_of::<Self>()),
            auth_handle: U32::new(index),
            nv_index: U32::new(index),
            session: PasswordSession::empty(),
            read_size: U16::new(NV_DATA_SIZE),
            offset: U16::new(0),
        }
    }
}

/// TPM2_NV_ReadPublic. No authorization, so the no-sessions tag (Part 3). The
/// response carries the public area, including the TPMA_NV attribute bits.
#[derive(IntoBytes, Immutable)]
#[repr(C)]
struct ReadPublicCommand {
    tag: U16,
    command_size: U32,
    command_code: U32,
    nv_index: U32,
}

impl ReadPublicCommand {
    fn new(index: u32) -> Self {
        Self {
            tag: U16::new(TPM_ST_NO_SESSIONS),
            command_size: U32::new(size_of::<Self>() as u32),
            command_code: U32::new(NV_READ_PUBLIC),
            nv_index: U32::new(index),
        }
    }
}

/// TPM2_PCR_Read of a single PCR in the SHA256 bank (Part 3). No
/// authorization, so the no-sessions tag. Reads back what extend_base put into
/// PCR 7, for diagnostics and PCR 7 stability checks.
#[derive(IntoBytes, Immutable)]
#[repr(C)]
struct PcrReadCommand {
    tag: U16,
    command_size: U32,
    command_code: U32,
    selection_count: U32,
    hash_algorithm: U16,
    size_of_select: u8,
    pcr_select: [u8; 3],
}

impl PcrReadCommand {
    fn new(pcr: u32) -> Self {
        // The PCR select is a little endian bitmap.
        let mut pcr_select = [0u8; 3];
        pcr_select[(pcr / 8) as usize] = 1 << (pcr % 8);
        Self {
            tag: U16::new(TPM_ST_NO_SESSIONS),
            command_size: U32::new(size_of::<Self>() as u32),
            command_code: U32::new(PCR_READ),
            selection_count: U32::new(1),
            hash_algorithm: U16::new(NAME_ALGORITHM_SHA256),
            size_of_select: 3,
            pcr_select,
        }
    }
}

/// The outcome of a TPM command.
#[derive(Clone, Copy, Debug)]
pub enum CommandError {
    /// The TCG2 call failed with this EFI status.
    Transport(Status),
    /// The TPM rejected the command with this response code.
    Rejected(u32),
    /// The response could not be interpreted.
    MalformedResponse,
}

pub type CommandResult<T> = Result<T, CommandError>;

/// Part 1, the header every response starts with.
#[derive(FromBytes, KnownLayout, Immutable)]
#[repr(C)]
struct ResponseHeader {
    tag: U16,
    response_size: U32,
    response_code: U32,
}

/// TPM2_NV_Read response with one session: the value follows the parameter
/// size and the data size field.
#[derive(FromBytes, KnownLayout, Immutable)]
#[repr(C)]
struct NvReadResponse {
    header: ResponseHeader,
    parameter_size: U32,
    data_size: U16,
    value: U64,
}

/// TPM2_NV_ReadPublic response, up to the attribute bits of the public area.
#[derive(FromBytes, KnownLayout, Immutable)]
#[repr(C)]
struct NvReadPublicResponse {
    header: ResponseHeader,
    public_area_size: U16,
    nv_index: U32,
    name_algorithm: U16,
    attributes: U32,
}

/// TPM2_PCR_Read response for the single SHA256 selection requested.
#[derive(FromBytes, KnownLayout, Immutable)]
#[repr(C)]
struct PcrReadResponse {
    header: ResponseHeader,
    pcr_update_counter: U32,
    selection_count: U32,
    hash_algorithm: U16,
    size_of_select: u8,
    pcr_select: [u8; 3],
    digest_count: U32,
    digest_size: U16,
    digest: [u8; 32],
}

struct Response {
    bytes: [u8; 128],
    length: usize,
}

impl Response {
    fn check(&self) -> CommandResult<()> {
        let header: &ResponseHeader = self.parse()?;
        match header.response_code.get() {
            TPM_RC_SUCCESS => Ok(()),
            code => Err(CommandError::Rejected(code)),
        }
    }

    /// Interprets the response bytes as the given response structure.
    fn parse<T>(&self) -> CommandResult<&T>
    where
        T: FromBytes + KnownLayout + Immutable,
    {
        T::ref_from_prefix(&self.bytes[..self.length])
            .map(|(value, _rest)| value)
            .map_err(|_| CommandError::MalformedResponse)
    }
}

fn submit(tcg: &mut Tcg, command: &[u8]) -> CommandResult<Response> {
    let mut bytes = [0u8; 128];
    tcg.submit_command(command, &mut bytes)
        .map_err(|error| CommandError::Transport(error.status()))?;
    // The response size is the four bytes after the two byte tag.
    let length =
        u32::from_be_bytes([bytes[2], bytes[3], bytes[4], bytes[5]]) as usize;
    if length < size_of::<ResponseHeader>() || length > bytes.len() {
        return Err(CommandError::MalformedResponse);
    }
    Ok(Response { bytes, length })
}

/// Defines the revocation counter.
pub fn define_counter(tcg: &mut Tcg, index: u32) -> CommandResult<()> {
    submit(tcg, DefineCommand::new(index, COUNTER_ATTRIBUTES).as_bytes())?
        .check()
}

/// Defines the base, an ordinary index holding the counter's start value.
pub fn define_base(tcg: &mut Tcg, index: u32) -> CommandResult<()> {
    submit(tcg, DefineCommand::new(index, BASE_ATTRIBUTES).as_bytes())?.check()
}

/// Writes an eight byte value to an index. Used to set the base.
pub fn write_value(tcg: &mut Tcg, index: u32, value: u64) -> CommandResult<()> {
    submit(tcg, WriteCommand::new(index, value).as_bytes())?.check()
}

/// Increments the counter by one.
pub fn increment_counter(tcg: &mut Tcg, index: u32) -> CommandResult<()> {
    submit(tcg, IndexCommand::new(NV_INCREMENT, index).as_bytes())?.check()
}

/// Locks the counter against further writes until the next TPM reset.
pub fn write_lock(tcg: &mut Tcg, index: u32) -> CommandResult<()> {
    submit(tcg, IndexCommand::new(NV_WRITE_LOCK, index).as_bytes())?.check()
}

/// One thing to add to the machine's account of the boot. What the log carries
/// and what the register is extended with are separate, because they are not
/// always the same bytes.
pub struct Extension<'a> {
    pub pcr: u32,
    pub event_type: EventType,
    pub logged: &'a [u8],
    pub hashed: &'a [u8],
    pub flags: HashLogExtendEventFlags,
}

/// Extends the base into PCR 7. This pins the base and records this stage in
/// the sealed state.
pub fn extend_base(tcg: &mut Tcg, base: u64) -> CommandResult<()> {
    extend(
        tcg,
        Extension {
            pcr: PCR_7,
            event_type: EventType::EVENT_TAG,
            logged: BASE_EVENT_DATA,
            hashed: &base.to_be_bytes(),
            flags: HashLogExtendEventFlags::empty(),
        },
    )
}

/// Hashes and logs one addition through the TCG2 protocol, so the event log
/// stays replayable. See the TCG EFI Protocol specification,
/// EFI_TCG2_PROTOCOL.HashLogExtendEvent, for what the flags ask for.
pub fn extend(tcg: &mut Tcg, addition: Extension) -> CommandResult<()> {
    let event = PcrEventInputs::new_in_box(
        PcrIndex(addition.pcr),
        addition.event_type,
        addition.logged,
    )
    .map_err(|_| CommandError::MalformedResponse)?;
    tcg.hash_log_extend_event(addition.flags, addition.hashed, &event)
        .map_err(|error| CommandError::Transport(error.status()))
}

/// Reads the SHA256 bank value of the given PCR.
pub fn read_pcr(tcg: &mut Tcg, pcr: u32) -> CommandResult<[u8; 32]> {
    let response = submit(tcg, PcrReadCommand::new(pcr).as_bytes())?;
    response.check()?;
    let parsed: &PcrReadResponse = response.parse()?;
    // Reject the response unless the TPM returned a full SHA256 digest.
    if parsed.digest_size.get() as usize != parsed.digest.len() {
        return Err(CommandError::MalformedResponse);
    }
    Ok(parsed.digest)
}

/// Reads the eight byte value of an index, used for both the counter and the
/// base.
pub fn read_value(tcg: &mut Tcg, index: u32) -> CommandResult<u64> {
    let response = submit(tcg, ReadCommand::new(index).as_bytes())?;
    response.check()?;
    let parsed: &NvReadResponse = response.parse()?;
    Ok(parsed.value.get())
}

/// Reads the index public area and reports whether it is a counter with the
/// expected attributes. This stops a non-counter index defined at the same
/// handle from being trusted as the floor: only a counter cannot be lowered.
pub fn is_counter(tcg: &mut Tcg, index: u32) -> CommandResult<bool> {
    let response = submit(tcg, ReadPublicCommand::new(index).as_bytes())?;
    response.check()?;
    let parsed: &NvReadPublicResponse = response.parse()?;
    let attributes = parsed.attributes.get();
    let nv_type = (attributes >> NV_TYPE_SHIFT) & NV_TYPE_MASK;
    Ok(nv_type == TPM_NT_COUNTER
        && attributes & WRITE_STCLEAR_BIT != 0
        && attributes & NO_DA_BIT != 0)
}

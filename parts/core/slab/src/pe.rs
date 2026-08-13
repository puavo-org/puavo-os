//! A minimal read-only reader for one named section of a PE image, used to
//! read the next stage component identity. Every access is bounds checked
//! through `get`, so a malformed image yields `None` rather than a panic.
//! PE header fields are little endian.

/// Offset in the DOS header of the pointer to the PE header.
const PE_HEADER_POINTER: usize = 0x3C;
/// Length of the "PE\0\0" signature that starts the PE header.
const PE_SIGNATURE_LENGTH: usize = 4;
/// Section count offset within the COFF file header.
const SECTION_COUNT_OFFSET: usize = 2;
/// Optional header size offset within the COFF file header.
const OPTIONAL_HEADER_SIZE_OFFSET: usize = 16;
/// Size of the COFF file header, after which the optional header begins.
const COFF_HEADER_SIZE: usize = 20;
/// Size of one section table entry.
const SECTION_ENTRY_SIZE: usize = 40;
/// Raw data size offset within a section table entry.
const SECTION_RAW_SIZE_OFFSET: usize = 16;
/// Raw data offset within a section table entry.
const SECTION_RAW_OFFSET_OFFSET: usize = 20;

/// Returns the raw bytes of the named section, or `None` if the section is
/// absent or the image is malformed. The name must be the exact eight byte PE
/// section name.
pub fn read_section<'a>(
    image: &'a [u8],
    section_name: &[u8; 8],
) -> Option<&'a [u8]> {
    // The DOS header points to the PE header, which starts with the signature.
    let pe_offset = read_u32(image, PE_HEADER_POINTER)? as usize;
    let signature_end = pe_offset.checked_add(PE_SIGNATURE_LENGTH)?;
    if image.get(pe_offset..signature_end)? != b"PE\0\0" {
        return None;
    }

    // The COFF header follows the signature, then the optional header, then
    // the section table.
    let coff = pe_offset + PE_SIGNATURE_LENGTH;
    let section_count = read_u16(image, coff + SECTION_COUNT_OFFSET)? as usize;
    let optional_header_size =
        read_u16(image, coff + OPTIONAL_HEADER_SIZE_OFFSET)? as usize;
    let section_table = coff + COFF_HEADER_SIZE + optional_header_size;

    // Walk the section table for a matching name and return its raw bytes.
    for index in 0..section_count {
        let entry = section_table
            .checked_add(index.checked_mul(SECTION_ENTRY_SIZE)?)?;
        let name = image.get(entry..entry.checked_add(section_name.len())?)?;
        if name == section_name {
            let raw_size =
                read_u32(image, entry + SECTION_RAW_SIZE_OFFSET)? as usize;
            let raw_offset =
                read_u32(image, entry + SECTION_RAW_OFFSET_OFFSET)? as usize;
            return image.get(raw_offset..raw_offset.checked_add(raw_size)?);
        }
    }

    None
}

fn read_u16(bytes: &[u8], offset: usize) -> Option<u16> {
    let slice = bytes.get(offset..offset.checked_add(2)?)?;
    Some(u16::from_le_bytes(slice.try_into().ok()?))
}

fn read_u32(bytes: &[u8], offset: usize) -> Option<u32> {
    let slice = bytes.get(offset..offset.checked_add(4)?)?;
    Some(u32::from_le_bytes(slice.try_into().ok()?))
}

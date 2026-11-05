//! Reads little endian fields from the start of a byte slice.

/// Reads fields from the start of the remaining bytes. Each read returns
/// None when too few bytes remain.
pub struct ByteReader<'a>(&'a [u8]);

impl<'a> ByteReader<'a> {
    pub fn new(bytes: &'a [u8]) -> Self {
        Self(bytes)
    }

    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }

    /// Takes the specified number of bytes.
    pub fn take(&mut self, length: usize) -> Option<&'a [u8]> {
        let (taken, remaining) = self.0.split_at_checked(length)?;
        self.0 = remaining;
        Some(taken)
    }

    pub fn read_u16(&mut self) -> Option<u16> {
        Some(u16::from_le_bytes(self.array()?))
    }

    pub fn read_u32(&mut self) -> Option<u32> {
        Some(u32::from_le_bytes(self.array()?))
    }

    /// Takes a size stored as a little endian u32.
    pub fn read_size(&mut self) -> Option<usize> {
        Some(self.read_u32()? as usize)
    }

    fn array<const SIZE: usize>(&mut self) -> Option<[u8; SIZE]> {
        let (array, remaining) = self.0.split_first_chunk::<SIZE>()?;
        self.0 = remaining;
        Some(*array)
    }
}

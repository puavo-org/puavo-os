//! The firmware framebuffer, written with plain file writes.

use std::fs::{self, File, OpenOptions};
use std::io;
use std::os::unix::fs::FileExt;

use slint::platform::software_renderer::PremultipliedRgbaColor;

const FRAMEBUFFER_DEVICE: &str = "/dev/fb0";
const SYSFS_DIRECTORY: &str = "/sys/class/graphics/fb0";
const BYTES_PER_PIXEL: usize = 4;
const SUPPORTED_BITS_PER_PIXEL: usize = 32;

pub struct Framebuffer {
    file: File,
    pub width: usize,
    pub height: usize,
    stride: usize,
    frame: Vec<u8>,
}

fn read_attribute(name: &str) -> io::Result<String> {
    Ok(fs::read_to_string(format!("{SYSFS_DIRECTORY}/{name}"))?
        .trim()
        .to_string())
}

fn invalid_data(message: String) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, message)
}

impl Framebuffer {
    /// Opens the framebuffer the firmware set up, which must hold 32 bits a
    /// pixel in blue, green, red order.
    pub fn open() -> io::Result<Self> {
        let size = read_attribute("virtual_size")?;
        let (width, height) = size
            .split_once(',')
            .and_then(|(width, height)| {
                Some((width.parse().ok()?, height.parse().ok()?))
            })
            .ok_or_else(|| invalid_data(format!("unreadable size {size}")))?;
        let stride: usize = read_attribute("stride")?
            .parse()
            .map_err(|_| invalid_data("unreadable stride".into()))?;
        let bits_per_pixel = read_attribute("bits_per_pixel")?;
        if bits_per_pixel != SUPPORTED_BITS_PER_PIXEL.to_string() {
            return Err(invalid_data(format!("{bits_per_pixel} bits a pixel")));
        }

        let file = OpenOptions::new().write(true).open(FRAMEBUFFER_DEVICE)?;
        let frame = vec![0; stride * height];
        Ok(Framebuffer { file, width, height, stride, frame })
    }

    /// Copies a rendered frame to the screen.
    pub fn show(
        &mut self,
        pixels: &[PremultipliedRgbaColor],
    ) -> io::Result<()> {
        for (row, line) in pixels.chunks(self.width).enumerate() {
            let start = row * self.stride;
            let target =
                &mut self.frame[start..start + self.width * BYTES_PER_PIXEL];
            for (pixel, bytes) in
                line.iter().zip(target.chunks_mut(BYTES_PER_PIXEL))
            {
                bytes.copy_from_slice(&[pixel.blue, pixel.green, pixel.red, 0]);
            }
        }
        self.file.write_all_at(&self.frame, 0)
    }
}

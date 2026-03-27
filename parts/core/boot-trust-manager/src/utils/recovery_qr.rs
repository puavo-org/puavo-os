use std::path::{Path, PathBuf};

use image::Luma;
use log::{info, warn};
use qrcode::QrCode;

use crate::display::plymouth;
use crate::error::PuavoError;
use crate::utils::efi;

/// Render data as a QR code PNG image and save it to
/// the specified path.
pub fn render_qr_code_to_image(
    data: &str,
    output_path: &Path,
) -> Result<(), PuavoError> {
    let code = QrCode::with_error_correction_level(
        data.as_bytes(),
        qrcode::EcLevel::L,
    )
    .map_err(|error| PuavoError::RecoveryQrError(error.to_string()))?;

    let image = code.render::<Luma<u8>>().build();

    image
        .save(output_path)
        .map_err(|error| PuavoError::RecoveryQrError(error.to_string()))
}

/// Read the recovery bundle from the EFI variable and
/// save it as a QR code PNG image to the specified path.
pub fn generate_recovery_qr_code(
    output_path: &Path,
) -> Result<bool, PuavoError> {
    let bundle = match efi::read_recovery_bundle() {
        Some(bundle) => bundle,
        None => {
            warn!("No recovery bundle EFI variable found");
            return Ok(false);
        }
    };

    render_qr_code_to_image(&bundle, output_path)?;
    Ok(true)
}

/// Generate the recovery QR code and display it via
/// Plymouth.
pub fn show_recovery_qr() {
    let temporary_qr_code = PathBuf::from("/run/recovery_qr.png");

    generate_recovery_qr_code(&temporary_qr_code)
        .and_then(|exists| {
            if exists {
                plymouth::show_image(&temporary_qr_code)
            } else {
                info!("No recovery bundle available for QR");
                Ok(())
            }
        })
        .inspect_err(|error| {
            warn!("Failed to generate or show recovery QR code: {}", error)
        })
        .ok();

    let _ = std::fs::remove_file(&temporary_qr_code);
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::utils::efi::{EfiProvider, reset_provider, set_provider};
    use rqrr::PreparedImage;
    use serial_test::serial;

    struct MockEfiProvider {
        recovery_bundle: Option<String>,
    }

    impl EfiProvider for MockEfiProvider {
        fn is_secure_boot_enabled(&self) -> bool {
            false
        }

        fn is_pin_change_requested(&self) -> bool {
            false
        }

        fn clear_pin_change_request(&self) {}

        fn read_recovery_bundle(&self) -> Option<String> {
            self.recovery_bundle.clone()
        }
    }

    /// Decode a QR code from a PNG file on disk.
    fn decode_qr_from_png(path: &Path) -> String {
        let dynamic_image = image::open(path).expect("Failed to open PNG");
        let gray = dynamic_image.to_luma8();
        let mut prepared = PreparedImage::prepare_from_greyscale(
            gray.width() as usize,
            gray.height() as usize,
            |column, row| gray.get_pixel(column as u32, row as u32).0[0],
        );
        let grids = prepared.detect_grids();
        assert_eq!(grids.len(), 1, "Expected one QR code");
        let (_metadata, content) =
            grids[0].decode().expect("Failed to decode QR from PNG");
        content
    }

    #[test]
    #[serial]
    fn save_recovery_qr_code_with_bundle() {
        let bundle = r#"{"serial_number":"TEST001","organisation_id":"test-org","organisation_key_version":1,"encrypted_key_data":"aabbccdd"}"#;
        set_provider(Box::new(MockEfiProvider {
            recovery_bundle: Some(bundle.to_string()),
        }));

        let path = std::env::temp_dir().join("test_save_recovery_qr.png");

        let result = generate_recovery_qr_code(&path).unwrap();
        assert!(result);

        let decoded = decode_qr_from_png(&path);
        assert_eq!(decoded, bundle);

        let _ = std::fs::remove_file(&path);
        reset_provider();
    }

    #[test]
    #[serial]
    fn save_recovery_qr_code_without_bundle() {
        set_provider(Box::new(MockEfiProvider { recovery_bundle: None }));

        let path = std::env::temp_dir().join("test_save_recovery_qr_none.png");
        std::fs::remove_file(&path).ok();

        let result = generate_recovery_qr_code(&path).unwrap();
        assert!(!result);
        assert!(!path.exists());

        reset_provider();
    }
}

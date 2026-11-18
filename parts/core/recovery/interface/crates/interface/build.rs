//! Compiles the interface and embeds its fonts, so that the program needs
//! no font files on the device.

use std::env;

const FONT_DIRECTORY: &str = "/usr/share/fonts/truetype/lato";

fn main() {
    let font_directory = env::var("RECOVERY_FONT_DIRECTORY")
        .unwrap_or_else(|_| FONT_DIRECTORY.to_string());
    println!("cargo:rerun-if-env-changed=RECOVERY_FONT_DIRECTORY");

    let configuration = slint_build::CompilerConfiguration::new()
        .embed_resources(
            slint_build::EmbedResourcesKind::EmbedForSoftwareRenderer,
        )
        .with_include_paths(vec![font_directory.into()]);
    slint_build::compile_with_config("ui/recovery.slint", configuration)
        .expect("failed to compile the interface");
}

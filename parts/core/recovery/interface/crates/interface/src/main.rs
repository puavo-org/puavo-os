//! The recovery interface on the firmware framebuffer. It guides a person
//! through the recovery flow and runs the work the flow asks for.

mod devices;
mod logger;
mod power;
mod presenter;
mod runner;
mod strings;
mod window;

use std::error::Error;

use presenter::Presenter;
use slint::ComponentHandle;
use window::FramebufferWindow;

slint::include_modules!();

fn main() -> Result<(), Box<dyn Error>> {
    logger::start_logging();
    let mut window = FramebufferWindow::open()?;
    let interface = RecoveryWindow::new()
        .map_err(|error| format!("failed to create the window: {error:?}"))?;
    let presenter = Presenter::start().connect(&interface);
    interface
        .show()
        .map_err(|error| format!("failed to show the window: {error:?}"))?;

    window
        .run(&interface, || presenter.borrow_mut().receive_reports(&interface))
}

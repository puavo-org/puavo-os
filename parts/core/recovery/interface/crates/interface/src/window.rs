//! Slint on the firmware framebuffer. Slint's software renderer draws into
//! memory, which is copied to the framebuffer, and Slint gets the keys the
//! console reads and what the pointer does.
//!
//! ```text
//!   console keys, pointer ──> Slint window ──callbacks──> Presenter
//!                                  │                          │
//!   framebuffer <──── render <─────┘           Flow, Runner <─┘
//! ```

use std::error::Error;
use std::rc::Rc;
use std::time::{Duration, Instant};

use slint::platform::software_renderer::{
    MinimalSoftwareWindow, PremultipliedRgbaColor, RepaintBufferType,
};
use slint::platform::{
    Platform, PointerEventButton, WindowAdapter, WindowEvent,
};
use slint::{LogicalPosition, PhysicalSize};

use crate::devices::framebuffer::Framebuffer;
use crate::devices::keyboard::Keyboard;
use crate::devices::pointer::{Pointer, PointerChange};
use crate::RecoveryWindow;

/// How long the loop waits for a key while nothing moves on the screen, and
/// while something does. The wait reads only the keys, so a moving pointer
/// counts as something that moves.
const IDLE_WAIT: Duration = Duration::from_millis(50);
const MOTION_WAIT: Duration = Duration::from_millis(16);

/// Gives Slint the one window, which draws into memory.
struct FramebufferPlatform {
    window: Rc<MinimalSoftwareWindow>,
    start: Instant,
}

impl Platform for FramebufferPlatform {
    fn create_window_adapter(
        &self,
    ) -> Result<Rc<dyn WindowAdapter>, slint::PlatformError> {
        Ok(self.window.clone())
    }

    fn duration_since_start(&self) -> Duration {
        self.start.elapsed()
    }
}

/// The one window of the program, on the whole screen.
pub struct FramebufferWindow {
    framebuffer: Framebuffer,
    keyboard: Keyboard,
    pointer: Pointer,
    window: Rc<MinimalSoftwareWindow>,
    pixels: Vec<PremultipliedRgbaColor>,
}

impl FramebufferWindow {
    /// Opens the devices and makes Slint draw for them. Slint windows are
    /// made after this.
    pub fn open() -> Result<Self, Box<dyn Error>> {
        let framebuffer = Framebuffer::open()?;
        let keyboard = Keyboard::open()?;
        let pointer = Pointer::open(framebuffer.width, framebuffer.height);

        let window =
            MinimalSoftwareWindow::new(RepaintBufferType::ReusedBuffer);
        window.set_size(PhysicalSize::new(
            framebuffer.width as u32,
            framebuffer.height as u32,
        ));
        slint::platform::set_platform(Box::new(FramebufferPlatform {
            window: window.clone(),
            start: Instant::now(),
        }))?;

        let pixels = vec![
            PremultipliedRgbaColor::default();
            framebuffer.width * framebuffer.height
        ];
        Ok(FramebufferWindow { framebuffer, keyboard, pointer, window, pixels })
    }

    /// Draws the interface and hands it the input, for as long as the
    /// program runs. The given function runs on every turn.
    pub fn run(
        &mut self,
        interface: &RecoveryWindow,
        mut tick: impl FnMut(),
    ) -> Result<(), Box<dyn Error>> {
        self.show_pointer(interface);
        loop {
            slint::platform::update_timers_and_animations();
            tick();
            let pointer_moved = self.dispatch_pointer(interface);

            let rendered = self.window.draw_if_needed(|renderer| {
                renderer.render(&mut self.pixels, self.framebuffer.width);
            });
            if rendered {
                self.framebuffer.show(&self.pixels)?;
            }

            let wait = if pointer_moved || self.window.has_active_animations() {
                MOTION_WAIT
            } else {
                IDLE_WAIT
            };
            if let Some(text) = self.keyboard.read(wait)? {
                let window = self.window.window();
                window.dispatch_event(WindowEvent::KeyPressed {
                    text: text.clone(),
                });
                window.dispatch_event(WindowEvent::KeyReleased { text });
            }
        }
    }

    /// Draws the pointer where it is.
    fn show_pointer(&self, interface: &RecoveryWindow) {
        interface.set_pointer_x(self.pointer.horizontal_position);
        interface.set_pointer_y(self.pointer.vertical_position);
    }

    /// Moves the drawn pointer, hands the window what the pointer did, and
    /// tells whether it did anything.
    fn dispatch_pointer(&mut self, interface: &RecoveryWindow) -> bool {
        let changes = self.pointer.read();
        if changes.is_empty() {
            return false;
        }

        self.show_pointer(interface);
        let position = LogicalPosition::new(
            self.pointer.horizontal_position,
            self.pointer.vertical_position,
        );
        let window = self.window.window();
        for change in changes {
            let event = match change {
                PointerChange::Moved => WindowEvent::PointerMoved { position },
                PointerChange::Pressed => WindowEvent::PointerPressed {
                    position,
                    button: PointerEventButton::Left,
                },
                PointerChange::Released => WindowEvent::PointerReleased {
                    position,
                    button: PointerEventButton::Left,
                },
            };
            window.dispatch_event(event);
        }
        true
    }
}

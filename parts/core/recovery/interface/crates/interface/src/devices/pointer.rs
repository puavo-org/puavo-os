//! The mouse or touchpad, read from the kernel input devices.

use std::time::{Duration, SystemTime};

use evdev::{
    AbsoluteAxisCode, Device, EventSummary, KeyCode, PropType, RelativeAxisCode,
};

/// The longest touch, and the farthest the pointer may move during it in
/// pixels, that still counts as a tap.
const TAP_TIME: Duration = Duration::from_millis(200);
const TAP_TRAVEL: f32 = 8.0;

/// What the pointer did since the last read.
pub enum PointerChange {
    Moved,
    Pressed,
    Released,
}

/// How a device reports its position.
enum Motion {
    Relative,
    /// A place on the device is a place on the screen, as on a touch screen
    /// or a tablet. The axis ranges scale it to the screen.
    Absolute {
        horizontal_range: (i32, i32),
        vertical_range: (i32, i32),
    },
    /// A finger moves the pointer by how far it moves.
    Touchpad(Touchpad),
}

/// What a touchpad reported, as its motion needs it.
#[derive(Clone, Copy, Debug)]
enum TouchInput {
    Down,
    Up,
    Horizontal(i32),
    Vertical(i32),
}

/// What a touch did to the pointer.
#[derive(Debug, PartialEq)]
enum TouchResult {
    Nothing,
    Moved { horizontal: f32, vertical: f32 },
    Tapped,
}

/// The finger on a touchpad.
struct Touchpad {
    /// Screen pixels for a unit of the touchpad.
    scale: f32,
    /// The last position of the finger, none until the first one of a touch.
    horizontal: Option<i32>,
    vertical: Option<i32>,
    /// When the finger landed and how far it moved the pointer since.
    landed_at: Option<SystemTime>,
    travel: f32,
}

struct PointingDevice {
    device: Device,
    motion: Motion,
}

pub struct Pointer {
    devices: Vec<PointingDevice>,
    width: f32,
    height: f32,
    pub horizontal_position: f32,
    pub vertical_position: f32,
}

impl Pointer {
    /// Opens every device with a left button that moves on two axes, and
    /// starts the pointer in the middle of the screen.
    pub fn open(width: usize, height: usize) -> Self {
        let devices = evdev::enumerate()
            .filter_map(|(_, device)| pointing_device(device, width as f32))
            .collect();
        Pointer {
            devices,
            width: width as f32,
            height: height as f32,
            horizontal_position: width as f32 / 2.0,
            vertical_position: height as f32 / 2.0,
        }
    }

    /// Reads what the devices reported since the last call, without waiting.
    pub fn read(&mut self) -> Vec<PointerChange> {
        let mut changes = Vec::new();
        let (width, height) = (self.width, self.height);
        for pointing in &mut self.devices {
            let Ok(events) = pointing.device.fetch_events() else {
                continue;
            };
            for event in events {
                let change = match (event.destructure(), &mut pointing.motion) {
                    (
                        EventSummary::RelativeAxis(
                            _,
                            RelativeAxisCode::REL_X,
                            delta,
                        ),
                        Motion::Relative,
                    ) => {
                        self.horizontal_position = (self.horizontal_position
                            + delta as f32)
                            .clamp(0.0, width - 1.0);
                        PointerChange::Moved
                    }
                    (
                        EventSummary::RelativeAxis(
                            _,
                            RelativeAxisCode::REL_Y,
                            delta,
                        ),
                        Motion::Relative,
                    ) => {
                        self.vertical_position = (self.vertical_position
                            + delta as f32)
                            .clamp(0.0, height - 1.0);
                        PointerChange::Moved
                    }
                    (
                        EventSummary::AbsoluteAxis(
                            _,
                            AbsoluteAxisCode::ABS_X,
                            value,
                        ),
                        Motion::Absolute { horizontal_range, .. },
                    ) => {
                        self.horizontal_position =
                            scale_to_screen(value, *horizontal_range, width);
                        PointerChange::Moved
                    }
                    (
                        EventSummary::AbsoluteAxis(
                            _,
                            AbsoluteAxisCode::ABS_Y,
                            value,
                        ),
                        Motion::Absolute { vertical_range, .. },
                    ) => {
                        self.vertical_position =
                            scale_to_screen(value, *vertical_range, height);
                        PointerChange::Moved
                    }
                    (EventSummary::Key(_, KeyCode::BTN_LEFT, 1), _) => {
                        PointerChange::Pressed
                    }
                    (EventSummary::Key(_, KeyCode::BTN_LEFT, 0), _) => {
                        PointerChange::Released
                    }
                    // Touchpad buttons are handled above, as mouse buttons.
                    (summary, Motion::Touchpad(touchpad)) => {
                        let Some(input) = touch_input(&summary) else {
                            continue;
                        };
                        match touchpad.receive(input, event.timestamp()) {
                            TouchResult::Nothing => continue,
                            TouchResult::Moved { horizontal, vertical } => {
                                self.horizontal_position =
                                    (self.horizontal_position + horizontal)
                                        .clamp(0.0, width - 1.0);
                                self.vertical_position =
                                    (self.vertical_position + vertical)
                                        .clamp(0.0, height - 1.0);
                                PointerChange::Moved
                            }
                            TouchResult::Tapped => {
                                changes.push(PointerChange::Pressed);
                                PointerChange::Released
                            }
                        }
                    }
                    _ => continue,
                };
                changes.push(change);
            }
        }
        changes
    }
}

/// The device as a pointing device, if it is one. A touchpad moves the
/// pointer across the width of the screen over its own width.
fn pointing_device(device: Device, width: f32) -> Option<PointingDevice> {
    let has_left_button = device
        .supported_keys()
        .is_some_and(|keys| keys.contains(KeyCode::BTN_LEFT));
    if !has_left_button {
        return None;
    }

    let relative = device.supported_relative_axes().is_some_and(|axes| {
        axes.contains(RelativeAxisCode::REL_X)
            && axes.contains(RelativeAxisCode::REL_Y)
    });
    let motion = if relative {
        Motion::Relative
    } else {
        let mut horizontal_range = None;
        let mut vertical_range = None;
        for (axis, information) in device.get_absinfo().ok()? {
            let range = (information.minimum(), information.maximum());
            match axis {
                AbsoluteAxisCode::ABS_X => horizontal_range = Some(range),
                AbsoluteAxisCode::ABS_Y => vertical_range = Some(range),
                _ => {}
            }
        }
        let horizontal_range = horizontal_range?;
        let vertical_range = vertical_range?;
        // The kernel marks a touchpad as a pointer and a touch screen as
        // direct. A device marked as neither is taken as direct.
        if device.properties().contains(PropType::POINTER) {
            let span = (horizontal_range.1 - horizontal_range.0).max(1);
            Motion::Touchpad(Touchpad::new(width / span as f32))
        } else {
            Motion::Absolute { horizontal_range, vertical_range }
        }
    };

    device.set_nonblocking(true).ok()?;
    Some(PointingDevice { device, motion })
}

/// The input of an event that moves a finger on a touchpad.
fn touch_input(summary: &EventSummary) -> Option<TouchInput> {
    match summary {
        EventSummary::AbsoluteAxis(_, AbsoluteAxisCode::ABS_X, value) => {
            Some(TouchInput::Horizontal(*value))
        }
        EventSummary::AbsoluteAxis(_, AbsoluteAxisCode::ABS_Y, value) => {
            Some(TouchInput::Vertical(*value))
        }
        EventSummary::Key(_, KeyCode::BTN_TOUCH, 1) => Some(TouchInput::Down),
        EventSummary::Key(_, KeyCode::BTN_TOUCH, 0) => Some(TouchInput::Up),
        _ => None,
    }
}

impl Touchpad {
    fn new(scale: f32) -> Self {
        Touchpad {
            scale,
            horizontal: None,
            vertical: None,
            landed_at: None,
            travel: 0.0,
        }
    }

    /// Moves the pointer by the change of the finger position, so a finger
    /// that lands does not move it. A short touch that hardly moved is a tap.
    fn receive(&mut self, input: TouchInput, time: SystemTime) -> TouchResult {
        match input {
            TouchInput::Down => {
                self.lift();
                self.landed_at = Some(time);
                TouchResult::Nothing
            }
            TouchInput::Up => {
                let held = self
                    .landed_at
                    .and_then(|landed_at| time.duration_since(landed_at).ok());
                let tapped = held.is_some_and(|held| held <= TAP_TIME)
                    && self.travel <= TAP_TRAVEL;
                self.lift();
                if tapped {
                    TouchResult::Tapped
                } else {
                    TouchResult::Nothing
                }
            }
            TouchInput::Horizontal(value) => {
                let change =
                    change_of(&mut self.horizontal, value) * self.scale;
                self.moved(change, 0.0)
            }
            TouchInput::Vertical(value) => {
                let change = change_of(&mut self.vertical, value) * self.scale;
                self.moved(0.0, change)
            }
        }
    }

    fn moved(&mut self, horizontal: f32, vertical: f32) -> TouchResult {
        if horizontal == 0.0 && vertical == 0.0 {
            return TouchResult::Nothing;
        }
        self.travel += horizontal.abs() + vertical.abs();
        TouchResult::Moved { horizontal, vertical }
    }

    fn lift(&mut self) {
        self.horizontal = None;
        self.vertical = None;
        self.landed_at = None;
        self.travel = 0.0;
    }
}

/// The change from the last value, which the value then replaces. The first
/// value of a touch has no change.
fn change_of(last: &mut Option<i32>, value: i32) -> f32 {
    let change = last.map_or(0, |last| value - last);
    *last = Some(value);
    change as f32
}

/// Scales an absolute axis value to a screen coordinate.
fn scale_to_screen(
    value: i32,
    (minimum, maximum): (i32, i32),
    extent: f32,
) -> f32 {
    let span = (maximum - minimum).max(1) as f32;
    ((value - minimum) as f32 / span * extent).clamp(0.0, extent - 1.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    const SCALE: f32 = 0.5;

    fn at(milliseconds: u64) -> SystemTime {
        SystemTime::UNIX_EPOCH + Duration::from_millis(milliseconds)
    }

    /// A finger that landed at a place at the start.
    fn touching(horizontal: i32, vertical: i32) -> Touchpad {
        let mut touchpad = Touchpad::new(SCALE);
        touchpad.receive(TouchInput::Down, at(0));
        touchpad.receive(TouchInput::Horizontal(horizontal), at(0));
        touchpad.receive(TouchInput::Vertical(vertical), at(0));
        touchpad
    }

    #[test]
    fn a_finger_that_lands_does_not_move_the_pointer() {
        let mut touchpad = Touchpad::new(SCALE);
        let landing = [
            TouchInput::Down,
            TouchInput::Horizontal(500),
            TouchInput::Vertical(300),
        ];
        for input in landing {
            let result = touchpad.receive(input, at(0));
            assert_eq!(result, TouchResult::Nothing);
        }
    }

    #[test]
    fn a_moving_finger_moves_the_pointer_by_its_change() {
        let mut touchpad = touching(500, 300);
        assert_eq!(
            touchpad.receive(TouchInput::Horizontal(520), at(300)),
            TouchResult::Moved { horizontal: 10.0, vertical: 0.0 }
        );
        assert_eq!(
            touchpad.receive(TouchInput::Vertical(290), at(310)),
            TouchResult::Moved { horizontal: 0.0, vertical: -5.0 }
        );
    }

    #[test]
    fn a_finger_lifted_and_landed_elsewhere_does_not_jump() {
        let mut touchpad = touching(500, 300);
        touchpad.receive(TouchInput::Up, at(400));
        touchpad.receive(TouchInput::Down, at(500));
        let result = touchpad.receive(TouchInput::Horizontal(100), at(500));
        assert_eq!(result, TouchResult::Nothing);
        let result = touchpad.receive(TouchInput::Horizontal(110), at(510));
        assert_eq!(
            result,
            TouchResult::Moved { horizontal: 5.0, vertical: 0.0 }
        );
    }

    #[test]
    fn a_short_touch_that_hardly_moved_is_a_tap() {
        let mut touchpad = touching(500, 300);
        touchpad.receive(TouchInput::Horizontal(502), at(50));
        let result = touchpad.receive(TouchInput::Up, at(150));
        assert_eq!(result, TouchResult::Tapped);
    }

    #[test]
    fn a_long_or_moving_touch_is_no_tap() {
        let mut touchpad = touching(500, 300);
        let result = touchpad.receive(TouchInput::Up, at(500));
        assert_eq!(result, TouchResult::Nothing);

        let mut touchpad = touching(500, 300);
        touchpad.receive(TouchInput::Horizontal(600), at(50));
        let result = touchpad.receive(TouchInput::Up, at(100));
        assert_eq!(result, TouchResult::Nothing);
    }
}

//! Shows the recovery flow in the window and turns what the person chose
//! there into flow input.

mod screen;
// A tool of this part, which draws every view without a device.
#[cfg(test)]
#[path = "../../../../tools/draw-views.rs"]
mod views;

use std::cell::RefCell;
use std::rc::Rc;

use log::debug;
use recovery_flow::{Effect, Flow, Report};
use recovery_services::network::Passphrase;
use recovery_services::recovery_service::DEVELOPMENT;
use recovery_services::support::support_addresses;
use slint::{ComponentHandle, ModelRc, VecModel};

use crate::power;
use crate::runner::Runner;
use crate::strings::{Language, Strings};
use crate::RecoveryWindow;
use screen::{Choice, Content, Screen};

/// Whether this build has a root shell beside the interface. The title
/// marks such a build.
const DEBUG: bool = cfg!(feature = "debug");

pub struct Presenter {
    flow: Flow,
    runner: Runner,
    strings: &'static Strings,
}

impl Presenter {
    /// Starts the flow and the work its start asks for. The texts are in
    /// English until the EFI partition of the device tells its language.
    pub fn start() -> Self {
        let strings = Strings::for_language(Language::English);
        let runner = Runner::new();
        let mut flow = Flow::new();
        runner.run_effect(flow.start());
        Presenter { flow, runner, strings }
    }

    /// Shows the flow in the window and acts on its callbacks. The returned
    /// presenter is shared with them.
    pub fn connect(self, window: &RecoveryWindow) -> Rc<RefCell<Presenter>> {
        label_window(window, self.strings, &support_addresses());
        self.present_view(window);
        let shared = Rc::new(RefCell::new(self));

        window.on_activate(window_callback(
            window,
            &shared,
            |presenter, window, index| {
                presenter.activate_choice(window, index as usize);
            },
        ));
        let back = window_callback(window, &shared, |presenter, window, ()| {
            let effect = presenter.flow.go_back_from_view();
            presenter.apply_effect(window, effect);
        });
        window.on_back(move || back(()));
        let rescan =
            window_callback(window, &shared, |presenter, window, ()| {
                let effect = presenter.flow.rescan();
                presenter.apply_effect(window, effect);
            });
        window.on_rescan(move || rescan(()));
        window.on_submit_passphrase(window_callback(
            window,
            &shared,
            |presenter, window, passphrase: slint::SharedString| {
                let passphrase = Passphrase::new(passphrase.into());
                let effect = presenter.flow.submit_passphrase(passphrase);
                presenter.apply_effect(window, effect);
            },
        ));
        window.on_submit_code(window_callback(
            window,
            &shared,
            |presenter, window, code: slint::SharedString| {
                let effect = presenter.flow.submit_code(&code);
                presenter.apply_effect(window, effect);
            },
        ));
        shared
    }

    /// Moves the flow on with what the services reported.
    pub fn receive_reports(&mut self, window: &RecoveryWindow) {
        let mut changed = false;
        while let Some(report) = self.runner.next_report() {
            if let Report::SavedRequestChecked { locale, .. } = &report {
                self.use_language_of(window, locale.as_deref());
            }
            if let Some(effect) = self.flow.receive_report(report) {
                self.runner.run_effect(effect);
            }
            changed = true;
        }
        if changed {
            self.present_view(window);
        }
    }

    /// Shows the texts in the language of the locale the device was
    /// installed with, as the boot trust manager does.
    fn use_language_of(
        &mut self,
        window: &RecoveryWindow,
        locale: Option<&str>,
    ) {
        debug!("the locale of the device is {locale:?}");
        let language = Language::from_locale(locale.unwrap_or_default());
        self.strings = Strings::for_language(language);
        label_window(window, self.strings, &support_addresses());
    }

    /// Runs the effect of what the person did and shows the flow again.
    fn apply_effect(
        &mut self,
        window: &RecoveryWindow,
        effect: Option<Effect>,
    ) {
        if let Some(effect) = effect {
            self.runner.run_effect(effect);
        }
        self.present_view(window);
    }

    /// Acts on the item the person chose with Enter or the pointer.
    fn activate_choice(&mut self, window: &RecoveryWindow, index: usize) {
        let Some(choice) = screen::choice_at(self.flow.view(), index) else {
            return;
        };
        let effect = match choice {
            Choice::Problem(problem) => {
                self.flow.choose_problem(problem);
                None
            }
            Choice::Proceed => self.flow.proceed_from_view(),
            Choice::Back => self.flow.go_back_from_view(),
            Choice::ChangeNetwork => self.flow.change_network(),
            Choice::Partition(index) => self.flow.choose_partition(index),
            Choice::Network(index) => self.flow.select_network(index),
            Choice::Action(action) => self.flow.take_action(action),
            Choice::Restart => return power::restart(),
            Choice::OpenFirmwareSetup => return power::open_firmware_setup(),
            Choice::PowerOff => return power::power_off(),
        };
        self.apply_effect(window, effect);
    }

    fn present_view(&self, window: &RecoveryWindow) {
        let screen = screen::screen_of_view(
            self.flow.view(),
            self.flow.progress(),
            self.strings,
        );
        show_screen(window, screen);
    }
}

/// Shows a screen in the window.
fn show_screen(window: &RecoveryWindow, screen: Screen) {
    match screen.content {
        Content::None => {}
        Content::Choices(items) => window.set_choices(list_model(items)),
        Content::Phases(items) => window.set_phases(list_model(items)),
        Content::Networks(items) => window.set_networks(list_model(items)),
        Content::CodeEntry { serial_number, refusal } => {
            window.set_serial_number(serial_number.into());
            window.set_code_refusal(refusal.into());
        }
        Content::Status(status) => window.set_status(status.into()),
    }

    if window.get_view() != screen.kind {
        window.set_selected(0);
        window.set_passphrase_shown(false);
    }
    window.set_view(screen.kind);
    window.set_heading(screen.heading.into());
    window.set_hint(screen.hint.into());
    window.set_choice_count(screen.choice_count as i32);
}

/// Sets the texts that do not change with the view.
fn label_window(
    window: &RecoveryWindow,
    strings: &Strings,
    support_addresses: &[String],
) {
    let mut title = strings.title.to_string();
    for (shown, mark) in
        [(DEVELOPMENT, strings.development_mark), (DEBUG, strings.debug_mark)]
    {
        if shown {
            title = format!("{title} ({mark})");
        }
    }
    window.set_app_title(title.into());
    window.set_continue_label(strings.continue_button.into());
    window.set_back_label(strings.back_button.into());
    window.set_restart_label(strings.restart_button.into());
    window.set_power_off_label(strings.power_off_button.into());
    window.set_firmware_label(strings.firmware_settings_button.into());
    window.set_change_network_label(strings.change_network_button.into());
    window.set_note(strings.may_turn_off.into());
    window.set_serial_label(strings.serial_number.into());
    window.set_code_keys(strings.code_keys.into());

    if !support_addresses.is_empty() {
        let support =
            format!("{} {}", strings.support_hint, support_addresses.join(" "));
        window.set_support(support.into());
    }
}

/// A window callback that runs an action on the shared presenter, while
/// the window is there.
fn window_callback<A>(
    window: &RecoveryWindow,
    presenter: &Rc<RefCell<Presenter>>,
    action: impl Fn(&mut Presenter, &RecoveryWindow, A),
) -> impl Fn(A) {
    let weak = window.as_weak();
    let presenter = Rc::clone(presenter);
    move |argument| {
        if let Some(window) = weak.upgrade() {
            action(&mut presenter.borrow_mut(), &window, argument);
        }
    }
}

fn list_model<T: Clone + 'static>(items: Vec<T>) -> ModelRc<T> {
    ModelRc::new(VecModel::from(items))
}

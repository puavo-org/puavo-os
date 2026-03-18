import St from 'gi://St';
import Meta from 'gi://Meta';
import Gio from 'gi://Gio';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

let ExtensionName;
let settings, extSettings;
let settingsSignal;
let panelButton;
let storedWindows = [];
let isHotkeySet = false;


function toggleDesktop() {
	let workspace = global.workspace_manager.get_active_workspace();
	let windows = workspace.list_windows();

	let tmpStoredWindows = [];
	// Try to minimize all windows
	for (let i = 0; i < windows.length; ++i) {
		if (!shouldBeIgnored(windows[i])) {
			windows[i].minimize();
			tmpStoredWindows.push(windows[i])
		}
	}

	if (tmpStoredWindows.length > 0) {
		storedWindows = tmpStoredWindows;
	} else {
		// If nothing were minimized (desktop is alredy shown)
		// try to restore previously minimized
		let topWindow;
		let stackedWindows = global.display.sort_windows_by_stacking(storedWindows);

		for (let i = 0; i < stackedWindows.length; i++) {
			if (stackedWindows[i] && stackedWindows[i].located_on_workspace(workspace)) {
				stackedWindows[i].unminimize();
				topWindow = stackedWindows[i];
			}
		}

		if (topWindow)
			topWindow.activate(global.get_current_time());

		storedWindows = [];
	}

	if (Main.overview.visible) {
		Main.overview.hide();
	}
}


function shouldBeIgnored(window) {
	if (!window)
		return true;

	if (window.minimized ||
		window.skip_taskbar ||
		window.window_type == Meta.WindowType.DESKTOP ||
		window.window_type == Meta.WindowType.DOCK) {

		return true;
	}

	return false;
}


function createPanelButton() {
	panelButton = new PanelMenu.Button(0.0, `${ExtensionName}`, false);

	let icon = new St.Icon({
		icon_name: 'computer-symbolic',
		style_class: 'system-status-icon',
	});

	panelButton.add_child(icon);

	panelButton.connect('button-press-event', toggleDesktop);

	panelButton.connect_after('key-release-event', (actor, event) => {
		let symbol = event.get_key_symbol();
		if (symbol == Clutter.KEY_Return || symbol == Clutter.KEY_space) {
			toggleDesktop();
		}
		return Clutter.EVENT_PROPAGATE;
	});
}


function addButton() {
	let role = `${ExtensionName} Indicator`;
	let index = settings.get_enum('button-position');
	let positions = ['left', 'left', 'center', 'right', 'right'];
	let modifiers = [0, 1, 0, 1, -1];

	createPanelButton();
	if (index == 0 || index == 4)
		panelButton.style = '-natural-hpadding:4px;-minimum-hpadding:4px;'

	Main.panel.addToStatusArea(role, panelButton, modifiers[index], positions[index]);
}


function removeButton() {
	if (panelButton)
		panelButton.destroy();

	panelButton = null;
}


function onEnable() {
	addButton();

	let mode = Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW | Shell.ActionMode.POPUP;
	let flag = Meta.KeyBindingFlags.IGNORE_AUTOREPEAT;

	if (settings.get_boolean('enable-hotkey')) {
		extSettings.set_strv('show-desktop', []);
		Main.wm.addKeybinding('show-desktop-hotkey', settings, flag, mode, toggleDesktop);
		isHotkeySet = true;
	}
}


function onDisable() {
	if (isHotkeySet) {
		Main.wm.removeKeybinding('show-desktop-hotkey');
		extSettings.reset('show-desktop');
		isHotkeySet = false;
	}
	removeButton();
}


export default class extends Extension {
	enable() {
		ExtensionName = this.metadata.name;
		settings = this.getSettings();
		extSettings = new Gio.Settings({ schema: 'org.gnome.desktop.wm.keybindings' });
		storedWindows = [];
		onEnable();

		settingsSignal = settings.connect('changed', (s) => {
			onDisable();
			onEnable();
		});
	}

	disable() {
		settings.disconnect(settingsSignal);
		onDisable();

		storedWindows = null;
		settings = null;
		extSettings = null;
	}
}

import Gtk from 'gi://Gtk';
import { ExtensionPreferences } from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';


export default class extends ExtensionPreferences {

	fillPreferencesWindow(window) {
		const Settings = this.getSettings();

		let builder = new Gtk.Builder();
		builder.set_translation_domain(this.metadata['gettext-domain']);
		builder.add_from_file(this.dir.get_child('prefs.ui').get_path());

		let currentPosition = Settings.get_enum('button-position');
		let isHotkeyEnabled = Settings.get_boolean('enable-hotkey');

		let comboBox = builder.get_object('panelButtonPosition_combobox');
		let enableSwitch = builder.get_object('useHotkey_switch');

		comboBox.set_active(currentPosition);
		enableSwitch.set_active(isHotkeyEnabled);

		comboBox.connect('changed', (w) => {
			let value = w.get_active();
			Settings.set_enum('button-position', value);
		});

		enableSwitch.connect('state-set', (w) => {
			let value = w.get_active();
			Settings.set_boolean('enable-hotkey', value);
		});

		window.add(builder.get_object('main_prefs'));
	}

}

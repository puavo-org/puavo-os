/*
Audio Menu Modifier GNOME shell extension
Version 1.0
(c) Opinsys Oy 2017, 2021
(c) Andres Cidoncha and others 2013-2021
(c) Andreas Fuchs 2013-2014

This shell extension is based on "Audio-Output-Switcher" by Andres Cidoncha.
Originally we only intended on adding one menu entry to it (sound settings),
but in the end, we ended up translating it and fixing a few little things
along the way. Our earlier development was rebased on a recent upstream version
in December 2021.

The original extension is available at https://github.com/AndresCidoncha/audio-switcher
and it is released under the GNU GPL3 license, so this extension falls under
the same license:

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

Of course, this is heavily customized for our Puavo system, but who knows,
maybe it might be useful for others too...
*/
const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;
const GObject = imports.gi.GObject;
const GLib = imports.gi.GLib;
const St = imports.gi.St;
const Util = imports.misc.util;
const Clutter = imports.gi.Clutter;

// we *did* try using gettext and the translation system, but... it just
// was too complex and heavy-weight for this little extension
const messages = {
	"OTHER": {
		"en": "Other",
		"fi": "Muu",
		"sv": "Andra",
		"de": "Andere",
		"fr": "Autre",
	},

	"NO_MORE_DEVICES": {
		"en": "No more devices",
		"fi": "Ei enempää laitteita",
		"sv": "Inga fler enheter",
		"de": "Keine Geräte mehr",
		"fr": "Plus d'appareils",
	},

	// see /puavo-os/debs/gnome-shell/po and grep for "Sound Settings"
	// and see the next line below the matches
	"SOUND_SETTINGS": {
		"en": "Sound settings...",
		"fi": "Ääniasetukset...",
		"sv": "Ljudinställningar...",
		"de": "Klangeinstellungen...",
		"fr": "Paramètres de son...",
	},
};

// the default language
var langID = "en";

function getText(id)
{
	if (id in messages && langID in messages[id])
		return messages[id][langID];

	return "<Missing translation>";
}

const AudioOutputSubMenu = GObject.registerClass({
    GTypeName: 'ASAudioOutputSubMenu',
}, class AudioOutputSubMenu extends PopupMenu.PopupSubMenuMenuItem {
    _init() {
		super._init('Audio Output: Connecting...', true);

		this._control = Main.panel.statusArea.aggregateMenu._volume._control;

		this._controlSignal = this._control.connect('default-sink-changed', () => {
			this._updateDefaultSink();
		});

		this._updateDefaultSink();

		this.menu.connect('open-state-changed', (menu, isOpen) => {
			if (isOpen)
				this._updateSinkList();
		});

		//Unless there is at least one item here, no 'open' will be emitted...
		let item = new PopupMenu.PopupMenuItem('Connecting...');
		this.menu.addMenuItem(item);
	}

	_updateDefaultSink() {
		let defsink = this._control.get_default_sink();
		//Unfortunately, Gvc neglects some pulse-devices, such as all "Monitor of ..."
		if (defsink == null)
			this.label.set_text(getText("OTHER"));
		else
			this.label.set_text(defsink.get_description());
	}

	_updateSinkList() {
		this.menu.removeAll();

		let defsink = this._control.get_default_sink();
		let sinklist = this._control.get_sinks();
		let control = this._control;
		let item;

		for (let i=0; i<sinklist.length; i++) {
			let sink = sinklist[i];
			if (sink === defsink)
				continue;
			item = new PopupMenu.PopupMenuItem(sink.get_description());
			item.connect('activate', () => {
				control.set_default_sink(sink);
			});
			this.menu.addMenuItem(item);
		}
		if (sinklist.length == 0 ||
			(sinklist.length == 1 && sinklist[0] === defsink)) {
			item = new PopupMenu.PopupMenuItem(getText("NO_MORE_DEVICES"));
			this.menu.addMenuItem(item);
		}
	}

	destroy() {
		this._control.disconnect(this._controlSignal);
		super.destroy();
	}
});

const AudioInputSubMenu = GObject.registerClass({
    GTypeName: 'ASAudioInputSubMenu',
}, class AudioInputSubMenu extends PopupMenu.PopupSubMenuMenuItem {
    _init() {
		super._init('Audio Input: Connecting...', true);

		this._control = Main.panel.statusArea.aggregateMenu._volume._control;


		this._controlSignal = this._control.connect('default-source-changed', () => {
			this._updateDefaultSource();
		});

		this._updateDefaultSource();

		this.menu.connect('open-state-changed', (menu, isOpen) => {
			if (isOpen)
				this._updateSourceList();
		});

		//Unless there is at least one item here, no 'open' will be emitted...
		let item = new PopupMenu.PopupMenuItem('Connecting...');
		this.menu.addMenuItem(item);
	}

	_updateDefaultSource() {
		let defsource = this._control.get_default_source();
		//Unfortunately, Gvc neglects some pulse-devices, such as all "Monitor of ..."
		if (defsource == null)
			this.label.set_text(getText("OTHER"));
		else
			this.label.set_text(defsource.get_description());
	}

	_updateSourceList() {
		this.menu.removeAll();

		let defsource = this._control.get_default_source();
		let sourcelist = this._control.get_sources();
		let control = this._control;
		let item;

		for (var i = 0; i < sourcelist.length; i++) {
			let source = sourcelist[i];
			if (source === defsource) {
				continue;
			}
			item = new PopupMenu.PopupMenuItem(source.get_description());
			item.connect('activate', () => {
				control.set_default_source(source);
			});
			this.menu.addMenuItem(item);
		}
		if (sourcelist.length == 0 ||
			(sourcelist.length == 1 && sourcelist[0] === defsource)) {
			item = new PopupMenu.PopupMenuItem(getText("NO_MORE_DEVICES"));
			this.menu.addMenuItem(item);
		}
	}

	destroy() {
		this._control.disconnect(this._controlSignal);
		super.destroy();
	}
});

var audioOutputSubMenu = null;
var audioInputSubMenu = null;
var savedUpdateVisibility = null;
var openAudioSettingsMenuItem = null;
var fakeSeparatorMenuItem = null;

function init() {
	const language = GLib.getenv("LANG");

	//log("INIT(): LANGUAGE='" + language + "'");

	if (language == "C" || language == "C.UTF-8")
		langID = "en";
	else if (language.length >= 2)
		langID = language.substring(0, 2);
	else {
		log("audio-switcher-mod@AndresCidoncha: unknown language '" + language + "', defaulting to 'en'");
		langID = "en";
	}

	//log("INIT(): LANGID='" + langID + "'");
}

function enable() {
	if ((audioInputSubMenu != null) || (audioOutputSubMenu != null))
		return;
	audioInputSubMenu = new AudioInputSubMenu();
	audioOutputSubMenu = new AudioOutputSubMenu();

	//Try to add the switchers right below the sliders...
	let volMen = Main.panel.statusArea.aggregateMenu._volume._volumeMenu;
	let items = volMen._getMenuItems();
	let i = 0;
	let inputPos = 0;
	let addedInput, addedOutput = false;
	while (i < items.length){
		if (items[i] === volMen._output.item){
			volMen.addMenuItem(audioOutputSubMenu, i+1);
			addedOutput = true;
		} else if (items[i] === volMen._input.item){
			volMen.addMenuItem(audioInputSubMenu, i+2);
			addedInput = true;
			inputPos = i+2;
		}
		if (addedOutput && addedInput){
			break;
		}
		i++;
	}

	// Add a new menu entry (icon+text) for opening the Gnome sound settings window
	openAudioSettingsMenuItem = new PopupMenu.PopupBaseMenuItem();

	openAudioSettingsMenuItem.actor.add_child(new St.Icon({
		style_class: "popup-menu-icon",
		icon_name: "audio-speakers-symbolic"
	}));

	openAudioSettingsMenuItem.actor.add_child(new St.Label({
		text: getText("SOUND_SETTINGS")
	}));

	openAudioSettingsMenuItem.connect("activate", () => {
		Util.spawn(["gnome-control-center", "sound"]);
	});

	volMen.addMenuItem(openAudioSettingsMenuItem, inputPos + 1);

	// Add a "fake" (it looks and feels like a real thing) separator line
	// below it. Can't use PopupMenu.PopupSeparatorMenuItem here, because
	// addMenuItem() contains some weird extra logic for handling separators
	// and that extra weird logic actually ends up hiding the separator!
	fakeSeparatorMenuItem = new PopupMenu.PopupBaseMenuItem({
		reactive: false,
		can_focus: false
	});

	fakeSeparatorMenuItem.actor.add_child(new St.Widget({
		style_class: "popup-separator-menu-item",
		y_expand: false,
		y_align: Clutter.ActorAlign.CENTER
		}));

	volMen.addMenuItem(fakeSeparatorMenuItem, inputPos + 2);

	//Make input-slider allways visible.
	savedUpdateVisibility = Main.panel.statusArea.aggregateMenu._volume._volumeMenu._input._updateVisibility;
	Main.panel.statusArea.aggregateMenu._volume._volumeMenu._input._updateVisibility = function () {};
	Main.panel.statusArea.aggregateMenu._volume._volumeMenu._input.item.actor.visible = true;

	// Make the aggregate menu wider to prevent an unfortunate text ellipsis.
	// We do this here, because those "unfortunate" labels are added here.
	Main.panel.statusArea.aggregateMenu.menu.box.set_width(350);
}

function disable() {
	audioInputSubMenu.destroy();
	audioInputSubMenu = null;
	audioOutputSubMenu.destroy();
	audioOutputSubMenu = null;
	openAudioSettingsMenuItem.destroy();
	openAudioSettingsMenuItem = null;
	fakeSeparatorMenuItem.destroy();
	fakeSeparatorMenuItem = null;

	Main.panel.statusArea.aggregateMenu._volume._volumeMenu._input._updateVisibility = savedUpdateVisibility;
	savedUpdateVisibility = null;
	Main.panel.statusArea.aggregateMenu._volume._volumeMenu._input._updateVisibility();
}

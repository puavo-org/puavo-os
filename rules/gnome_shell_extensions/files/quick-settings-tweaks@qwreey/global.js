import GLib from "gi://GLib";
import Gio from "gi://Gio";
import * as Main from "resource:///org/gnome/shell/ui/main.js";
import Logger from "./libs/shared/logger.js";
export default class Global {
    static get QuickSettingsSystemIndicator() {
        return new Promise(resolve => {
            let system = this.QuickSettings._system;
            if (system) {
                resolve(system);
                return;
            }
            GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                system = this.QuickSettings._system;
                if (!system)
                    return GLib.SOURCE_CONTINUE;
                resolve(system);
                return GLib.SOURCE_REMOVE;
            });
        });
    }
    static get QuickSettingsSystemItem() {
        return this.QuickSettingsSystemIndicator
            .then(system => system._systemItem)
            .catch(Logger.error);
    }
    static get MessageList() {
        return this.DateMenu._messageList;
    }
    static get DateMenuIndicator() {
        return this.DateMenu._indicator;
    }
    static GetShutdownMenuBox() {
        // To prevent freeze, priority should be PRIORITY_DEFAULT_IDLE instead of PRIORITY_DEFAULT
        return new Promise(resolve => {
            GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                if (!this.QuickSettings._system)
                    return GLib.SOURCE_CONTINUE;
                resolve(this.QuickSettings._system._systemItem.menu.box);
                return GLib.SOURCE_REMOVE;
            });
        });
    }
    static StreamSliderGetter() {
        if (!this.QuickSettings._volumeInput)
            return null;
        return {
            VolumeInput: this.QuickSettings._volumeInput,
            InputStreamSlider: this.QuickSettings._volumeInput._input,
            OutputStreamSlider: this.QuickSettings._volumeOutput._output,
        };
    }
    static GetStreamSlider() {
        return new Promise(resolve => {
            let streamSlider = this.StreamSliderGetter();
            if (streamSlider) {
                resolve(streamSlider);
                return;
            }
            GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                streamSlider = this.StreamSliderGetter();
                if (!streamSlider)
                    return GLib.SOURCE_CONTINUE;
                resolve(streamSlider);
                return GLib.SOURCE_REMOVE;
            });
        });
    }
    static GetDbusInterface(path, interfaceName) {
        let cachedInfo = this.DBusFiles.get(path);
        if (!cachedInfo) {
            const DbusFile = Gio.File.new_for_path(`${this.Extension.path}/${path}`);
            cachedInfo = Gio.DBusNodeInfo.new_for_xml(this.Decoder.decode(DbusFile.load_contents(null)[1]));
            this.DBusFiles.set(path, cachedInfo);
        }
        return cachedInfo.lookup_interface(interfaceName);
    }
    static GetShader(path) {
        let cachedInfo = this.Shaders.get(path);
        if (!cachedInfo) {
            const shaderFile = Gio.File.new_for_path(`${this.Extension.path}/${path}`);
            const [declarations, main] = this.Decoder.decode(shaderFile.load_contents(null)[1]).split(/^.*?main\(\s?\)\s?/m);
            cachedInfo = [
                declarations.trim(),
                main.trim().replace(/^[{}]/gm, '').trim()
            ];
            this.Shaders.set(path, cachedInfo);
        }
        return cachedInfo;
    }
    static unload() {
        this.QuickSettings = null;
        this.QuickSettingsMenu = null;
        this.QuickSettingsGrid = null;
        this.QuickSettingsBox = null;
        this.QuickSettingsActor = null;
        this.Indicators = null;
        this.DateMenu = null;
        this.DateMenuMenu = null;
        this.DateMenuBox = null;
        this.DateMenuHolder = null;
        this.MessageTray = null;
        this.Extension = null;
        this.Settings = null;
        this.DBusFiles = null;
        this.Shaders = null;
        this.Decoder = null;
    }
    static load(extension) {
        this.Extension = extension;
        this.Settings = extension.getSettings();
        this.Shaders = new Map();
        this.DBusFiles = new Map();
        this.Decoder = new TextDecoder("utf-8");
        // Quick Settings Items
        const QuickSettings = this.QuickSettings = Main.panel.statusArea.quickSettings;
        this.QuickSettingsMenu = QuickSettings.menu;
        this.QuickSettingsGrid = QuickSettings.menu._grid;
        this.QuickSettingsBox = QuickSettings.menu.box;
        this.QuickSettingsActor = QuickSettings.menu.actor;
        this.Indicators = QuickSettings._indicators;
        // Date Menu
        const DateMenu = this.DateMenu = Main.panel.statusArea.dateMenu;
        const DateMenuMenu = this.DateMenuMenu = DateMenu.menu;
        this.DateMenuBox = DateMenuMenu.box;
        this.DateMenuHolder = DateMenuMenu.box.first_child.first_child;
        // Message
        this.MessageTray = Main.messageTray;
    }
}

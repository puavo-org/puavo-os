import Maid from "../shared/maid.js";
import Global from "../../global.js";
import Logger from "../shared/logger.js";
export class SettingLoader {
    constructor(onChange, parent) {
        this.parent = parent;
        this.records = new Set();
        this.listeners = [];
        this.onChange = onChange;
    }
    push(key) {
        if (this.records.has(key))
            return;
        this.records.add(key);
        this.listeners.push(Global.Settings.connect(`changed::${key}`, () => this.onChange(key)));
        if (!this.parent.disableDebugMessage)
            Logger.debug(() => `Setting listener for key '${key}' added for feature ${this.parent.constructor.name}`);
    }
    clear() {
        for (const source of this.listeners) {
            Global.Settings.disconnect(source);
        }
        this.listeners = [];
        this.records.clear();
        if (!this.parent.disableDebugMessage) {
            Logger.debug(() => `Disconnected setting listeners for feature ${this.parent.constructor.name}`);
        }
    }
    loadBoolean(key) {
        this.push(key);
        return Global.Settings.get_boolean(key);
    }
    loadString(key) {
        this.push(key);
        return Global.Settings.get_string(key);
    }
    loadInt(key) {
        this.push(key);
        return Global.Settings.get_int(key);
    }
    loadStrv(key) {
        this.push(key);
        return Global.Settings.get_strv(key);
    }
    loadValue(key) {
        this.push(key);
        return Global.Settings.get_value(key).recursiveUnpack();
    }
    loadRgb(key) {
        this.push(key);
        const color = Global.Settings.get_value(key).recursiveUnpack();
        if (!color.length)
            return null;
        return color;
    }
    loadRgba(key) {
        this.push(key);
        const color = Global.Settings.get_value(key).recursiveUnpack();
        if (!color.length)
            return null;
        return color;
    }
}
export class FeatureBase {
    constructor() {
        this.disableDebugMessage = false;
        this.maid = new Maid();
        this.loader = new SettingLoader((key) => {
            this.loader.clear();
            this.loadSettings(this.loader);
            this.reload(key);
        }, this);
    }
    load(noSettingsLoad) {
        if (!noSettingsLoad)
            this.loadSettings(this.loader);
        this.onLoad();
    }
    unload(noSettingsUnload) {
        if (!noSettingsUnload)
            this.loader.clear();
        this.onUnload();
        this.maid.clear();
    }
    reload(changedKey) {
        this.unload(true);
        this.load(true);
    }
}

import { FeatureBase } from "../libs/shell/feature.js";
import Global from "../global.js";
import Logger from "../libs/shared/logger.js";
import Config from "../config.js";
export class DebugFeature extends FeatureBase {
	constructor() {
		super(...arguments);
		this.disableDebugMessage = true;
	}
	loadSettings(loader) {
		this.expose = loader.loadBoolean("debug-expose");
		this.showLayoutBorder = loader.loadBoolean("debug-show-layout-border");
		this.logLevel = loader.loadInt("debug-log-level");
	}
	// #endregion settings
	onLoad() {
		Logger.setHeader(Config.loggerPrefix);
		Logger.setLogLevel(this.logLevel);
		Logger.debug(() => `Logger initialized, LogLevel: ${this.logLevel}`);
		if (this.expose) {
			globalThis.qst = Global;
			for (const feature of Global.Extension.features) {
				Global[feature.constructor.name] = feature;
			}
			this.maid.functionJob(() => {
				for (const feature of Global.Extension.features) {
					delete Global[feature.constructor.name];
				}
				delete globalThis.qst;
			});
			Logger.debug("Extension environment expose enabled");
		}
		if (this.showLayoutBorder) {
			// @ts-ignore Box pointer is private
			Global.QuickSettingsMenu._boxPointer.style_class += " QSTWEAKS-debug-show-layout";
			this.maid.functionJob(() => {
				// @ts-ignore Box pointer is private
				Global.QuickSettingsMenu._boxPointer.style_class =
					// @ts-ignore Box pointer is private
					Global.QuickSettingsMenu._boxPointer.style_class.replace(/ QSTWEAKS-debug-show-layout/, "");
			});
			Logger.debug("Show layout border enabled");
		}
	}
	onUnload() { }
}

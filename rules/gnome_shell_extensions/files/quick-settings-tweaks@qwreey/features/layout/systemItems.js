import { FeatureBase } from "../../libs/shell/feature.js";
import Logger from "../../libs/shared/logger.js";
import Global from "../../global.js";
export class SystemItemsLayoutFeature extends FeatureBase {
    loadSettings(loader) {
        this.hideScreenshot = loader.loadBoolean("system-items-layout-hide-screenshot");
        this.hideSettings = loader.loadBoolean("system-items-layout-hide-settings");
        this.hideLock = loader.loadBoolean("system-items-layout-hide-lock");
        this.hideShutdown = loader.loadBoolean("system-items-layout-hide-shutdown");
        this.hideBattery = loader.loadBoolean("system-items-layout-hide-battery");
        this.hideLayout = loader.loadBoolean("system-items-layout-hide");
        this.enabled = loader.loadBoolean("system-items-layout-enabled");
        this.order = loader.loadStrv("system-items-layout-order");
    }
    // #endregion settings
    async getItmes() {
        const systemItem = await Global.QuickSettingsSystemItem;
        const children = systemItem.child.get_children();
        let screenshotItem;
        let settingsItem;
        let lockItem;
        let shutdownItem;
        for (const child of children) {
            if (child.constructor.name == "ScreenshotItem") {
                screenshotItem = child;
                continue;
            }
            if (child.constructor.name == "SettingsItem") {
                settingsItem = child;
                continue;
            }
            if (child.constructor.name == "LockItem") {
                lockItem = child;
                continue;
            }
            if (child.constructor.name == "ShutdownItem") {
                shutdownItem = child;
            }
        }
        return {
            screenshot: screenshotItem,
            settings: settingsItem,
            lock: lockItem,
            shutdown: shutdownItem,
            battery: systemItem.powerToggle,
            laptopSpacer: systemItem._laptopSpacer,
            desktopSpacer: systemItem._desktopSpacer,
            box: systemItem
        };
    }
    onLoad() {
        if (!this.enabled)
            return;
        this.getItmes().then(items => {
            if (this.hideLayout) {
                this.maid.hideJob(items.box, () => true);
                return;
            }
            if (this.hideBattery) {
                this.maid.hideJob(items.battery, () => {
                    items.battery._sync();
                });
            }
            if (this.hideScreenshot) {
                this.maid.hideJob(items.screenshot, () => true);
            }
            if (this.hideLock) {
                this.maid.hideJob(items.lock, () => true);
            }
            if (this.hideShutdown) {
                this.maid.hideJob(items.shutdown, () => true);
            }
            if (this.hideSettings) {
                this.maid.hideJob(items.settings, () => true);
            }
            let last;
            for (const [index, item] of this.order.entries()) {
                const current = items[item];
                if (index)
                    items.box.child.set_child_above_sibling(current, last);
                last = current;
            }
        }).catch(Logger.error);
    }
    onUnload() { }
}

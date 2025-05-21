import * as Main from "resource:///org/gnome/shell/ui/main.js";
import { SystemIndicator } from "resource:///org/gnome/shell/ui/quickSettings.js";
import { FeatureBase } from "../../libs/shell/feature.js";
import { SystemIndicatorTracker } from "../../libs/shell/quickSettingsUtils.js";
import { SystemIndicatorOrderItem } from "../../libs/types/systemIndicatorOrderItem.js";
import { StyleClass } from "../../libs/shared/styleClass.js";
import Global from "../../global.js";
export class SystemIndicatorLayoutFeature extends FeatureBase {
    loadSettings(loader) {
        this.orderEnabled = loader.loadBoolean("system-indicator-layout-enabled");
        this.order = loader.loadValue("system-indicator-layout-order");
        this.unordered = this.order.find(item => item.nonOrdered);
        this.privacyIndicatorStyle = loader.loadString("system-indicator-privacy-indicator-style");
        this.accentScreenSharingIndicator = loader.loadBoolean("system-indicator-screen-sharing-indicator-use-accent");
        this.accentScreenRecordingIndicator = loader.loadBoolean("system-indicator-screen-recording-indicator-use-accent");
    }
    // #endregion settings
    onIndicatorCreated(maid, indicator) {
        const rule = this.order.find(item => SystemIndicatorOrderItem.indicatorMatch(item, indicator))
            ?? this.unordered;
        if (rule.hide)
            maid.hideJob(indicator);
    }
    onUpdate() {
        const children = Global.Indicators.get_children();
        const head = [];
        const middle = children.filter(child => child instanceof SystemIndicator);
        const tail = [];
        let overNonOrdered = false;
        for (const item of this.order) {
            if (item.nonOrdered) {
                overNonOrdered = true;
                continue;
            }
            const middleIndex = middle.findIndex(toggle => SystemIndicatorOrderItem.indicatorMatch(item, toggle));
            if (middleIndex == -1)
                continue;
            const toggle = middle[middleIndex];
            middle.splice(middleIndex, 1);
            (overNonOrdered ? tail : head).push(toggle);
        }
        let last = null;
        for (const item of [head, middle, tail].flat()) {
            if (last)
                Global.Indicators.set_child_above_sibling(item, last);
            last = item;
        }
    }
    onLoad() {
        // Colored privacy indicator
        const privacyIndicatorStyle = new StyleClass(Global.Indicators.style_class);
        if (this.privacyIndicatorStyle == "accent") {
            privacyIndicatorStyle.add("QSTWEAKS-privacy-indicator-use-accent");
        }
        else if (this.privacyIndicatorStyle == "monochrome") {
            privacyIndicatorStyle.add("QSTWEAKS-privacy-indicator-use-monochrome");
        }
        if (privacyIndicatorStyle.modified) {
            Global.Indicators.style_class = privacyIndicatorStyle.stringify();
            this.maid.functionJob(() => {
                Global.Indicators.style_class =
                    new StyleClass(Global.Indicators.style_class)
                        .remove("QSTWEAKS-privacy-indicator-use-accent")
                        .remove("QSTWEAKS-privacy-indicator-use-monochrome")
                        .stringify();
            });
        }
        // Colored screen sharing indicator
        if (this.accentScreenSharingIndicator) {
            Main.panel.statusArea["screenSharing"].style_class =
                new StyleClass(Main.panel.statusArea["screenSharing"].style_class)
                    .add("QSTWEAKS-screen-sharing-indicator-use-accent")
                    .stringify();
            this.maid.functionJob(() => {
                Main.panel.statusArea["screenSharing"].style_class =
                    new StyleClass(Main.panel.statusArea["screenSharing"].style_class)
                        .remove("QSTWEAKS-screen-sharing-indicator-use-accent")
                        .stringify();
            });
        }
        // Colored screen recording indicator
        if (this.accentScreenRecordingIndicator) {
            Main.panel.statusArea["screenRecording"].style_class =
                new StyleClass(Main.panel.statusArea["screenRecording"].style_class)
                    .add("QSTWEAKS-screen-recording-indicator-use-accent")
                    .stringify();
            this.maid.functionJob(() => {
                Main.panel.statusArea["screenRecording"].style_class =
                    new StyleClass(Main.panel.statusArea["screenRecording"].style_class)
                        .remove("QSTWEAKS-screen-recording-indicator-use-accent")
                        .stringify();
            });
        }
        // Ordering
        if (!this.orderEnabled)
            return;
        this.tracker = new SystemIndicatorTracker();
        this.tracker.onIndicatorCreated = this.onIndicatorCreated.bind(this);
        this.tracker.onUpdate = this.onUpdate.bind(this);
        this.tracker.load();
    }
    onUnload() {
        const tracker = this.tracker;
        if (tracker) {
            this.tracker = null;
            tracker.unload();
        }
    }
}

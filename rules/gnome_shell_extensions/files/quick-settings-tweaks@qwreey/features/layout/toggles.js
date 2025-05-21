import { QuickToggle, QuickMenuToggle, } from "resource:///org/gnome/shell/ui/quickSettings.js";
import { FeatureBase } from "../../libs/shell/feature.js";
import { QuickSettingsToggleTracker } from "../../libs/shell/quickSettingsUtils.js";
import { ToggleOrderItem } from "../../libs/types/toggleOrderItem.js";
import Global from "../../global.js";
export class TogglesLayoutFeature extends FeatureBase {
    loadSettings(loader) {
        this.enabled = loader.loadBoolean("toggles-layout-enabled");
        this.order = loader.loadValue("toggles-layout-order");
        for (const orderItem of this.order) {
            if (orderItem.titleRegex) {
                orderItem.cachedTitleRegex = new RegExp(orderItem.titleRegex);
            }
            if (orderItem.nonOrdered) {
                this.unordered = orderItem;
            }
        }
    }
    // #endregion settings
    onToggleCreated(maid, toggle) {
        const rule = this.order.find(item => ToggleOrderItem.toggleMatch(item, toggle))
            ?? this.unordered;
        if (rule.hide)
            maid.hideJob(toggle);
    }
    onUpdate() {
        const children = Global.QuickSettingsGrid.get_children();
        const head = [];
        const middle = children.filter(child => ((child instanceof QuickMenuToggle)
            || (child instanceof QuickToggle))
            && child.constructor.name != "BackgroundAppsToggle");
        const tail = [];
        let overNonOrdered = false;
        for (const item of this.order) {
            if (item.nonOrdered) {
                overNonOrdered = true;
                continue;
            }
            const middleIndex = middle.findIndex(toggle => ToggleOrderItem.toggleMatch(item, toggle));
            if (middleIndex == -1)
                continue;
            const toggle = middle[middleIndex];
            middle.splice(middleIndex, 1);
            (overNonOrdered ? tail : head).push(toggle);
        }
        let last = null;
        for (const item of [head, middle, tail].flat()) {
            if (last)
                Global.QuickSettingsGrid.set_child_above_sibling(item, last);
            last = item;
        }
    }
    onLoad() {
        if (!this.enabled)
            return;
        this.tracker = new QuickSettingsToggleTracker();
        this.tracker.onToggleCreated = this.onToggleCreated.bind(this);
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

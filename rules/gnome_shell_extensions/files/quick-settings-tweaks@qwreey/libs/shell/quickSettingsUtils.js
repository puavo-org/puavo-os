import { QuickMenuToggle, QuickToggle, SystemIndicator, } from "resource:///org/gnome/shell/ui/quickSettings.js";
import { PopupSeparatorMenuItem } from "resource:///org/gnome/shell/ui/popupMenu.js";
import Global from "../../global.js";
import Maid from "../shared/maid.js";
export class ChildrenTrackerBase {
    load() {
        const connectTarget = this.connectTarget = this.getConnectTarget();
        this.appliedChild = new Map();
        this.addConnection = connectTarget.connect("child-added", (_, child) => {
            this.catchChild(child);
            if (this.onUpdate)
                this.onUpdate();
        });
        for (const child of connectTarget.get_children()) {
            this.catchChild(child);
        }
        if (this.onUpdate)
            this.onUpdate();
    }
    unload() {
        for (const maid of this.appliedChild.values()) {
            maid.destroy();
        }
        this.connectTarget.disconnect(this.addConnection);
        this.addConnection = null;
        this.appliedChild = null;
    }
    get items() {
        if (!this.appliedChild)
            return [];
        return [...this.appliedChild.keys()];
    }
}
export class QuickSettingsMenuTracker extends ChildrenTrackerBase {
    catchChild(child) {
        const menu = child.menu;
        if (!menu)
            return;
        if (this.appliedChild.has(menu))
            return;
        const menuMaid = new Maid();
        menuMaid.functionJob(() => {
            this.appliedChild.delete(menu);
        });
        menuMaid.connectJob(menu, "open-state-changed", (_, isOpen) => {
            if (this.onMenuOpen)
                this.onMenuOpen(menuMaid, menu, isOpen);
        });
        menuMaid.connectJob(menu, "destroy", () => {
            menuMaid.destroy();
        });
        if (this.onMenuCreated)
            this.onMenuCreated(menuMaid, menu);
        this.appliedChild.set(menu, menuMaid);
    }
    getConnectTarget() {
        return Global.QuickSettingsGrid;
    }
    get menus() {
        if (!this.appliedChild)
            return [];
        return [...this.appliedChild.keys()];
    }
}
export class QuickSettingsToggleTracker extends ChildrenTrackerBase {
    catchChild(child) {
        if (!(child instanceof QuickToggle)
            && !(child instanceof QuickMenuToggle))
            return;
        if (this.appliedChild.has(child))
            return;
        const toggleMaid = new Maid();
        toggleMaid.functionJob(() => {
            this.appliedChild.delete(child);
        });
        toggleMaid.connectJob(child, "destroy", () => {
            toggleMaid.destroy();
        });
        if (this.onToggleCreated)
            this.onToggleCreated(toggleMaid, child);
        this.appliedChild.set(child, toggleMaid);
    }
    getConnectTarget() {
        return Global.QuickSettingsGrid;
    }
}
export class SystemIndicatorTracker extends ChildrenTrackerBase {
    catchChild(child) {
        if (!(child instanceof SystemIndicator))
            return;
        if (this.appliedChild.has(child))
            return;
        const indicatorMaid = new Maid();
        indicatorMaid.functionJob(() => {
            this.appliedChild.delete(child);
        });
        indicatorMaid.connectJob(child, "destroy", () => {
            indicatorMaid.destroy();
        });
        if (this.onIndicatorCreated)
            this.onIndicatorCreated(indicatorMaid, child);
        this.appliedChild.set(child, indicatorMaid);
    }
    getConnectTarget() {
        return Global.Indicators;
    }
}
export function updateMenuSeparators(menu) {
    for (const item of menu._getMenuItems()) {
        if (!(item instanceof PopupSeparatorMenuItem)) {
            continue;
        }
        menu._updateSeparatorVisibility(item);
    }
}

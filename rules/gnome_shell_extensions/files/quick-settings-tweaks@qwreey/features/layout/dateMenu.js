import { FeatureBase } from "../../libs/shell/feature.js";
import { StyleClass } from "../../libs/shared/styleClass.js";
import Global from "../../global.js";
import Logger from "../../libs/shared/logger.js";
export class DateMenuLayoutFeature extends FeatureBase {
    loadSettings(loader) {
        this.hideLeftBox = loader.loadBoolean("datemenu-hide-left-box");
        this.hideRightBox = loader.loadBoolean("datemenu-hide-right-box");
        this.disableMenu = loader.loadBoolean("datemenu-disable-menu");
    }
    // #endregion settings
    onLoad() {
        const style = new StyleClass(Global.DateMenuBox.style_class);
        // Hide left box from date menu
        if (this.hideLeftBox) {
            const leftBox = Global.DateMenuHolder.get_first_child();
            if (leftBox) {
                this.maid.hideJob(leftBox, () => true);
            }
            else {
                Logger.error("Failed to get date menu left box");
            }
            style.add("QSTWEAKS-hide-left-box");
        }
        // Hide right box from date menu
        if (this.hideRightBox) {
            const rightBox = Global.DateMenuHolder.get_last_child();
            if (rightBox) {
                this.maid.hideJob(rightBox, () => true);
            }
            else {
                Logger.error("Failed to get date menu right box");
            }
            style.add("QSTWEAKS-hide-right-box");
        }
        // Disable menu open action
        if (this.disableMenu) {
            Global.DateMenu.reactive = false;
            this.maid.functionJob(() => {
                Global.DateMenu.reactive = true;
            });
        }
        // Modify style class
        if (style.modified) {
            Global.DateMenuBox.style_class = style.stringify();
        }
    }
    onUnload() {
        // Remove modified styles
        const style = new StyleClass(Global.DateMenuBox.style_class)
            .remove("QSTWEAKS-hide-right-box")
            .remove("QSTWEAKS-hide-left-box");
        if (style.modified) {
            Global.DateMenuBox.style_class = style.stringify();
        }
    }
}

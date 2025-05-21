import { FeatureBase } from "../../libs/shell/feature.js";
import GObject from "gi://GObject";
// TODO: migration from qst 1.8
export class SoundLayoutFeature extends FeatureBase {
    // #region settings
    loadSettings(loader) {
        throw GObject.NotImplementedError;
    }
    // #endregion settings
    onLoad() {
        throw GObject.NotImplementedError;
    }
    onUnload() {
        throw GObject.NotImplementedError;
    }
}

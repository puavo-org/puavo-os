import St from "gi://St";
import { Rgba } from "../shared/colors.js";
export var StyledSlider;
(function (StyledSlider) {
    function getStyle(options) {
        const { style, activeBackgroundColor, handleRadius, handleColor, backgroundColor, height, } = options;
        const styleList = [];
        switch (style) {
            case "slim":
                styleList.push("-slider-handle-radius:0px");
                if (activeBackgroundColor) {
                    styleList.push("color:" + Rgba.formatCss(activeBackgroundColor));
                }
                else {
                    styleList.push("color:-st-accent-color");
                }
                break;
            case "default":
            default:
                if (handleRadius) {
                    styleList.push(`-slider-handle-radius:${handleRadius}px`);
                }
                if (handleColor) {
                    styleList.push(`color:${Rgba.formatCss(handleColor)}`);
                }
                break;
        }
        if (height)
            styleList.push(`-barlevel-height:${height}px`);
        if (activeBackgroundColor)
            styleList.push(`-barlevel-active-background-color:${Rgba.formatCss(activeBackgroundColor)}`);
        if (backgroundColor)
            styleList.push(`-barlevel-background-color:${Rgba.formatCss(backgroundColor)}`);
        const result = styleList.join(";");
        return result;
    }
    StyledSlider.getStyle = getStyle;
    let Options;
    (function (Options) {
        function fromLoader(loader, prefix) {
            return {
                style: loader.loadString(prefix + "-style"),
                handleColor: loader.loadRgba(prefix + "-handle-color"),
                handleRadius: loader.loadInt(prefix + "-handle-radius"),
                backgroundColor: loader.loadRgba(prefix + "-background-color"),
                height: loader.loadInt(prefix + "-height"),
                activeBackgroundColor: loader.loadRgba(prefix + "-active-background-color"),
            };
        }
        Options.fromLoader = fromLoader;
        function isStyleKey(prefix, key) {
            if (key == prefix + "-style")
                return true;
            if (key == prefix + "-handle-color")
                return true;
            if (key == prefix + "-handle-radius")
                return true;
            if (key == prefix + "-background-color")
                return true;
            if (key == prefix + "-height")
                return true;
            if (key == prefix + "-active-background-color")
                return true;
            return false;
        }
        Options.isStyleKey = isStyleKey;
    })(Options = StyledSlider.Options || (StyledSlider.Options = {}));
})(StyledSlider || (StyledSlider = {}));
export var StyledScroll;
(function (StyledScroll) {
    function updateStyle(scroll, options) {
        scroll.style_class =
            options.fadeOffset
                ? "vfade"
                : "";
        scroll.vscrollbar_policy =
            options.showScrollbar
                ? St.PolicyType.AUTOMATIC
                : St.PolicyType.EXTERNAL;
        scroll.style =
            options.fadeOffset
                ? `-st-vfade-offset:${options.fadeOffset}px;`
                : "";
    }
    StyledScroll.updateStyle = updateStyle;
    let Options;
    (function (Options) {
        function fromLoader(loader, prefix) {
            return {
                showScrollbar: loader.loadBoolean(prefix + "-show-scrollbar"),
                fadeOffset: loader.loadInt(prefix + "-fade-offset"),
            };
        }
        Options.fromLoader = fromLoader;
    })(Options = StyledScroll.Options || (StyledScroll.Options = {}));
})(StyledScroll || (StyledScroll = {}));

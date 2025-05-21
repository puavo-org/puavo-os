export var Rgba;
(function (Rgba) {
    function formatCss(color) {
        const [r, g, b, a] = color;
        return `rgba(${r},${g},${b},${a / 1000})`;
    }
    Rgba.formatCss = formatCss;
})(Rgba || (Rgba = {}));

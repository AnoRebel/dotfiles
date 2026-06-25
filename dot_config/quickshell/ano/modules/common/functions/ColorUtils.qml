pragma Singleton
import Quickshell

Singleton {
    id: root

    // Mix two colors: ratio 0.0 = pure color2, 1.0 = pure color1
    function mix(color1, color2, ratio, alpha) {
        if (alpha === undefined) alpha = -1;
        let r = color1.r * ratio + color2.r * (1 - ratio);
        let g = color1.g * ratio + color2.g * (1 - ratio);
        let b = color1.b * ratio + color2.b * (1 - ratio);
        let a = alpha >= 0 ? alpha : (color1.a * ratio + color2.a * (1 - ratio));
        return Qt.rgba(r, g, b, a);
    }

    // Set alpha on a color
    function transparentize(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    // Solve overlay color given base, overlay, and desired opacity
    function solveOverlayColor(baseColor, overlayColor, opacity) {
        if (opacity <= 0) return overlayColor;
        if (opacity >= 1) return baseColor;
        let r = (overlayColor.r - baseColor.r * (1 - opacity)) / opacity;
        let g = (overlayColor.g - baseColor.g * (1 - opacity)) / opacity;
        let b = (overlayColor.b - baseColor.b * (1 - opacity)) / opacity;
        return Qt.rgba(
            Math.max(0, Math.min(1, r)),
            Math.max(0, Math.min(1, g)),
            Math.max(0, Math.min(1, b)),
            opacity
        );
    }

    // Lighten a color by amount (0-1)
    function lighten(color, amount) {
        return mix(Qt.rgba(1, 1, 1, color.a), color, amount);
    }

    // Darken a color by amount (0-1)
    function darken(color, amount) {
        return mix(Qt.rgba(0, 0, 0, color.a), color, amount);
    }

    // Get luminance of a color (0-1)
    function luminance(color) {
        return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
    }

    // Check if a color is "dark"
    function isDark(color) {
        return luminance(color) < 0.5;
    }

    // Convert hex string to color
    function fromHex(hex) {
        return Qt.color(hex);
    }

    // Convert color to hex string
    function toHex(color) {
        function _hex(v) {
            let h = Math.round(v * 255).toString(16);
            return h.length === 1 ? "0" + h : h;
        }
        return "#" + _hex(color.r) + _hex(color.g) + _hex(color.b);
    }

    // Convert color to hex with alpha
    function toHexA(color) {
        function _hex(v) {
            let h = Math.round(v * 255).toString(16);
            return h.length === 1 ? "0" + h : h;
        }
        return "#" + _hex(color.r) + _hex(color.g) + _hex(color.b) + _hex(color.a);
    }
}

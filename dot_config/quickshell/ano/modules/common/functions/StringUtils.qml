pragma Singleton
import Quickshell

Singleton {
    id: root

    // Truncate string with ellipsis
    function truncate(str, maxLength, suffix) {
        if (typeof str !== "string") return "";
        if (suffix === undefined) suffix = "…";
        if (str.length <= maxLength) return str;
        return str.substring(0, maxLength - suffix.length) + suffix;
    }

    // Capitalize first letter
    function capitalize(str) {
        if (typeof str !== "string" || str.length === 0) return "";
        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    // Title case (capitalize each word)
    function titleCase(str) {
        if (typeof str !== "string") return "";
        return str.split(/\s+/).map(w => capitalize(w)).join(" ");
    }

    // Format bytes as human-readable (KB, MB, GB, etc.)
    function formatBytes(bytes, decimals) {
        if (decimals === undefined) decimals = 1;
        if (bytes === 0) return "0 B";
        let k = 1024;
        let sizes = ["B", "KB", "MB", "GB", "TB"];
        let i = Math.floor(Math.log(bytes) / Math.log(k));
        let value = bytes / Math.pow(k, i);
        return value.toFixed(decimals) + " " + sizes[i];
    }

    // Format duration in seconds as human-readable (e.g., "3:45", "1:02:30")
    function formatDuration(seconds) {
        if (typeof seconds !== "number" || seconds < 0) return "0:00";
        seconds = Math.floor(seconds);
        let h = Math.floor(seconds / 3600);
        let m = Math.floor((seconds % 3600) / 60);
        let s = seconds % 60;
        let sStr = s < 10 ? "0" + s : "" + s;
        if (h > 0) {
            let mStr = m < 10 ? "0" + m : "" + m;
            return h + ":" + mStr + ":" + sStr;
        }
        return m + ":" + sStr;
    }

    // Format percentage
    function formatPercent(value, decimals) {
        if (decimals === undefined) decimals = 0;
        return (value * 100).toFixed(decimals) + "%";
    }

    // Simple template substitution: replaces {key} with values[key]
    function template(str, values) {
        if (typeof str !== "string") return "";
        return str.replace(/\{(\w+)\}/g, function(match, key) {
            return values.hasOwnProperty(key) ? values[key] : match;
        });
    }
}

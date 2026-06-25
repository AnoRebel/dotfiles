pragma Singleton
import Quickshell

/**
 * Format helpers for the Settings UI. Single source of truth for
 * unit-driven duration rendering, so every interval/timeout slider
 * across the Settings pages reads consistently regardless of magnitude.
 */
Singleton {
    id: root

    /**
     * Format a millisecond duration with the unit picked by magnitude.
     * Precision is preserved so timing-sensitive fields (animation
     * durations, idle thresholds, fetch intervals) stay readable
     * without rounding away meaningful values.
     *
     *   < 1000ms                  → integer "Nms"
     *   1s..9.99s                 → "N.NNs" (two decimals for fine timings)
     *   10s..59.9s                → "N.Ns" (one decimal)
     *   1min..9min59s             → "Nmin Ns" when it has a tail seconds part,
     *                                 else "Nmin" (e.g. "1min 30s", "5min")
     *   10min..59min              → integer "Nmin"
     *   1h..9h59m                 → "Nh Nmin" when it has a tail minutes part,
     *                                 else "Nh" (e.g. "1h 30min", "2h")
     *   ≥ 10h                     → "N.Nh" (one decimal)
     *
     * Trailing zeros are stripped — e.g. 1500ms → "1.5s", not "1.50s".
     * Negative or non-finite inputs return "0ms".
     */
    function formatDuration(ms) {
        if (typeof ms !== "number" || !isFinite(ms) || ms < 0) return "0ms";
        if (ms < 1000) return Math.round(ms) + "ms";

        // Sub-minute: one or two decimals depending on scale
        if (ms < 60_000) {
            const s = ms / 1000;
            const decimals = s < 10 ? 2 : 1;
            return root._stripTrailingZeros(s.toFixed(decimals)) + "s";
        }

        // Sub-hour: split into "Nmin Ns" when there's a meaningful tail
        if (ms < 3_600_000) {
            const totalSec = Math.round(ms / 1000);
            const min = Math.floor(totalSec / 60);
            const sec = totalSec - min * 60;
            // Drop the seconds tail when it's zero, or when minutes ≥ 10
            // (10min granularity is fine).
            if (sec === 0 || min >= 10) return min + "min";
            return min + "min " + sec + "s";
        }

        // Sub-10h: split into "Nh Nmin" when there's a meaningful tail
        if (ms < 36_000_000) {
            const totalMin = Math.round(ms / 60_000);
            const h = Math.floor(totalMin / 60);
            const min = totalMin - h * 60;
            if (min === 0) return h + "h";
            return h + "h " + min + "min";
        }

        // ≥10h: one decimal hours, plenty of resolution
        const h = ms / 3_600_000;
        return root._stripTrailingZeros(h.toFixed(1)) + "h";
    }

    // Internal: drop trailing zeros (and a stranded decimal point) from
    // a fixed-decimal numeric string so we don't render "1.50s".
    function _stripTrailingZeros(s) {
        if (s.indexOf(".") < 0) return s;
        return s.replace(/\.?0+$/, "");
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import "."

/**
 * Registry powering the Settings command palette.
 *
 * Builds a search index dynamically from two live sources:
 *
 *   1. Config.options — every leaf and intermediate key in the user's
 *      JSON config becomes a search entry. New keys added to the schema
 *      automatically appear in search; no static list to keep in sync.
 *
 *   2. The per-page configRoots declared on each SettingsPageHeader —
 *      maps top-level config roots to the Settings page that owns them.
 *
 * Entry shape (per leaf):
 *
 *   {
 *     key: "anoSpot.eventBorder.holdMs",
 *     pageIndex: 5,             // index into SettingsOverlay.pages
 *     pageName: "AnoSpot",      // human-readable
 *     pageIcon: "view_compact_alt",
 *     haystack: "anoSpot.eventBorder.holdMs anoSpot AnoSpot eventBorder holdMs",
 *   }
 *
 * Card-level resolution (for scroll-to-card) is performed at click time
 * by SettingsCommandPalette, which walks the loaded page's children for
 * a SettingsCard whose configKeys list covers the entry's key — that
 * avoids needing a parallel static map of cards.
 *
 * Page mapping must be registered by SettingsOverlay/settings.qml so the
 * registry knows the canonical page list (index → name + icon + roots).
 * Both shells call registerPages() with the same data on startup.
 */
Singleton {
    id: root

    // Set by the host shell (overlay or standalone). Each entry:
    //   { name, icon, configRoots: [...] }
    property var pages: []

    // Cached search index — recomputed when pages or config schema changes.
    property var entries: []

    // Token-set tokens of the current query, lower-cased and trimmed.
    // Empty array means "show everything"; otherwise every token must
    // appear in an entry's haystack.
    property var _queryTokens: []
    property string query: ""

    // Filtered + ranked subset of `entries` matching the current query.
    property var results: []

    onQueryChanged: {
        const q = (root.query || "").trim().toLowerCase();
        root._queryTokens = q.length === 0 ? [] : q.split(/\s+/).filter(t => t.length > 0);
        root._refilter();
    }

    // Called by the host shell at startup with the same `pages` array
    // SettingsOverlay/settings.qml use to render the nav rail. Idempotent.
    function registerPages(pageList) {
        root.pages = pageList || [];
        root._rebuildIndex();
    }

    // Rebuild on demand if the host shell wants to refresh after config
    // reloads (Config emits readyChanged once the bundle + delta apply).
    function rebuild() { root._rebuildIndex(); }

    // ── Index build ────────────────────────────────────────────────────

    function _rebuildIndex() {
        const opts = Config.options;
        if (!opts) {
            root.entries = [];
            root.results = [];
            return;
        }
        const out = [];
        // Walk every key path in Config.options. Both leaves and
        // intermediate objects emit entries — searching "anoSpot" should
        // match both a top-level subtree and individual leaves.
        root._walk(opts, "", out);
        root.entries = out;
        root._refilter();
    }

    function _walk(obj, prefix, out) {
        if (!obj || typeof obj !== "object") return;
        // QML JsonAdapter properties enumerate as plain JS-object keys.
        for (const key in obj) {
            if (key.startsWith("_") || key.startsWith("on")) continue;
            const value = obj[key];
            if (typeof value === "function") continue;
            const path = prefix.length === 0 ? key : `${prefix}.${key}`;

            const pageInfo = root._resolvePage(path);
            // Every path that resolves to a known page becomes an entry.
            if (pageInfo) {
                out.push({
                    key: path,
                    pageIndex: pageInfo.index,
                    pageName: pageInfo.name,
                    pageIcon: pageInfo.icon,
                    haystack: root._buildHaystack(path, pageInfo.name)
                });
            }
            // Recurse into plain objects (skip arrays — they're values, not subtrees).
            const isPlainObject = value && typeof value === "object"
                && !Array.isArray(value) && !(value instanceof Date);
            if (isPlainObject) {
                root._walk(value, path, out);
            }
        }
    }

    // Find the page whose configRoots cover this dotted path.
    // Matches in priority order: exact dotted path > top-level root.
    function _resolvePage(path) {
        const top = path.split(".")[0];
        let topMatch = null;
        for (let i = 0; i < root.pages.length; ++i) {
            const page = root.pages[i];
            const roots = page.configRoots || [];
            // Exact dotted-path hit beats top-level
            for (const r of roots) {
                if (r === path) {
                    return { index: i, name: page.name, icon: page.icon };
                }
            }
            for (const r of roots) {
                if (r === top && !topMatch) {
                    topMatch = { index: i, name: page.name, icon: page.icon };
                }
            }
        }
        return topMatch;
    }

    // The haystack a query is matched against. Includes the dotted path,
    // its individual segments (so "holdMs" matches "anoSpot.eventBorder.holdMs"
    // typed as just "holdms"), and the page name.
    function _buildHaystack(path, pageName) {
        const segments = path.split(".");
        // Also produce camel-case-split tokens, so "hold ms" and "event border"
        // match the run-on identifiers. QtJS doesn't always have flatMap,
        // so concat manually.
        const camelSplit = [];
        for (const s of segments) {
            const parts = s.replace(/([a-z])([A-Z])/g, "$1 $2").split(/\s+/);
            for (const p of parts) camelSplit.push(p);
        }
        return [path, pageName].concat(segments).concat(camelSplit).join(" ").toLowerCase();
    }

    // ── Filter / rank ──────────────────────────────────────────────────

    function _refilter() {
        const tokens = root._queryTokens;
        if (tokens.length === 0) {
            // No query — show top entries by some sensible default. Use
            // page index ascending so users see the natural Settings order.
            root.results = root.entries.slice(0, 50).sort((a, b) => {
                if (a.pageIndex !== b.pageIndex) return a.pageIndex - b.pageIndex;
                return a.key.localeCompare(b.key);
            });
            return;
        }
        // Every token must appear somewhere in the haystack (AND across tokens,
        // case-insensitive substring match — already lower-cased on store).
        const matches = root.entries.filter(e => {
            for (const t of tokens) if (e.haystack.indexOf(t) < 0) return false;
            return true;
        });
        // Rank: shorter key wins (more specific matches surface first).
        matches.sort((a, b) => {
            // Prefer entries whose key path itself contains all tokens
            const aKey = a.key.toLowerCase();
            const bKey = b.key.toLowerCase();
            const aHits = tokens.every(t => aKey.indexOf(t) >= 0) ? 1 : 0;
            const bHits = tokens.every(t => bKey.indexOf(t) >= 0) ? 1 : 0;
            if (aHits !== bHits) return bHits - aHits;
            return a.key.length - b.key.length;
        });
        root.results = matches.slice(0, 100);
    }

    // Refresh the index when the config becomes ready (initial load) or
    // reloads (user edited the file externally).
    Connections {
        target: Config
        function onReadyChanged() { if (Config.ready) root._rebuildIndex(); }
    }
    Component.onCompleted: { if (Config.ready) root._rebuildIndex(); }
}

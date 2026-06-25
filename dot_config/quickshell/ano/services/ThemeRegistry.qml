pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Discovers + indexes available static themes from
 *   1. Directories.userThemesPath (~/.config/anoshell/themes/*.json) — user overrides
 *   2. Directories.bundledThemesPath (assets/themes/*.json) — shipped
 *
 * Exposes `themes`, a ListModel of:
 *     {
 *       name              filename without .json (= the value to write to
 *                         Config.options.appearance.theme.name)
 *       displayName       _meta.name from the JSON
 *       description       _meta.description
 *       darkmode          true/false from _meta.darkmode
 *       primary           hex string for the picker swatch
 *       surface           hex string for the picker swatch
 *       surfaceContainer  hex string for the picker swatch
 *       outline           hex string for the picker swatch
 *       source            "user" if loaded from userThemesPath, else "bundled"
 *     }
 *
 * Also exposes `themeContents`, a JS object mapping theme name → fully
 * parsed JSON, used by AppearanceConfig's hover-preview to feed
 * Appearance.previewTokens without re-reading the file.
 *
 * Refresh by calling refresh(); the registry also auto-refreshes on
 * Component.onCompleted.
 *
 * User themes take precedence on filename collision — the user dir is
 * scanned first, and the bundled scan skips any name already loaded.
 */
Singleton {
    id: root

    ListModel { id: themesModel }
    property alias themes: themesModel
    readonly property int count: themesModel.count

    // name → parsed JSON. Populated alongside themesModel as files are
    // read. Used for hover-preview without disk re-reads.
    property var themeContents: ({})

    // Track loaded names so the bundled pass can skip user-overridden entries.
    property var _loadedNames: new Set()
    // Pending file-read queue. Each entry: { path, name, source }
    property var _pendingFiles: []

    function refresh(): void {
        themesModel.clear()
        themeContents = ({})
        _loadedNames = new Set()
        _pendingFiles = []
        // List user dir first so it wins on name collisions.
        listUserDirProc.running = true
    }

    function _onListed(rawText: string, source: string, dir: string): void {
        const lines = (rawText || "").split("\n").map(l => l.trim()).filter(l => l.length > 0)
        for (const line of lines) {
            if (!line.endsWith(".json")) continue
            const name = line.slice(0, -5)
            if (_loadedNames.has(name)) continue  // user-override beats bundled
            _pendingFiles.push({ path: dir + "/" + line, name: name, source: source })
        }
        _processNext()
    }

    function _processNext(): void {
        if (_pendingFiles.length === 0) {
            // After user dir, scan bundled.
            if (!listBundledDirProc.running && !listBundledDirProc._done) {
                listBundledDirProc._done = true
                listBundledDirProc.running = true
            }
            return
        }
        const next = _pendingFiles.shift()
        readProc._currentEntry = next
        readProc.command = ["cat", next.path]
        readProc.running = true
    }

    Component.onCompleted: refresh()

    // Re-scan when the underlying paths change (rare — e.g. user edits config
    // to point at a different stashDir). Cheap, no harm.
    Connections {
        target: Directories
        function onUserThemesPathChanged() { root.refresh() }
        function onBundledThemesPathChanged() { root.refresh() }
    }

    Process {
        id: listUserDirProc
        // ls returns nonzero when the dir doesn't exist — that's fine, just means no user themes.
        command: ["ls", "-1", Directories.userThemesPath]
        stdout: StdioCollector {
            onStreamFinished: root._onListed(this.text, "user", Directories.userThemesPath)
        }
        onExited: (code, _) => {
            if (code !== 0) {
                // Skip silently to bundled scan.
                listBundledDirProc._done = true
                listBundledDirProc.running = true
            }
        }
    }

    Process {
        id: listBundledDirProc
        property bool _done: false
        command: ["ls", "-1", Directories.bundledThemesPath]
        stdout: StdioCollector {
            onStreamFinished: root._onListed(this.text, "bundled", Directories.bundledThemesPath)
        }
    }

    Process {
        id: readProc
        property var _currentEntry: null
        stdout: StdioCollector {
            onStreamFinished: {
                const entry = readProc._currentEntry
                if (!entry) return
                let json
                try {
                    json = JSON.parse(this.text)
                } catch (e) {
                    console.warn("[ThemeRegistry] failed to parse", entry.path, ":", e)
                    root._processNext()
                    return
                }

                const meta = json._meta || {}
                themesModel.append({
                    name: entry.name,
                    displayName: meta.name || entry.name,
                    description: meta.description || "",
                    darkmode: meta.darkmode !== false,
                    primary: json.primary || "#888888",
                    surface: json.surface || json.background || "#222222",
                    surfaceContainer: json.surface_container_high || json.surface_container || json.surface || "#333333",
                    outline: json.outline || json.outline_variant || "#444444",
                    source: entry.source
                })
                // Cache the full parsed JSON so AppearanceConfig hover-preview
                // can feed Appearance.previewTokens without re-reading the file.
                const updated = Object.assign({}, root.themeContents)
                updated[entry.name] = json
                root.themeContents = updated
                root._loadedNames.add(entry.name)
                root._processNext()
            }
        }
    }
}

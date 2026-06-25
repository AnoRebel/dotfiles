pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import "lrcparser.js" as Lrc

/**
 * Synchronized lyrics for the currently playing Mpris track.
 *
 * Backends (Config.options.lyrics.backend):
 *   "Auto"    — default. Try Local first; fall back to LRCLIB; then NetEase
 *   "Local"   — only read .lrc files from <lyrics.dir>; no network
 *   "LRCLIB"  — query lrclib.net (cleanest public API, MIT-licensed corpus)
 *   "NetEase" — query music.163.com (broad Chinese-music coverage; needs
 *               browser-style headers)
 *
 * Local file resolution: searches <lyrics.dir> for "<artist> - <title>.lrc"
 * (case-insensitive, recursive) before any network call.
 *
 * Public surface:
 *   model            ListModel of { time, lyricLine }
 *   currentIndex     index of the line currently playing (or -1)
 *   loading          true while a fetch is in flight
 *   backend          which backend produced the current model
 *   offset           per-track offset in seconds (saved to lyricsMap)
 *   candidatesModel  alternate candidate songs from the online backend
 *                    so the user can manually pick when auto-match is wrong
 *   loadLyrics()     re-trigger lookup for the current track
 *   selectCandidate(songId, source)
 *   jumpTo(index, time)
 *   savePrefs()      persist offset + chosen backend + chosen songId
 *
 * Adapter changes from caelestia/services/LyricsService.qml:
 *   - Players.active                 → MprisController.activePlayer
 *   - Requests.get(url, cb, err, hdr) → Process(curl) per-fetcher (3 procs)
 *   - GlobalConfig.services.{showLyrics,lyricsBackend,paths.lyricsDir}
 *                                    → Config.options.lyrics.{visible,backend,dir}
 *   - Paths.absolutePath(...)        → manual ~ expansion via Quickshell.env("HOME")
 *   - LRCLIB primary online backend, NetEase secondary (caelestia did
 *     NetEase only). Auto mode tries LRCLIB before falling back to NetEase
 *   - Service is dormant when Config.options.lyrics.enable is false
 *     (default false). Auto-fetch on track change is gated on this.
 */
Singleton {
    id: root

    // ─── Config-driven properties ─────────────────────────────────────────
    readonly property bool serviceEnabled: Config.options?.lyrics?.enable ?? false
    readonly property bool lyricsVisible: Config.options?.lyrics?.visible ?? true
    readonly property string preferredBackend: Config.options?.lyrics?.backend ?? "Auto"
    readonly property string lyricsDir: {
        const raw = Config.options?.lyrics?.dir ?? "~/.config/anoshell/lyrics";
        const home = Quickshell.env("HOME") || "";
        return raw.replace(/^~(\/|$)/, home + "/").replace(/\/$/, "");
    }
    readonly property string lyricsMapFile: lyricsDir + "/lyrics_map.json"

    // ─── State ────────────────────────────────────────────────────────────
    property var player: MprisController.activePlayer
    property int currentIndex: -1
    property bool loading: false
    property bool isManualSeeking: false
    property string backend: "Local"        // backend that produced the current model
    property real currentSongId: 0          // backend-specific id (NetEase) or 0
    property string loadedLocalFile: ""
    property real offset: 0
    property int currentRequestId: 0
    property var lyricsMap: ({})            // { "Artist - Title": { offset, backend, neteaseId } }

    readonly property alias model: lyricsModel
    readonly property alias candidatesModel: fetchedCandidatesModel

    // Browser-style headers for NetEase (it 403s a bare curl).
    readonly property var _netEaseHeaders: [
        "-H", "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0",
        "-H", "Referer: https://music.163.com/"
    ]

    // ─── Public API ───────────────────────────────────────────────────────
    function getMetadata() {
        if (!player || !player.metadata) return null;
        let artist = player.metadata["xesam:artist"];
        const title = player.metadata["xesam:title"];
        if (Array.isArray(artist)) artist = artist.join(", ");
        return { artist: artist || "Unknown", title: title || "Unknown" };
    }

    function _metaKey(meta) {
        return `${meta.artist} - ${meta.title}`;
    }

    function savePrefs() {
        const meta = getMetadata();
        if (!meta) return;
        const key = _metaKey(meta);
        const existing = root.lyricsMap[key] ?? {};
        root.lyricsMap[key] = {
            offset: root.offset,
            backend: root.backend,
            neteaseId: existing.neteaseId ?? null
        };
        root.lyricsMap = root.lyricsMap;  // notify bindings

        const payload = JSON.stringify(root.lyricsMap);
        saveLyricsMap.command = ["sh", "-c",
            `mkdir -p ${_shEsc(root.lyricsDir)} && printf %s ${_shEsc(payload)} > ${_shEsc(root.lyricsMapFile)}`
        ];
        saveLyricsMap.running = true;
    }

    function toggleVisibility() {
        Config.setNestedValue("lyrics.visible", !root.lyricsVisible);
    }

    function loadLyrics() {
        if (!root.serviceEnabled) return;
        loadDebounce.restart();
    }

    function _shEsc(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function _doLoadLyrics() {
        const meta = getMetadata();
        if (!meta) {
            lyricsModel.clear();
            root.currentIndex = -1;
            return;
        }

        loading = true;
        lyricsModel.clear();
        currentIndex = -1;
        root.currentSongId = 0;

        root.currentRequestId++;
        const requestId = root.currentRequestId;

        const key = _metaKey(meta);
        const saved = root.lyricsMap[key];
        root.offset = saved?.offset ?? 0.0;

        // Pinned-backend modes go straight to that backend.
        if (root.preferredBackend === "LRCLIB") {
            root.backend = "LRCLIB";
            fetchLrclib(meta.title, meta.artist, requestId);
            return;
        }
        if (root.preferredBackend === "NetEase") {
            root.backend = "NetEase";
            fetchNetEase(meta.title, meta.artist, requestId);
            return;
        }
        if (root.preferredBackend === "Local") {
            root.backend = "Local";
            _findLocal(meta, requestId);
            return;
        }

        // Auto: try local, with LRCLIB+NetEase candidates queued for fallback.
        root.backend = "Local";
        _findLocal(meta, requestId);
        // Pre-populate candidates so the user can manually pick if auto-match is wrong.
        fetchNetEaseCandidates(meta.title, meta.artist, requestId);
    }

    function _findLocal(meta, requestId) {
        const cleanDir = lyricsDir;
        const flatPath = `${cleanDir}/${meta.artist} - ${meta.title}.lrc`;

        const artistStr = Array.isArray(meta.artist) ? meta.artist.join(", ") : String(meta.artist || "");
        const titleStr = Array.isArray(meta.title) ? meta.title.join(", ") : String(meta.title || "");
        findLyricsInSubdirs.command = ["sh", "-c",
            `find ${_shEsc(cleanDir)} -type f -iname "*${artistStr.replace(/"/g, '\\"')}*${titleStr.replace(/"/g, '\\"')}*.lrc" 2>/dev/null | head -n 1`
        ];
        findLyricsInSubdirs.requestId = requestId;
        findLyricsInSubdirs.foundFile = false;
        findLyricsInSubdirs.running = true;

        // Fast path: try the flat-file location directly. Even if find takes
        // a beat, an exact filename hit lands first.
        lrcFile.path = "";
        lrcFile.path = flatPath;
    }

    function updateModel(parsedArray) {
        root.currentIndex = -1;
        lyricsModel.clear();
        for (const line of parsedArray) {
            lyricsModel.append({ time: line.time, lyricLine: line.text });
        }
    }

    function fallbackToOnline() {
        const meta = getMetadata();
        if (!meta) return;
        // Auto mode: try LRCLIB first, NetEase second.
        root.backend = "LRCLIB";
        fetchLrclib(meta.title, meta.artist, root.currentRequestId);
    }

    // ─── LRCLIB backend ───────────────────────────────────────────────────
    function fetchLrclib(title, artist, reqId) {
        lrclibProc._reqId = reqId;
        lrclibProc._buf = "";
        const url = `https://lrclib.net/api/get?artist_name=${encodeURIComponent(artist)}&track_name=${encodeURIComponent(title)}`;
        lrclibProc.command = ["curl", "-sL", "--max-time", "15", url];
        lrclibProc.running = true;
    }

    Process {
        id: lrclibProc
        property int _reqId: -1
        property string _buf: ""
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { lrclibProc._buf += data; }
        }
        onExited: (code, _) => {
            if (_reqId !== root.currentRequestId) return;
            if (code !== 0 || !_buf) {
                _onLrclibFail();
                return;
            }
            try {
                const res = JSON.parse(_buf);
                // LRCLIB fields: { syncedLyrics, plainLyrics, ... }
                if (res && res.syncedLyrics && res.syncedLyrics.length > 0) {
                    updateModel(Lrc.parseLrc(res.syncedLyrics));
                    root.backend = "LRCLIB";
                    root.loading = false;
                    return;
                }
            } catch (e) {
                // fall through
            }
            _onLrclibFail();
        }

        function _onLrclibFail() {
            // In Auto mode, fall back to NetEase. In LRCLIB-pinned mode, stop.
            if (root.preferredBackend === "Auto") {
                const meta = getMetadata();
                if (meta) {
                    root.backend = "NetEase";
                    fetchNetEase(meta.title, meta.artist, root.currentRequestId);
                    return;
                }
            }
            root.loading = false;
        }
    }

    // ─── NetEase backend ──────────────────────────────────────────────────
    // NetEase has two stages: search → pick best match → fetch lyrics by id.
    function _searchNetEase(title, artist, reqId, onResults) {
        neteaseSearchProc._reqId = reqId;
        neteaseSearchProc._buf = "";
        neteaseSearchProc._onResults = onResults;
        const query = encodeURIComponent(`${title} ${artist}`);
        const url = `https://music.163.com/api/search/get?s=${query}&type=1&limit=5`;
        neteaseSearchProc.command = ["curl", "-sL", "--max-time", "15"]
            .concat(_netEaseHeaders).concat([url]);
        neteaseSearchProc.running = true;
    }

    function fetchNetEaseCandidates(title, artist, reqId) {
        _searchNetEase(title, artist, reqId, _songs => {});
    }

    function fetchNetEase(title, artist, reqId) {
        _searchNetEase(title, artist, reqId, songs => {
            const bestMatch = songs.find(s => {
                const inputArtist = String(artist || "").toLowerCase();
                const sArtist = String(s.artists?.[0]?.name || "").toLowerCase();
                return inputArtist.includes(sArtist) || sArtist.includes(inputArtist);
            });
            if (!bestMatch) {
                root.loading = false;
                return;
            }
            const meta = getMetadata();
            if (meta) {
                const key = _metaKey(meta);
                root.lyricsMap[key] = {
                    offset: root.lyricsMap[key]?.offset ?? 0.0,
                    backend: "NetEase",
                    neteaseId: bestMatch.id
                };
            }
            root.currentSongId = bestMatch.id;
            savePrefs();
            fetchNetEaseLyrics(bestMatch.id, reqId);
        });
    }

    Process {
        id: neteaseSearchProc
        property int _reqId: -1
        property string _buf: ""
        property var _onResults: null
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { neteaseSearchProc._buf += data; }
        }
        onExited: (code, _) => {
            if (_reqId !== root.currentRequestId) return;
            if (code !== 0 || !_buf) {
                if (typeof _onResults === "function") _onResults([]);
                return;
            }
            let songs = [];
            try {
                const res = JSON.parse(_buf);
                songs = res.result?.songs || [];
            } catch (e) {
                // empty
            }
            fetchedCandidatesModel.clear();
            for (const s of songs) {
                fetchedCandidatesModel.append({
                    id: s.id,
                    title: s.name || "Unknown Title",
                    artist: s.artists?.map(a => a.name).join(", ") || "Unknown Artist"
                });
            }
            if (typeof _onResults === "function") _onResults(songs);
        }
    }

    function fetchNetEaseLyrics(id, reqId) {
        neteaseLyricsProc._reqId = reqId;
        neteaseLyricsProc._buf = "";
        const url = `https://music.163.com/api/song/lyric?id=${id}&lv=1&kv=1&tv=-1`;
        neteaseLyricsProc.command = ["curl", "-sL", "--max-time", "15"]
            .concat(_netEaseHeaders).concat([url]);
        neteaseLyricsProc.running = true;
    }

    Process {
        id: neteaseLyricsProc
        property int _reqId: -1
        property string _buf: ""
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { neteaseLyricsProc._buf += data; }
        }
        onExited: (code, _) => {
            if (_reqId !== root.currentRequestId) return;
            if (code !== 0 || !_buf) {
                root.loading = false;
                return;
            }
            try {
                const res = JSON.parse(_buf);
                if (res.lrc?.lyric) {
                    updateModel(Lrc.parseLrc(res.lrc.lyric));
                    root.backend = "NetEase";
                }
            } catch (e) {
                // empty
            }
            root.loading = false;
        }
    }

    // ─── Manual selection / position tracking ─────────────────────────────
    function selectCandidate(songId, source) {
        const meta = getMetadata();
        if (!meta) return;
        // For now NetEase is the only backend with browseable candidates.
        const sourceBackend = source || "NetEase";
        root.backend = sourceBackend;
        root.currentSongId = songId;
        const key = _metaKey(meta);
        root.lyricsMap[key] = {
            offset: root.lyricsMap[key]?.offset ?? 0.0,
            backend: sourceBackend,
            neteaseId: sourceBackend === "NetEase" ? songId : (root.lyricsMap[key]?.neteaseId ?? null)
        };
        savePrefs();
        if (sourceBackend === "NetEase") {
            fetchNetEaseLyrics(songId, currentRequestId);
        }
    }

    function updatePosition() {
        if (isManualSeeking || loading || !player || lyricsModel.count === 0) return;
        const pos = (player.position ?? 0) - root.offset;
        let newIdx = -1;
        for (let i = lyricsModel.count - 1; i >= 0; i--) {
            if (pos >= lyricsModel.get(i).time - 0.1) { newIdx = i; break; }
        }
        if (newIdx !== currentIndex) root.currentIndex = newIdx;
    }

    function jumpTo(index, time) {
        root.isManualSeeking = true;
        root.currentIndex = index;
        // Per Quickshell.Services.Mpris docs, position is only writable
        // when both positionSupported and canSeek are true. Silently no-op
        // otherwise (most players will at least preserve currentIndex).
        if (player && player.positionSupported && player.canSeek) {
            player.position = time + root.offset + 0.01;
        }
        seekTimer.restart();
    }

    // ─── Models ───────────────────────────────────────────────────────────
    ListModel { id: lyricsModel }
    ListModel { id: fetchedCandidatesModel }

    Timer {
        id: seekTimer
        interval: 500
        onTriggered: root.isManualSeeking = false
    }

    // MprisPlayer.position is not reactive by default — it only emits
    // positionChanged on nonlinear changes (seeks). To advance the
    // highlighted line during normal playback, manually emit
    // positionChanged at 1Hz while playing, then bind updatePosition()
    // to it. Pattern from quickshell.org/docs/master/types/.../MprisPlayer.
    Timer {
        id: positionPoll
        running: !!root.player && root.player.playbackState === MprisPlaybackState.Playing
                 && root.lyricsModel.count > 0
        interval: 250  // 4Hz — smooth enough for line-level highlight, light on CPU
        repeat: true
        onTriggered: {
            if (root.player) root.player.positionChanged();
        }
    }
    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onPositionChanged() { root.updatePosition(); }
    }

    // If the local file lookup didn't yield anything within the interval,
    // fall back to the online backends (Auto mode only).
    Timer {
        id: fallbackTimer
        interval: 200
        onTriggered: {
            if (lyricsModel.count === 0 && root.preferredBackend === "Auto") {
                fallbackToOnline();
            }
        }
    }

    Timer {
        id: loadDebounce
        interval: 50
        onTriggered: root._doLoadLyrics()
    }

    // ─── Persistent maps + local LRC reads ────────────────────────────────
    FileView {
        id: lyricsMapFileView
        path: root.lyricsMapFile
        printErrors: false
        onLoaded: {
            try {
                root.lyricsMap = JSON.parse(text());
            } catch (e) {
                root.lyricsMap = {};
            }
        }
    }

    FileView {
        id: lrcFile
        printErrors: false
        onLoaded: {
            fallbackTimer.stop();
            const parsed = Lrc.parseLrc(text());
            if (parsed.length > 0) {
                root.backend = "Local";
                root.loadedLocalFile = path;
                updateModel(parsed);
                root.loading = false;
            } else if (root.preferredBackend === "Local") {
                // Local-pinned: nothing else to do.
                root.loading = false;
            }
            // In Auto mode, the Process onExited / fallbackTimer handle the next step.
        }
    }

    Process {
        id: saveLyricsMap
        running: false
    }

    Process {
        id: findLyricsInSubdirs
        property int requestId: -1
        property bool foundFile: false
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (findLyricsInSubdirs.requestId === root.currentRequestId) {
                    const foundPath = data.trim();
                    if (foundPath && foundPath.length > 0) {
                        findLyricsInSubdirs.foundFile = true;
                        fallbackTimer.stop();
                        root.loadedLocalFile = foundPath;
                        lrcFile.path = "";
                        lrcFile.path = foundPath;
                    }
                }
            }
        }
        onExited: (code, _) => {
            if (requestId === root.currentRequestId && !foundFile && root.preferredBackend === "Auto") {
                if (lyricsModel.count === 0) {
                    fallbackTimer.restart();
                }
            }
            foundFile = false;
        }
    }

    // ─── Track-change wiring ──────────────────────────────────────────────
    Connections {
        target: MprisController
        function onActivePlayerChanged() {
            root.player = MprisController.activePlayer;
            loadLyrics();
        }
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onMetadataChanged() { loadLyrics(); }
    }
}

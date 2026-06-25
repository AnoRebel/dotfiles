import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.layouts
import qs.modules.overview
import "."
/**
 * AnoView — Compositor-agnostic window overview with 10 selectable layouts.
 * Works on both Hyprland (via Hyprland.toplevels) and Niri (via NiriService.windows + ToplevelManager).
 * Supports text filtering, keyboard navigation, random layout mode.
 */
Scope {
    id: anoView

    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: viewLoader
            required property var modelData
            active: GlobalStates.overviewOpen

            component: PanelWindow {
                id: root
                screen: viewLoader.modelData

                // Layout config
                property string layoutAlgorithm: Config.options?.overview?.layout ?? "smartgrid"
                property string lastLayoutAlgorithm: ""
                property bool animateWindows: false
                property var lastPositions: ({})

                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                visible: GlobalStates.overviewOpen

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.exclusiveZone: -1
                WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? 1 : 0
                WlrLayershell.namespace: "quickshell:anoview"

                // Dim background
                Rectangle {
                    anchors.fill: parent
                    color: "#88000000"
                    opacity: GlobalStates.overviewOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Resolve active window address for Hero/Spiral/Satellite layouts
                function getActiveAddress() {
                    if (CompositorService.compositor === "hyprland") {
                        return Hyprland.activeToplevel?.lastIpcObject?.address ?? ""
                    }
                    // Niri: find focused window
                    const focusedWin = NiriService.windows?.find(w => w.is_focused)
                    return focusedWin?.id?.toString() ?? ""
                }

                function toggleView() {
                    if (GlobalStates.overviewOpen) {
                        // Closing
                        GlobalStates.overviewOpen = false
                        root.animateWindows = false
                        root.lastPositions = {}
                    } else {
                        // Opening
                        if (root.layoutAlgorithm === 'random') {
                            var layouts = LayoutsManager.layoutNames.filter(l => l !== root.lastLayoutAlgorithm)
                            root.lastLayoutAlgorithm = layouts[Math.floor(Math.random() * layouts.length)]
                        } else {
                            root.lastLayoutAlgorithm = root.layoutAlgorithm
                        }
                        exposeArea.currentIndex = -1
                        searchBox.reset()
                        GlobalStates.overviewOpen = true
                        refreshThumbs()
                    }
                }

                function refreshThumbs() {
                    if (!GlobalStates.overviewOpen) return
                    for (var i = 0; i < winRepeater.count; ++i) {
                        var it = winRepeater.itemAt(i)
                        if (it?.visible && it.refreshThumb) it.refreshThumb()
                    }
                }

                // Periodically refresh thumbnails
                Timer {
                    interval: 125; repeat: true
                    running: GlobalStates.overviewOpen
                    onTriggered: root.refreshThumbs()
                }

                // Listen for window events to refresh
                Connections {
                    enabled: CompositorService.compositor === "hyprland"
                    target: Hyprland
                    function onRawEvent(ev) {
                        if (!GlobalStates.overviewOpen) return
                        if (["openwindow", "closewindow", "changefloatingmode", "movewindow"].includes(ev.name)) {
                            Hyprland.refreshToplevels()
                            root.refreshThumbs()
                        }
                    }
                }

                // Activate a window (compositor-agnostic)
                function activateWindow(toplevel, clientInfo) {
                    GlobalStates.overviewOpen = false
                    root.animateWindows = false
                    root.lastPositions = {}

                    if (CompositorService.compositor === "hyprland") {
                        const addr = toplevel?.address ?? clientInfo?.address ?? ""
                        if (addr) {
                            Hyprland.dispatch("focuswindow address:0x" + addr)
                            Hyprland.dispatch("alterzorder top")
                        }
                    } else if (CompositorService.compositor === "niri") {
                        const winId = toplevel?.id ?? clientInfo?.id
                        if (winId !== undefined) NiriService.focusWindow(winId)
                    }
                }

                function closeWindow(toplevel) {
                    if (CompositorService.compositor === "hyprland") {
                        const addr = toplevel?.address ?? ""
                        if (addr) Hyprland.dispatch("closewindow address:0x" + addr)
                    } else if (CompositorService.compositor === "niri") {
                        const winId = toplevel?.id
                        if (winId !== undefined) NiriService.closeWindow(winId)
                    }
                }

                // Build window list (compositor-agnostic)
                function buildWindowList(query) {
                    var q = (query || "").toLowerCase()
                    var windowList = []

                    if (CompositorService.compositor === "hyprland") {
                        var toplevels = Hyprland.toplevels?.values ?? []
                        for (var it of toplevels) {
                            var ci = it?.lastIpcObject ?? {}
                            var ws = ci?.workspace; var wsId = ws?.id
                            if (wsId === undefined || wsId === null) continue
                            var size = ci?.size ?? [0, 0]; var at = ci?.at ?? [-1000, -1000]
                            if (at[1] + size[1] <= 0) continue

                            var title = (it.title || ci.title || "").toLowerCase()
                            var clazz = (ci["class"] || "").toLowerCase()
                            var app = (it.appId || ci.initialClass || "").toLowerCase()
                            if (q.length > 0 && title.indexOf(q) === -1 && clazz.indexOf(q) === -1 && app.indexOf(q) === -1) continue

                            windowList.push({
                                win: it, clientInfo: ci, workspaceId: wsId,
                                width: size[0], height: size[1],
                                lastIpcObject: ci, address: ci.address
                            })
                        }
                    } else if (CompositorService.compositor === "niri") {
                        var niriWindows = NiriService.windows ?? []
                        var toplevelsMap = {}
                        for (var tl of ToplevelManager.toplevels.values) {
                            toplevelsMap[tl.appId] = tl
                        }
                        for (var nw of niriWindows) {
                            var nTitle = (nw.title || "").toLowerCase()
                            var nApp = (nw.app_id || "").toLowerCase()
                            if (q.length > 0 && nTitle.indexOf(q) === -1 && nApp.indexOf(q) === -1) continue

                            var tl2 = toplevelsMap[nw.app_id]
                            windowList.push({
                                win: tl2 ?? nw, clientInfo: nw, workspaceId: nw.workspace_id ?? 0,
                                width: nw.width ?? 800, height: nw.height ?? 600,
                                lastIpcObject: nw, address: nw.id?.toString() ?? "",
                                id: nw.id
                            })
                        }
                    }

                    windowList.sort((a, b) => {
                        if (a.workspaceId < b.workspaceId) return -1
                        if (a.workspaceId > b.workspaceId) return 1
                        return 0
                    })
                    return windowList
                }

                // Main UI
                FocusScope {
                    anchors.fill: parent; focus: true

                    Keys.onPressed: event => {
                        if (!GlobalStates.overviewOpen) return
                        if (event.key === Qt.Key_Escape) { root.toggleView(); event.accepted = true; return }
                        const total = winRepeater.count; if (total <= 0) return

                        function moveH(delta) {
                            for (var s = 1; s <= total; ++s) {
                                var c = (exposeArea.currentIndex + delta * s + total) % total
                                var it = winRepeater.itemAt(c); if (it?.visible) { exposeArea.currentIndex = c; return }
                            }
                        }
                        function moveV(dir) {
                            var cur = winRepeater.itemAt(exposeArea.currentIndex)
                            if (!cur?.visible) { moveH(dir > 0 ? 1 : -1); return }
                            var cx = cur.x + cur.width / 2, cy = cur.y + cur.height / 2
                            var bestIdx = -1, bestDy = 99999999, bestDx = 99999999
                            for (var i = 0; i < total; ++i) {
                                var it = winRepeater.itemAt(i)
                                if (!it?.visible || i === exposeArea.currentIndex) continue
                                var dy = (it.y + it.height / 2) - cy
                                if (dir > 0 && dy <= 0) continue; if (dir < 0 && dy >= 0) continue
                                var absDy = Math.abs(dy), absDx = Math.abs((it.x + it.width / 2) - cx)
                                if (absDy < bestDy || (absDy === bestDy && absDx < bestDx)) { bestDy = absDy; bestDx = absDx; bestIdx = i }
                            }
                            if (bestIdx >= 0) exposeArea.currentIndex = bestIdx
                        }

                        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) { moveH(1); event.accepted = true }
                        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) { moveH(-1); event.accepted = true }
                        else if (event.key === Qt.Key_Down) { moveV(1); event.accepted = true }
                        else if (event.key === Qt.Key_Up) { moveV(-1); event.accepted = true }
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            var item = winRepeater.itemAt(exposeArea.currentIndex)
                            if (item) { root.activateWindow(item.hWin, item.clientInfo); event.accepted = true }
                        }
                    }

                    MouseArea { anchors.fill: parent; hoverEnabled: false; z: -1; onClicked: root.toggleView() }

                    Item {
                        anchors.fill: parent; anchors.margins: 32

                        Column {
                            id: layoutRoot
                            anchors.fill: parent; anchors.margins: 48; spacing: 20

                            Item {
                                id: exposeArea
                                width: layoutRoot.width
                                height: layoutRoot.height - searchBox.implicitHeight - layoutRoot.spacing
                                property int currentIndex: 0
                                property string searchText: ""
                                onSearchTextChanged: currentIndex = (windowLayoutModel.count > 0) ? 0 : -1

                                ScriptModel {
                                    id: windowLayoutModel
                                    property int areaW: exposeArea.width
                                    property int areaH: exposeArea.height
                                    property string query: exposeArea.searchText
                                    property string algo: root.lastLayoutAlgorithm
                                    // Depend on toplevel changes
                                    property var _dep1: CompositorService.compositor === "hyprland" ? Hyprland.toplevels?.values : null
                                    property var _dep2: CompositorService.compositor === "niri" ? NiriService.windows : null

                                    values: {
                                        if (areaW <= 0 || areaH <= 0) return []
                                        var wl = root.buildWindowList(query)
                                        return LayoutsManager.doLayout(algo, wl, areaW, areaH, root.getActiveAddress())
                                    }
                                }

                                Repeater {
                                    id: winRepeater
                                    model: windowLayoutModel

                                    delegate: WindowThumbnail {
                                        hWin: modelData.win
                                        wHandle: hWin?.wayland ?? null
                                        winKey: String(modelData.address ?? modelData.win?.address ?? index)
                                        thumbW: modelData.width
                                        thumbH: modelData.height
                                        clientInfo: modelData.clientInfo ?? hWin?.lastIpcObject ?? ({})
                                        targetX: modelData.x
                                        targetY: modelData.y
                                        targetZ: (visible && exposeArea.currentIndex === index) ? 1000 : (modelData.zIndex || 0)
                                        targetRotation: modelData.rotation || 0
                                        hovered: visible && (exposeArea.currentIndex === index)
                                        animateWindows: root.animateWindows
                                        lastPositions: root.lastPositions

                                        onActivated: root.activateWindow(hWin, clientInfo)
                                        onClosed: root.closeWindow(hWin)
                                    }
                                }
                            }

                            SearchBox {
                                id: searchBox
                                onTextChanged: text => { root.animateWindows = true; exposeArea.searchText = text }
                            }
                        }
                    }
                }
            }
        }
    }

    // IPC
    IpcHandler {
        target: "anoview"
        function toggle(layout: string): void {
            if (layout) Config.options.overview.layout = layout
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
        function open(layout: string): void {
            if (layout) Config.options.overview.layout = layout
            GlobalStates.overviewOpen = true
        }
        function close(): void { GlobalStates.overviewOpen = false }
    }

    // Also respond to the generic overviewWorkspacesToggle IPC from companion configs
    IpcHandler {
        target: "overviewWorkspacesToggle"
        function invoke(): void { GlobalStates.overviewOpen = !GlobalStates.overviewOpen }
    }

    // GlobalShortcuts (Hyprland only)
    Loader {
        active: CompositorService.compositor === "hyprland"
        sourceComponent: Item {
            GlobalShortcut { name: "overviewToggle"; description: "Toggle AnoView"; onPressed: GlobalStates.overviewOpen = !GlobalStates.overviewOpen }
        }
    }
}

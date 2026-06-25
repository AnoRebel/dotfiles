import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Alt-Tab window switcher with live thumbnails.
 * Supports MRU (most-recently-used) ordering, keyboard navigation (Tab/Shift+Tab),
 * window previews via ScreencopyView, configurable styles (list/grid/compact),
 * and search filtering. Compositor-agnostic.
 *
 * Inspired by inir AltSwitcher with simplification for ano.
 */
Scope {
    id: root

    // Config
    readonly property var opts: Config.options?.altSwitcher ?? ({})
    readonly property bool enableAnimation: opts.enableAnimation ?? true
    readonly property int animDurationMs: opts.animationDurationMs ?? 200
    readonly property bool useMRU: opts.useMostRecentFirst ?? true
    readonly property real backgroundOpacity: opts.backgroundOpacity ?? 0.85
    readonly property int scrimDim: opts.scrimDim ?? 40
    readonly property string panelAlignment: opts.panelAlignment ?? "center"
    readonly property bool compactStyle: opts.compactStyle ?? false
    readonly property int itemSize: compactStyle ? 48 : 72
    readonly property int panelWidth: compactStyle ? 400 : 500
    readonly property int maxVisible: opts.maxVisible ?? 12

    // State
    property bool panelVisible: false
    property var windowSnapshot: []
    property int selectedIndex: 0
    property string searchText: ""

    readonly property var filteredWindows: {
        if (searchText.length === 0) return windowSnapshot
        const q = searchText.toLowerCase()
        return windowSnapshot.filter(w => {
            const title = (w.title ?? "").toLowerCase()
            const appId = (w.appId ?? "").toLowerCase()
            return title.includes(q) || appId.includes(q)
        })
    }

    function buildSnapshot() {
        const toplevels = ToplevelManager.toplevels.values
        let windows = toplevels.map(tl => ({
            toplevel: tl,
            title: tl.title ?? "",
            appId: tl.appId ?? "",
            activated: tl.activated,
            wayland: tl.wayland ?? null,
        }))
        // MRU: activated window first
        if (useMRU) {
            windows.sort((a, b) => {
                if (a.activated && !b.activated) return -1
                if (!a.activated && b.activated) return 1
                return 0
            })
        }
        return windows.slice(0, maxVisible)
    }

    function show() {
        windowSnapshot = buildSnapshot()
        if (windowSnapshot.length === 0) return
        selectedIndex = Math.min(1, windowSnapshot.length - 1) // Start at second item (first is current)
        searchText = ""
        panelVisible = true
    }

    function hide() {
        panelVisible = false
    }

    function activateSelected() {
        const windows = filteredWindows
        if (selectedIndex < 0 || selectedIndex >= windows.length) { hide(); return }
        const win = windows[selectedIndex]
        if (win.toplevel) {
            win.toplevel.activated = true
            if (CompositorService.compositor === "hyprland") {
                const addr = win.toplevel.HyprlandToplevel?.address ?? ""
                if (addr) Quickshell.execDetached(["hyprctl", "dispatch", `focuswindow address:0x${addr}`])
            } else if (CompositorService.compositor === "niri") {
                NiriService.focusWindowByAppId(win.appId)
            }
        }
        hide()
    }

    function cycleNext() {
        const total = filteredWindows.length
        if (total <= 0) return
        selectedIndex = (selectedIndex + 1) % total
    }

    function cyclePrev() {
        const total = filteredWindows.length
        if (total <= 0) return
        selectedIndex = (selectedIndex - 1 + total) % total
    }

    // IPC
    IpcHandler {
        target: "altSwitcher"
        function show(): void { root.show() }
        function hide(): void { root.hide() }
        function next(): void { if (!root.panelVisible) root.show(); else root.cycleNext() }
        function prev(): void { if (!root.panelVisible) root.show(); else root.cyclePrev() }
        function activate(): void { root.activateSelected() }
    }

    PanelWindow {
        id: switcherWindow
        visible: root.panelVisible
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:altSwitcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.panelVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) { root.hide(); event.accepted = true; return }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.activateSelected(); event.accepted = true; return }
            if (event.key === Qt.Key_Tab) {
                if (event.modifiers & Qt.ShiftModifier) root.cyclePrev()
                else root.cycleNext()
                event.accepted = true; return
            }
            if (event.key === Qt.Key_Up) { root.cyclePrev(); event.accepted = true; return }
            if (event.key === Qt.Key_Down) { root.cycleNext(); event.accepted = true; return }
            // Type to search
            if (event.text.length === 1 && event.text.match(/[a-zA-Z0-9 ]/)) {
                root.searchText += event.text
                root.selectedIndex = 0
                event.accepted = true
            }
            if (event.key === Qt.Key_Backspace && root.searchText.length > 0) {
                root.searchText = root.searchText.substring(0, root.searchText.length - 1)
                root.selectedIndex = 0
                event.accepted = true
            }
        }

        // Scrim
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, root.scrimDim / 100)
            opacity: root.panelVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: root.animDurationMs } }
            MouseArea { anchors.fill: parent; onClicked: root.hide() }
        }

        // Switcher panel
        Rectangle {
            id: switcherPanel
            anchors.centerIn: parent
            width: root.panelWidth
            height: Math.min(panelContent.implicitHeight + 32, switcherWindow.height * 0.7)
            radius: Appearance?.rounding.windowRounding ?? 20
            color: Qt.rgba((Appearance?.colors.colLayer0 ?? "#1C1B1F").r, (Appearance?.colors.colLayer0 ?? "#1C1B1F").g, (Appearance?.colors.colLayer0 ?? "#1C1B1F").b, root.backgroundOpacity)
            border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
            clip: true

            opacity: root.panelVisible ? 1 : 0
            scale: root.panelVisible ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: root.animDurationMs; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: root.animDurationMs; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: panelContent
                anchors { fill: parent; margins: 16 }
                spacing: 8

                // Search indicator (only when typing)
                Loader {
                    Layout.fillWidth: true
                    active: root.searchText.length > 0
                    visible: active
                    sourceComponent: Rectangle {
                        implicitHeight: 32; radius: 16
                        color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 6
                            MaterialSymbol { text: "search"; iconSize: 16; opacity: 0.5 }
                            StyledText { text: root.searchText; font.pixelSize: 14; Layout.fillWidth: true }
                        }
                    }
                }

                // Window list
                StyledFlickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: windowColumn.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: windowColumn
                        width: parent.width; spacing: 4

                        Repeater {
                            model: root.filteredWindows

                            Rectangle {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: windowRow.implicitHeight + 12
                                radius: Appearance?.rounding.small ?? 8

                                property bool isSelected: root.selectedIndex === index

                                color: isSelected
                                    ? Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.2)
                                    : itemMA.containsMouse
                                        ? Appearance?.colors.colLayer1Hover ?? "#E5DFED"
                                        : "transparent"
                                border.width: isSelected ? 2 : 0
                                border.color: Appearance?.colors.colPrimary ?? "#65558F"

                                Behavior on color { ColorAnimation { duration: 100 } }

                                RowLayout {
                                    id: windowRow
                                    anchors { fill: parent; margins: 6 }
                                    spacing: 10

                                    // App icon
                                    Rectangle {
                                        width: root.itemSize; height: root.itemSize
                                        radius: Appearance?.rounding.small ?? 8
                                        color: Appearance?.colors.colLayer2 ?? "#2B2930"
                                        clip: true

                                        // Live thumbnail
                                        Loader {
                                            anchors.fill: parent
                                            active: !!modelData.wayland
                                            sourceComponent: ScreencopyView {
                                                anchors.fill: parent
                                                captureSource: modelData.wayland
                                                live: false; paintCursor: false
                                            }
                                        }

                                        // Fallback icon
                                        IconImage {
                                            anchors.centerIn: parent
                                            implicitWidth: root.itemSize * 0.6
                                            implicitHeight: root.itemSize * 0.6
                                            source: `image://icon/${modelData.appId}`
                                            visible: !modelData.wayland
                                        }
                                    }

                                    // Title + app info
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        StyledText {
                                            text: modelData.title || modelData.appId || "Unknown"
                                            font.pixelSize: root.compactStyle ? 13 : 15
                                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight; Layout.fillWidth: true
                                            color: isSelected ? Appearance?.colors.colPrimary ?? "#65558F" : Appearance?.m3colors.m3onBackground ?? "#E6E1E5"
                                        }
                                        StyledText {
                                            text: modelData.appId ?? ""
                                            font.pixelSize: 11; opacity: 0.4
                                            visible: !root.compactStyle && modelData.title !== modelData.appId
                                            elide: Text.ElideRight; Layout.fillWidth: true
                                        }
                                    }

                                    // Active indicator
                                    Rectangle {
                                        visible: modelData.activated
                                        width: 8; height: 8; radius: 4
                                        color: "#81C784"
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: itemMA
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.selectedIndex = index; root.activateSelected() }
                                    onEntered: root.selectedIndex = index
                                }
                            }
                        }
                    }
                }

                // Footer hint
                StyledText {
                    text: `${root.filteredWindows.length} window${root.filteredWindows.length !== 1 ? "s" : ""} • Tab/↑↓ to navigate • Enter to activate • Type to filter`
                    font.pixelSize: 10; opacity: 0.3
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}

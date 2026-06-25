import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * App launcher & search overlay. Searches .desktop applications
 * via DesktopEntries, supports keyboard navigation, fuzzy matching,
 * recent apps tracking, and calculator (via qalc if installed).
 *
 * Opens centered, focuses search input immediately. Escape to close.
 */
Scope {
    id: root
    property string query: ""
    property int selectedIndex: 0

    readonly property var allApps: DesktopEntries.applications.values
    readonly property var filteredApps: {
        if (query.length === 0) {
            // Show recent apps, then alphabetical
            const recents = (Config.options?.search?.recentApps ?? []).map(id => allApps.find(a => a.id === id)).filter(a => !!a)
            const rest = allApps.filter(a => !(Config.options?.search?.recentApps ?? []).includes(a.id)).sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""))
            return [...recents, ...rest].slice(0, 50)
        }
        const q = query.toLowerCase()
        return allApps.filter(app => {
            const name = (app.name ?? "").toLowerCase()
            const desc = (app.comment ?? "").toLowerCase()
            const exec = (app.exec ?? "").toLowerCase()
            const id = (app.id ?? "").toLowerCase()
            return name.includes(q) || desc.includes(q) || exec.includes(q) || id.includes(q)
        }).sort((a, b) => {
            // Exact prefix match first
            const aName = (a.name ?? "").toLowerCase()
            const bName = (b.name ?? "").toLowerCase()
            const aStarts = aName.startsWith(q) ? 0 : 1
            const bStarts = bName.startsWith(q) ? 0 : 1
            if (aStarts !== bStarts) return aStarts - bStarts
            return aName.localeCompare(bName)
        }).slice(0, 30)
    }

    // Calculator
    property string calcResult: ""
    readonly property bool isCalcQuery: /^[\d+\-*/().% ^sqrtpi,e]+$/.test(query) && query.length > 1

    function launch(app) {
        if (app) {
            app.launch()
            // Track in recents
            const recents = [...(Config.options?.search?.recentApps ?? [])]
            const idx = recents.indexOf(app.id)
            if (idx >= 0) recents.splice(idx, 1)
            recents.unshift(app.id)
            Config.setNestedValue("search.recentApps", recents.slice(0, 10))
        }
        GlobalStates.searchOpen = false
        query = ""
    }

    Connections {
        target: GlobalStates
        function onSearchOpenChanged() {
            if (GlobalStates.searchOpen) { root.query = ""; root.selectedIndex = 0; root.calcResult = "" }
        }
    }

    IpcHandler {
        target: "search"
        function toggle(): void { GlobalStates.searchOpen = !GlobalStates.searchOpen }
        function open(): void { GlobalStates.searchOpen = true }
        function close(): void { GlobalStates.searchOpen = false }
    }

    PanelWindow {
        id: searchWindow
        visible: GlobalStates.searchOpen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:search"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.searchOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) { GlobalStates.searchOpen = false; event.accepted = true; return }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.filteredApps.length > 0 && root.selectedIndex < root.filteredApps.length)
                    root.launch(root.filteredApps[root.selectedIndex])
                event.accepted = true; return
            }
            if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                root.selectedIndex = Math.min(root.selectedIndex + 1, root.filteredApps.length - 1)
                event.accepted = true
            }
            if (event.key === Qt.Key_Up || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                event.accepted = true
            }
        }

        // Scrim
        Rectangle {
            anchors.fill: parent; color: "#000000"
            opacity: GlobalStates.searchOpen ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MouseArea { anchors.fill: parent; onClicked: GlobalStates.searchOpen = false }
        }

        // Search card — positioned in upper third of screen
        Rectangle {
            id: searchCard
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.15
            width: Math.min(560, parent.width * 0.65)
            height: Math.min(searchContent.implicitHeight + 32, parent.height * 0.65)
            radius: Appearance?.rounding.windowRounding ?? 20
            color: Appearance?.m3colors.m3background ?? "#1C1B1F"
            border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
            clip: true

            opacity: GlobalStates.searchOpen ? 1 : 0
            scale: GlobalStates.searchOpen ? 1 : 0.92
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: searchContent
                anchors { fill: parent; margins: 16 }
                spacing: 12

                // Search input
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 48; radius: 24
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                    RowLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                        spacing: 10
                        MaterialSymbol { text: "search"; iconSize: 24; color: Appearance?.colors.colPrimary ?? "#65558F" }
                        StyledTextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: 16
                            focus: GlobalStates.searchOpen
                            onTextChanged: { root.query = text; root.selectedIndex = 0 }

                            StyledText {
                                anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                text: "Search apps..."; opacity: 0.3; font.pixelSize: 16
                                visible: !searchInput.text || searchInput.text.length === 0
                            }
                        }
                        ToolbarButton {
                            iconName: "close"; iconSize: 18
                            visible: root.query.length > 0
                            onClicked: { searchInput.text = "" }
                        }
                    }
                }

                // Calculator result
                Loader {
                    Layout.fillWidth: true
                    active: root.isCalcQuery && root.calcResult.length > 0
                    visible: active
                    sourceComponent: Rectangle {
                        implicitHeight: calcRow.implicitHeight + 12; radius: Appearance?.rounding.small ?? 8
                        color: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
                        RowLayout {
                            id: calcRow; anchors { fill: parent; margins: 6 }
                            spacing: 8
                            MaterialSymbol { text: "calculate"; iconSize: 20; color: Appearance?.m3colors.m3onSecondaryContainer ?? "#1D1B20" }
                            StyledText {
                                text: `= ${root.calcResult}`
                                font.pixelSize: 18; font.weight: Font.Bold; font.family: Appearance?.font.family.mono ?? "monospace"
                                color: Appearance?.m3colors.m3onSecondaryContainer ?? "#1D1B20"
                                Layout.fillWidth: true
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { Quickshell.clipboardText = root.calcResult }
                            StyledToolTip { text: "Click to copy" }
                        }
                    }
                }

                // Calculator process
                Process {
                    id: calcProcess
                    running: false
                    command: ["qalc", "-t", root.query]
                    stdout: StdioCollector {
                        id: calcCollector
                        onStreamFinished: root.calcResult = calcCollector.text.trim()
                    }
                }
                Connections {
                    target: root
                    function onIsCalcQueryChanged() {
                        if (root.isCalcQuery) calcProcess.running = true
                        else root.calcResult = ""
                    }
                }

                // App list
                StyledFlickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.min(appColumn.implicitHeight, 400)
                    contentHeight: appColumn.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: appColumn
                        width: parent.width; spacing: 2

                        // Section header for recents
                        StyledText {
                            visible: root.query.length === 0 && (Config.options?.search?.recentApps ?? []).length > 0
                            text: "Recent"
                            font.pixelSize: 11; opacity: 0.4; font.weight: Font.DemiBold
                            Layout.fillWidth: true; Layout.topMargin: 4
                        }

                        Repeater {
                            model: root.filteredApps

                            Rectangle {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 44
                                radius: Appearance?.rounding.small ?? 8

                                property bool isSelected: root.selectedIndex === index
                                color: isSelected
                                    ? Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.15)
                                    : appItemMA.containsMouse ? Appearance?.colors.colLayer1Hover ?? "#E5DFED" : "transparent"
                                border.width: isSelected ? 1 : 0
                                border.color: Appearance?.colors.colPrimary ?? "#65558F"

                                RowLayout {
                                    anchors { fill: parent; margins: 6 }
                                    spacing: 10
                                    IconImage {
                                        implicitWidth: 32; implicitHeight: 32
                                        source: modelData.icon ? `image://icon/${modelData.icon}` : `image://icon/${modelData.id}`
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 0
                                        StyledText {
                                            text: modelData.name ?? modelData.id ?? ""
                                            font.pixelSize: 14
                                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight; Layout.fillWidth: true
                                        }
                                        StyledText {
                                            text: modelData.comment ?? ""
                                            font.pixelSize: 11; opacity: 0.4
                                            elide: Text.ElideRight; Layout.fillWidth: true
                                            visible: (modelData.comment ?? "").length > 0
                                        }
                                    }
                                }

                                MouseArea {
                                    id: appItemMA
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launch(modelData)
                                    onEntered: root.selectedIndex = index
                                }
                            }
                        }

                        StyledText {
                            visible: root.filteredApps.length === 0
                            text: root.query.length > 0 ? "No apps found" : "No applications"
                            font.pixelSize: 14; opacity: 0.4
                            Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 20
                        }
                    }
                }

                // Footer
                StyledText {
                    text: "↑↓ Navigate • Enter to launch • Esc to close"
                    font.pixelSize: 10; opacity: 0.3
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}

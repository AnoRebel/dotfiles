import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Keybind cheatsheet overlay. Reads keybinds from HyprlandKeybinds (Hyprland)
 * or NiriKeybinds (Niri) and displays them in a searchable, categorized grid.
 * Each category is a collapsible section with key combinations styled as keyboard keys.
 */
Scope {
    id: root
    property bool cheatsheetOpen: false
    property string searchQuery: ""

    function toggle() { cheatsheetOpen = !cheatsheetOpen }
    function open() { cheatsheetOpen = true }
    function close() { cheatsheetOpen = false; searchQuery = "" }

    readonly property var keybindData: {
        if (CompositorService.compositor === "hyprland") return HyprlandKeybinds.keybinds
        if (CompositorService.compositor === "niri") return NiriKeybinds.keybinds
        return { children: [] }
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    PanelWindow {
        id: csWindow
        visible: root.cheatsheetOpen

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:cheatsheet"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.cheatsheetOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }

        Keys.onPressed: event => { if (event.key === Qt.Key_Escape) root.close() }

        // Scrim
        Rectangle {
            anchors.fill: parent; color: "#000000"
            opacity: root.cheatsheetOpen ? 0.6 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        // Card
        Rectangle {
            id: csCard
            anchors.centerIn: parent
            width: Math.min(900, parent.width * 0.85)
            height: Math.min(700, parent.height * 0.85)
            radius: Appearance?.rounding.windowRounding ?? 20
            color: Appearance?.m3colors.m3background ?? "#1C1B1F"
            border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
            clip: true

            opacity: root.cheatsheetOpen ? 1 : 0
            scale: root.cheatsheetOpen ? 1 : 0.92
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors { fill: parent; margins: 20 }
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    MaterialSymbol { text: "keyboard"; iconSize: 28; color: Appearance?.colors.colPrimary ?? "#65558F" }
                    StyledText { text: "Keyboard Shortcuts"; font.pixelSize: Appearance?.font.pixelSize.huger ?? 22; font.weight: Font.Bold; Layout.fillWidth: true }
                    StyledText { text: CompositorService.compositor; font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12; opacity: 0.4 }
                    ToolbarButton { iconName: "close"; iconSize: 22; onClicked: root.close() }
                }

                // Search bar
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 40; radius: 20
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 8
                        MaterialSymbol { text: "search"; iconSize: 20; opacity: 0.5 }
                        StyledTextInput {
                            id: csSearch
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: 14
                            focus: root.cheatsheetOpen
                            text: root.searchQuery
                            onTextChanged: root.searchQuery = text

                            StyledText {
                                anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                text: "Search keybinds..."; opacity: 0.4; font.pixelSize: 14
                                visible: !csSearch.text || csSearch.text.length === 0
                            }
                        }
                        ToolbarButton {
                            iconName: "close"; iconSize: 16
                            visible: root.searchQuery.length > 0
                            onClicked: { root.searchQuery = ""; csSearch.text = "" }
                        }
                    }
                }

                // Keybind sections
                StyledFlickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: sectionColumn.implicitHeight; clip: true

                    ColumnLayout {
                        id: sectionColumn
                        width: parent.width; spacing: 16

                        // Empty state
                        ColumnLayout {
                            visible: keybindData.children.length === 0
                            Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 60; spacing: 8
                            MaterialSymbol { text: "info"; iconSize: 48; opacity: 0.3; Layout.alignment: Qt.AlignHCenter }
                            StyledText { text: "No keybinds loaded"; font.pixelSize: 16; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
                            StyledText { text: "Keybinds are loaded from your compositor config"; font.pixelSize: 13; opacity: 0.3; Layout.alignment: Qt.AlignHCenter }
                        }

                        Repeater {
                            model: keybindData.children ?? []

                            ColumnLayout {
                                id: sectionDelegate
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true; spacing: 6

                                property string sectionName: modelData.name ?? `Section ${index + 1}`
                                property var binds: modelData.children ?? []
                                property var filteredBinds: root.searchQuery.length === 0
                                    ? binds
                                    : binds.filter(b => {
                                        const q = root.searchQuery.toLowerCase()
                                        return (b.keys ?? "").toLowerCase().includes(q)
                                            || (b.action ?? "").toLowerCase().includes(q)
                                            || (b.description ?? "").toLowerCase().includes(q)
                                    })

                                visible: filteredBinds.length > 0

                                property bool expanded: true

                                // Section header
                                MouseArea {
                                    Layout.fillWidth: true
                                    implicitHeight: sectionHeaderRow.implicitHeight + 8
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: sectionDelegate.expanded = !sectionDelegate.expanded

                                    RowLayout {
                                        id: sectionHeaderRow
                                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                        spacing: 8
                                        Rectangle { width: 4; height: 18; radius: 2; color: Appearance?.colors.colPrimary ?? "#65558F" }
                                        StyledText {
                                            text: sectionDelegate.sectionName
                                            font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                                            font.weight: Font.DemiBold
                                            color: Appearance?.colors.colPrimary ?? "#65558F"
                                            Layout.fillWidth: true
                                        }
                                        StyledText {
                                            text: `${sectionDelegate.filteredBinds.length}`
                                            font.pixelSize: 11; opacity: 0.4
                                        }
                                        MaterialSymbol {
                                            text: sectionDelegate.expanded ? "expand_less" : "expand_more"
                                            iconSize: 20; opacity: 0.5
                                        }
                                    }
                                }

                                // Keybind rows
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 3
                                    visible: sectionDelegate.expanded
                                    Layout.leftMargin: 12

                                    Repeater {
                                        model: sectionDelegate.filteredBinds

                                        Rectangle {
                                            required property var modelData
                                            required property int index
                                            Layout.fillWidth: true
                                            implicitHeight: bindRow.implicitHeight + 8
                                            radius: Appearance?.rounding.verysmall ?? 4
                                            color: index % 2 === 0 ? Qt.rgba(1, 1, 1, 0.02) : "transparent"

                                            RowLayout {
                                                id: bindRow
                                                anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 4; bottomMargin: 4 }
                                                spacing: 12

                                                // Key combination pills
                                                RowLayout {
                                                    spacing: 4
                                                    Layout.preferredWidth: 200
                                                    Layout.alignment: Qt.AlignVCenter

                                                    Repeater {
                                                        model: (modelData.keys ?? "").split("+")

                                                        KeyboardKey {
                                                            required property string modelData
                                                            keyText: modelData
                                                        }
                                                    }
                                                }

                                                // Description / action
                                                StyledText {
                                                    text: modelData.description || modelData.action || ""
                                                    font.pixelSize: Appearance?.font.pixelSize.small ?? 13
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                    opacity: 0.8
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

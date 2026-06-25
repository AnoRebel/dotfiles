import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

/**
 * Clipboard manager overlay — browse clipboard history from cliphist,
 * search/filter entries, click to paste, right-click to copy without paste,
 * view images inline, clear all, and pin entries.
 * Text and image entries are shown with different styling.
 */
Scope {
    id: root
    property string searchQuery: ""

    readonly property var filteredEntries: {
        if (searchQuery.length === 0) return Cliphist.entries
        const q = searchQuery.toLowerCase()
        return Cliphist.entries.filter(entry => {
            const text = entry.split("\t").slice(1).join("\t").toLowerCase()
            return text.includes(q)
        })
    }

    Component.onCompleted: Cliphist.refresh()

    Connections {
        target: GlobalStates
        function onClipboardOpenChanged() {
            if (GlobalStates.clipboardOpen) { root.searchQuery = ""; Cliphist.refresh() }
        }
    }

    PanelWindow {
        id: clipWindow
        visible: GlobalStates.clipboardOpen

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:clipboard"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.clipboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }

        Keys.onPressed: event => { if (event.key === Qt.Key_Escape) GlobalStates.clipboardOpen = false }

        // Scrim
        Rectangle {
            anchors.fill: parent; color: "#000000"
            opacity: GlobalStates.clipboardOpen ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MouseArea { anchors.fill: parent; onClicked: GlobalStates.clipboardOpen = false }
        }

        // Card
        Rectangle {
            id: clipCard
            anchors.centerIn: parent
            width: Math.min(600, parent.width * 0.7)
            height: Math.min(650, parent.height * 0.8)
            radius: Appearance?.rounding.windowRounding ?? 20
            color: Appearance?.m3colors.m3background ?? "#1C1B1F"
            border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
            clip: true

            opacity: GlobalStates.clipboardOpen ? 1 : 0
            scale: GlobalStates.clipboardOpen ? 1 : 0.92
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors { fill: parent; margins: 16 }
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    MaterialSymbol { text: "content_paste"; iconSize: 24; color: Appearance?.colors.colPrimary ?? "#65558F" }
                    StyledText { text: "Clipboard"; font.pixelSize: Appearance?.font.pixelSize.huger ?? 22; font.weight: Font.Bold; Layout.fillWidth: true }
                    StyledText { text: `${Cliphist.entries.length} items`; font.pixelSize: 12; opacity: 0.4 }

                    // Superpaste
                    RippleButtonWithIcon {
                        iconName: "content_paste_go"
                        buttonText: "Superpaste"
                        buttonRadius: Appearance?.rounding.full ?? 9999
                        onClicked: { Cliphist.superpaste(5); GlobalStates.clipboardOpen = false }
                        StyledToolTip { text: "Paste last 5 items rapidly" }
                    }

                    // Clear all
                    ToolbarButton {
                        iconName: "delete_sweep"; iconSize: 20
                        toolTipText: "Clear all history"
                        onClicked: Cliphist.wipe()
                    }

                    ToolbarButton { iconName: "close"; iconSize: 20; onClicked: GlobalStates.clipboardOpen = false }
                }

                // Search
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 40; radius: 20
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 8
                        MaterialSymbol { text: "search"; iconSize: 20; opacity: 0.5 }
                        StyledTextInput {
                            id: clipSearch
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: 14; focus: GlobalStates.clipboardOpen
                            onTextChanged: root.searchQuery = text
                            StyledText {
                                anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                text: "Search clipboard..."; opacity: 0.4; font.pixelSize: 14
                                visible: !clipSearch.text || clipSearch.text.length === 0
                            }
                        }
                        ToolbarButton { iconName: "close"; iconSize: 16; visible: root.searchQuery.length > 0; onClicked: clipSearch.text = "" }
                    }
                }

                // Entry list
                StyledFlickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: entryColumn.implicitHeight; clip: true

                    ColumnLayout {
                        id: entryColumn
                        width: parent.width; spacing: 4

                        StyledText {
                            visible: root.filteredEntries.length === 0
                            text: root.searchQuery.length > 0 ? "No matching entries" : "Clipboard is empty"
                            font.pixelSize: 14; opacity: 0.4
                            Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 40
                        }

                        Repeater {
                            model: root.filteredEntries

                            Rectangle {
                                required property string modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: entryContent.implicitHeight + 12
                                radius: Appearance?.rounding.small ?? 8
                                color: entryMA.containsMouse ? Appearance?.colors.colLayer1Hover ?? "#E5DFED" : (index % 2 === 0 ? Qt.rgba(1,1,1,0.02) : "transparent")
                                border.width: entryMA.containsMouse ? 1 : 0
                                border.color: Appearance?.colors.colPrimary ?? "#65558F"

                                property bool isImage: Cliphist.entryIsImage(modelData)
                                property string displayText: modelData.split("\t").slice(1).join("\t")

                                RowLayout {
                                    id: entryContent
                                    anchors { fill: parent; margins: 6 }
                                    spacing: 8

                                    // Type indicator
                                    MaterialSymbol {
                                        text: isImage ? "image" : "text_snippet"
                                        iconSize: 18; opacity: 0.4
                                        color: isImage ? "#81C784" : Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                                        Layout.alignment: Qt.AlignTop
                                    }

                                    // Content preview
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2

                                        // For images: show image indicator
                                        StyledText {
                                            visible: isImage
                                            text: displayText
                                            font.pixelSize: 13; font.italic: true
                                            opacity: 0.6; Layout.fillWidth: true
                                        }

                                        // For text: show content
                                        StyledText {
                                            visible: !isImage
                                            text: displayText.substring(0, 300) + (displayText.length > 300 ? "..." : "")
                                            font.pixelSize: 13
                                            wrapMode: Text.Wrap; maximumLineCount: 4
                                            elide: Text.ElideRight; Layout.fillWidth: true
                                        }
                                    }

                                    // Actions
                                    RowLayout {
                                        spacing: 2; Layout.alignment: Qt.AlignTop
                                        ToolbarButton {
                                            iconName: "content_copy"; iconSize: 14
                                            toolTipText: "Copy to clipboard"
                                            onClicked: Cliphist.copy(modelData)
                                        }
                                        ToolbarButton {
                                            iconName: "content_paste"; iconSize: 14
                                            toolTipText: "Paste"
                                            onClicked: { Cliphist.paste(modelData); GlobalStates.clipboardOpen = false }
                                        }
                                        ToolbarButton {
                                            iconName: "delete"; iconSize: 14
                                            toolTipText: "Delete entry"
                                            onClicked: Cliphist.deleteEntry(modelData)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: entryMA
                                    anchors.fill: parent; hoverEnabled: true; z: -1
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: event => {
                                        if (event.button === Qt.RightButton) Cliphist.copy(modelData)
                                        else { Cliphist.paste(modelData); GlobalStates.clipboardOpen = false }
                                    }
                                }
                            }
                        }
                    }
                }

                // Footer
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    StyledText { text: "Click to paste • Right-click to copy • Esc to close"; font.pixelSize: 11; opacity: 0.3; Layout.fillWidth: true }
                }
            }
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { GlobalStates.clipboardOpen = !GlobalStates.clipboardOpen }
        function open(): void { GlobalStates.clipboardOpen = true }
        function close(): void { GlobalStates.clipboardOpen = false }
    }
}

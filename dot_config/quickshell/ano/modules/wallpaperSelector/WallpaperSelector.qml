import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

/**
 * Wallpaper selector overlay — browse wallpapers from a directory,
 * preview thumbnails in a grid, click to apply, navigate directories.
 */
Scope {
    id: root

    PanelWindow {
        id: wpWindow
        visible: GlobalStates.wallpaperSelectorOpen

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:wallpaper"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.wallpaperSelectorOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }

        Keys.onPressed: event => { if (event.key === Qt.Key_Escape) GlobalStates.wallpaperSelectorOpen = false }

        // Scrim
        Rectangle {
            anchors.fill: parent; color: "#000000"
            opacity: GlobalStates.wallpaperSelectorOpen ? 0.6 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MouseArea { anchors.fill: parent; onClicked: GlobalStates.wallpaperSelectorOpen = false }
        }

        // Card
        Rectangle {
            id: wpCard
            anchors.centerIn: parent
            width: Math.min(1100, parent.width * 0.88)
            height: Math.min(750, parent.height * 0.88)
            radius: Appearance?.rounding.windowRounding ?? 20
            color: Appearance?.m3colors.m3background ?? "#1C1B1F"
            border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
            clip: true

            opacity: GlobalStates.wallpaperSelectorOpen ? 1 : 0
            scale: GlobalStates.wallpaperSelectorOpen ? 1 : 0.92
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors { fill: parent; margins: 16 }
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true; spacing: 12

                    ToolbarButton { iconName: "arrow_back"; iconSize: 22; onClicked: Wallpapers.navigateUp(); toolTipText: "Parent directory" }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        StyledText { text: "Wallpapers"; font.pixelSize: Appearance?.font.pixelSize.huger ?? 22; font.weight: Font.Bold }
                        StyledText {
                            text: Wallpapers.effectiveDirectory
                            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                            font.family: Appearance?.font.family.mono ?? "monospace"
                            opacity: 0.4; elide: Text.ElideMiddle; Layout.fillWidth: true
                        }
                    }

                    // Randomize button
                    RippleButtonWithIcon {
                        iconName: "shuffle"; buttonText: "Random"
                        buttonRadius: Appearance?.rounding.full ?? 9999
                        onClicked: Wallpapers.randomFromCurrentFolder()
                    }

                    // Rotation status
                    Rectangle {
                        implicitWidth: rotRow.implicitWidth + 16
                        implicitHeight: rotRow.implicitHeight + 8
                        radius: height / 2
                        visible: Config.options?.background?.randomize?.enable ?? false
                        color: Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.15)

                        RowLayout {
                            id: rotRow; anchors.centerIn: parent; spacing: 4
                            MaterialSymbol { text: "autorenew"; iconSize: 14; color: Appearance?.colors.colPrimary ?? "#65558F" }
                            StyledText {
                                text: {
                                    const v = Config.options?.background?.randomize?.interval ?? 300
                                    return v >= 3600 ? `${(v / 3600).toFixed(1)}h` : v >= 60 ? `${Math.round(v / 60)}m` : `${v}s`
                                }
                                font.pixelSize: 11; color: Appearance?.colors.colPrimary ?? "#65558F"
                            }
                        }
                    }

                    ToolbarButton { iconName: "close"; iconSize: 22; onClicked: GlobalStates.wallpaperSelectorOpen = false }
                }

                // Directory path bar
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 36; radius: 18
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                    StyledTextInput {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Appearance?.font.family.mono ?? "monospace"
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
                        text: Wallpapers.effectiveDirectory
                        onAccepted: Wallpapers.setDirectory(text)
                    }
                }

                // Wallpaper grid
                GridView {
                    id: wallpaperGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: 200; cellHeight: 140

                    model: Wallpapers.folderModel

                    ScrollBar.vertical: StyledScrollBar {}

                    delegate: Item {
                        width: wallpaperGrid.cellWidth
                        height: wallpaperGrid.cellHeight

                        required property string fileName
                        required property string filePath
                        required property bool fileIsDir

                        Rectangle {
                            anchors { fill: parent; margins: 4 }
                            radius: Appearance?.rounding.small ?? 8
                            color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
                            clip: true

                            // Thumbnail
                            Image {
                                anchors.fill: parent
                                source: fileIsDir ? "" : `file://${filePath}`
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(384, 256)
                                visible: !fileIsDir && status === Image.Ready
                            }

                            // Directory indicator
                            ColumnLayout {
                                anchors.centerIn: parent
                                visible: fileIsDir
                                spacing: 4
                                MaterialSymbol { text: "folder"; iconSize: 36; color: Appearance?.colors.colPrimary ?? "#65558F"; Layout.alignment: Qt.AlignHCenter }
                                StyledText { text: fileName; font.pixelSize: 11; elide: Text.ElideMiddle; Layout.maximumWidth: 160; Layout.alignment: Qt.AlignHCenter }
                            }

                            // Name badge
                            Rectangle {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: 26; color: "#CC000000"
                                visible: !fileIsDir
                                radius: Appearance?.rounding.small ?? 8
                                topLeftRadius: 0; topRightRadius: 0

                                StyledText {
                                    anchors { centerIn: parent; leftMargin: 6; rightMargin: 6 }
                                    width: parent.width - 12
                                    text: fileName
                                    font.pixelSize: 10; color: "white"
                                    elide: Text.ElideMiddle
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            // Hover border
                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance?.rounding.small ?? 8
                                color: "transparent"
                                border.width: wpItemMA.containsMouse ? 2 : 0
                                border.color: Appearance?.colors.colPrimary ?? "#65558F"
                            }

                            // Click overlay
                            Rectangle {
                                anchors.fill: parent; radius: Appearance?.rounding.small ?? 8
                                color: wpItemMA.containsMouse ? "#22ffffff" : "transparent"
                            }

                            MouseArea {
                                id: wpItemMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (fileIsDir) Wallpapers.setDirectory(filePath)
                                    else { Wallpapers.select(filePath); GlobalStates.wallpaperSelectorOpen = false }
                                }
                            }
                        }
                    }

                    // Empty state
                    StyledText {
                        anchors.centerIn: parent
                        visible: Wallpapers.folderModel.count === 0
                        text: "No wallpapers found in this directory"
                        font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                        opacity: 0.4
                    }
                }

                // Footer stats
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    StyledText {
                        text: `${Wallpapers.folderModel.count} items`
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        opacity: 0.4
                    }
                    Item { Layout.fillWidth: true }
                    Loader {
                        active: Wallpapers.thumbnailGenerationRunning
                        visible: active
                        sourceComponent: RowLayout {
                            spacing: 6
                            StyledProgressBar { Layout.preferredWidth: 100; value: Wallpapers.thumbnailGenerationProgress; valueBarHeight: 4 }
                            StyledText { text: "Generating thumbnails..."; font.pixelSize: 11; opacity: 0.5 }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "wallpaperSelector"
        function toggle(): void { GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen }
        function open(): void { GlobalStates.wallpaperSelectorOpen = true }
        function close(): void { GlobalStates.wallpaperSelectorOpen = false }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * Compact media player card for right sidebar.
 * Shows album art, track info, playback controls, and progress.
 * Inspired by ilyamiro's MusicPopup vinyl design.
 */
Rectangle {
    id: root
    implicitHeight: contentCol.implicitHeight + 16
    radius: Appearance?.rounding.normal ?? 12
    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

    ColumnLayout {
        id: contentCol
        anchors { fill: parent; margins: 8 }
        spacing: 6

        // Track info row
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Album art (circular, spinning when playing)
            Rectangle {
                Layout.preferredWidth: 48; Layout.preferredHeight: 48
                radius: 24
                color: Appearance?.colors.colLayer2 ?? "#2B2930"
                clip: true

                StyledImage {
                    anchors.fill: parent
                    source: MprisController.activeTrack?.artUrl ?? ""
                    fillMode: Image.PreserveAspectCrop

                    RotationAnimator {
                        target: parent
                        from: 0; to: 360; duration: 8000
                        running: MprisController.isPlaying
                        loops: Animation.Infinite
                    }
                }

                // Vinyl hole
                Rectangle {
                    anchors.centerIn: parent
                    width: 10; height: 10; radius: 5
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                StyledText {
                    text: MprisController.activeTrack?.title ?? "No media"
                    font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                StyledText {
                    text: MprisController.activeTrack?.artist ?? ""
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                    opacity: 0.6
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            // Shuffle
            ToolbarButton {
                iconName: "shuffle"; iconSize: 18
                visible: MprisController.shuffleSupported
                opacity: MprisController.hasShuffle ? 1 : 0.4
                onClicked: MprisController.setShuffle(!MprisController.hasShuffle)
            }

            ToolbarButton { iconName: "skip_previous"; iconSize: 22; onClicked: MprisController.previous(); enabled: MprisController.canGoPrevious }

            // Play/Pause button (prominent)
            Rectangle {
                width: 40; height: 40; radius: 20
                color: Appearance?.colors.colPrimary ?? "#65558F"
                scale: playMA.pressed ? 0.9 : (playMA.containsMouse ? 1.05 : 1)
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: MprisController.isPlaying ? "pause" : "play_arrow"
                    iconSize: 24; fill: 1
                    color: Appearance?.m3colors.m3onPrimary ?? "white"
                }
                MouseArea {
                    id: playMA; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MprisController.togglePlaying()
                }
            }

            ToolbarButton { iconName: "skip_next"; iconSize: 22; onClicked: MprisController.next(); enabled: MprisController.canGoNext }

            // Loop
            ToolbarButton {
                iconName: MprisController.loopState === 2 ? "repeat_one" : "repeat"
                iconSize: 18
                visible: MprisController.loopSupported
                opacity: MprisController.loopState !== 0 ? 1 : 0.4
                onClicked: MprisController.setLoopState((MprisController.loopState + 1) % 3)
            }
        }
    }
}

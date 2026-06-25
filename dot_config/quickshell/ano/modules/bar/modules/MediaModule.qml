import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.spectrum
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * Compact media player bar module with morph-capable popout showing
 * album art, track info, playback controls, and spectrum.
 */
Item {
    id: root
    visible: MprisController.activePlayer != null
    implicitWidth: visible ? mediaRow.implicitWidth + 12 : 0
    implicitHeight: Appearance.sizes.barHeight
    property bool hovered: mediaMA.containsMouse

    RowLayout {
        id: mediaRow; anchors.centerIn: parent; spacing: 4
        MaterialSymbol {
            text: MprisController.isPlaying ? "pause" : "play_arrow"
            iconSize: Appearance?.font.pixelSize.normal ?? 18; fill: 1
            color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
            Layout.alignment: Qt.AlignVCenter
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: MprisController.togglePlaying() }
        }
        StyledText {
            text: MprisController.activeTrack?.title ?? ""
            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
            color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
            elide: Text.ElideRight; Layout.maximumWidth: 150; Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mediaMA; anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.MiddleButton
        onClicked: GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
    }

    BarModulePopout {
        shown: root.hovered
        popupWidth: 300; popupHeight: mediaPopupCol.implicitHeight + 24

        ColumnLayout {
            id: mediaPopupCol; anchors.fill: parent; spacing: 10

            // Track info with art
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Rectangle {
                    width: 56; height: 56; radius: 28; color: Appearance?.colors.colLayer2 ?? "#2B2930"; clip: true
                    Image {
                        anchors.fill: parent; source: MprisController.activeTrack?.artUrl ?? ""
                        fillMode: Image.PreserveAspectCrop; asynchronous: true
                        layer.enabled: true; layer.effect: OpacityMask { maskSource: Rectangle { width: 56; height: 56; radius: 28 } }
                        RotationAnimator { target: parent; from: 0; to: 360; duration: 10000; running: MprisController.isPlaying; loops: Animation.Infinite }
                    }
                    Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: Appearance?.colors.colLayer0 ?? "#1C1B1F" }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    StyledText { text: MprisController.activeTrack?.title ?? ""; font.pixelSize: 15; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                    StyledText { text: MprisController.activeTrack?.artist ?? ""; font.pixelSize: 12; opacity: 0.5; elide: Text.ElideRight; Layout.fillWidth: true }
                    StyledText { text: MprisController.activeTrack?.album ?? ""; font.pixelSize: 11; opacity: 0.3; visible: (MprisController.activeTrack?.album ?? "").length > 0; elide: Text.ElideRight; Layout.fillWidth: true }
                }
            }

            // Spectrum (if cava running)
            Loader {
                Layout.fillWidth: true; Layout.preferredHeight: 24
                active: !SpectrumService.isIdle; visible: active
                sourceComponent: Rectangle {
                    radius: 6; color: Appearance?.colors.colLayer2 ?? "#2B2930"
                    MirroredSpectrum {
                        anchors { fill: parent; margins: 2 }
                        fillColor: Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.5)
                    }
                }
                Component.onCompleted: SpectrumService.registerComponent("mediaBarPopup")
                Component.onDestruction: SpectrumService.unregisterComponent("mediaBarPopup")
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 16
                ToolbarButton { iconName: "skip_previous"; iconSize: 22; onClicked: MprisController.previous(); enabled: MprisController.canGoPrevious }
                Rectangle {
                    width: 40; height: 40; radius: 20; color: Appearance?.colors.colPrimary ?? "#65558F"
                    scale: playMA.pressed ? 0.9 : 1; Behavior on scale { NumberAnimation { duration: 100 } }
                    MaterialSymbol { anchors.centerIn: parent; text: MprisController.isPlaying ? "pause" : "play_arrow"; iconSize: 24; fill: 1; color: Appearance?.m3colors.m3onPrimary ?? "white" }
                    MouseArea { id: playMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: MprisController.togglePlaying() }
                }
                ToolbarButton { iconName: "skip_next"; iconSize: 22; onClicked: MprisController.next(); enabled: MprisController.canGoNext }
            }

            // Click hint
            StyledText { text: "Middle-click for full player"; font.pixelSize: 9; opacity: 0.3; Layout.alignment: Qt.AlignHCenter }
        }
    }
}

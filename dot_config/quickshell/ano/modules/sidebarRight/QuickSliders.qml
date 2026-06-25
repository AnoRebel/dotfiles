import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * Volume + Brightness sliders, inspired by ilyamiro's battery popup sliders.
 */
Rectangle {
    id: root
    property var brightnessMonitor

    implicitHeight: slidersColumn.implicitHeight + 16
    radius: Appearance?.rounding.normal ?? 12
    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

    ColumnLayout {
        id: slidersColumn
        anchors { fill: parent; margins: 8 }
        spacing: 8

        // Brightness
        Loader {
            Layout.fillWidth: true
            active: (Config.options?.sidebar?.quickSliders?.showBrightness ?? true) && !!root.brightnessMonitor
            visible: active
            sourceComponent: RowLayout {
                spacing: 8
                MaterialSymbol {
                    text: "brightness_6"; iconSize: 20
                    color: Appearance?.colors.colPrimary ?? "#65558F"
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledSlider {
                    Layout.fillWidth: true
                    configuration: StyledSlider.Configuration.M
                    value: root.brightnessMonitor?.brightness ?? 0
                    onMoved: root.brightnessMonitor?.setBrightness(value)
                    stopIndicatorValues: []
                }
            }
        }

        // Volume
        Loader {
            Layout.fillWidth: true
            active: Config.options?.sidebar?.quickSliders?.showVolume ?? true
            visible: active
            sourceComponent: RowLayout {
                spacing: 8
                MaterialSymbol {
                    text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                    iconSize: 20
                    color: Audio.sink?.audio?.muted ? Appearance?.m3colors.m3error ?? "#BA1A1A" : Appearance?.colors.colPrimary ?? "#65558F"
                    Layout.alignment: Qt.AlignVCenter
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.toggleMute()
                    }
                }
                StyledSlider {
                    Layout.fillWidth: true
                    configuration: StyledSlider.Configuration.M
                    value: Audio.sink?.audio?.volume ?? 0
                    onMoved: { if (Audio.sink?.audio) Audio.sink.audio.volume = value }
                    stopIndicatorValues: []
                }
            }
        }

        // Mic
        Loader {
            Layout.fillWidth: true
            active: Config.options?.sidebar?.quickSliders?.showMic ?? false
            visible: active
            sourceComponent: RowLayout {
                spacing: 8
                MaterialSymbol {
                    text: Audio.source?.audio?.muted ? "mic_off" : "mic"
                    iconSize: 20; color: Appearance?.colors.colPrimary ?? "#65558F"
                    Layout.alignment: Qt.AlignVCenter
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Audio.toggleMicMute() }
                }
                StyledSlider {
                    Layout.fillWidth: true
                    configuration: StyledSlider.Configuration.M
                    value: Audio.source?.audio?.volume ?? 0
                    onMoved: { if (Audio.source?.audio) Audio.source.audio.volume = value }
                    stopIndicatorValues: []
                }
            }
        }
    }
}

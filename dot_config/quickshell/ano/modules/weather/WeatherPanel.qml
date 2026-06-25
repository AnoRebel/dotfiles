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
 * Standalone weather panel — detailed weather overlay with current conditions,
 * forecast-like stats (humidity, wind, UV, visibility, pressure),
 * sunrise/sunset times, and configurable units.
 * Triggered via IPC or bar weather module click.
 */
Scope {
    id: root

    IpcHandler {
        target: "weatherPanel"
        function toggle(): void { GlobalStates.weatherPanelOpen = !GlobalStates.weatherPanelOpen }
        function open(): void { GlobalStates.weatherPanelOpen = true }
        function close(): void { GlobalStates.weatherPanelOpen = false }
    }

    PanelWindow {
        id: weatherWindow
        visible: GlobalStates.weatherPanelOpen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:weather"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.weatherPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }
        Keys.onPressed: event => { if (event.key === Qt.Key_Escape) GlobalStates.weatherPanelOpen = false }

        Rectangle {
            anchors.fill: parent; color: "#000000"
            opacity: GlobalStates.weatherPanelOpen ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MouseArea { anchors.fill: parent; onClicked: GlobalStates.weatherPanelOpen = false }
        }

        Rectangle {
            id: weatherCard
            anchors.centerIn: parent
            width: Math.min(420, parent.width * 0.5)
            height: weatherContent.implicitHeight + 48
            radius: Appearance?.rounding.windowRounding ?? 20
            color: Appearance?.m3colors.m3background ?? "#1C1B1F"
            border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
            clip: true

            opacity: GlobalStates.weatherPanelOpen ? 1 : 0
            scale: GlobalStates.weatherPanelOpen ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: weatherContent
                anchors { fill: parent; margins: 24 }
                spacing: 16

                // City + temperature hero
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 4
                    StyledText {
                        text: Weather.data.city || "Loading..."
                        font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                        opacity: 0.6; Layout.alignment: Qt.AlignHCenter
                    }
                    StyledText {
                        text: Weather.data.temp || "--"
                        font.pixelSize: 56; font.weight: Font.Bold
                        font.family: Appearance?.font.family.numbers ?? "monospace"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    StyledText {
                        text: `Feels like ${Weather.data.tempFeelsLike || "--"}`
                        font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                        opacity: 0.5; Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Stats grid
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: statsGrid.implicitHeight + 20
                    radius: Appearance?.rounding.normal ?? 12
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                    GridLayout {
                        id: statsGrid
                        anchors { fill: parent; margins: 10 }
                        columns: 3; columnSpacing: 12; rowSpacing: 12

                        WeatherStat { icon: "water_drop"; label: "Humidity"; value: Weather.data.humidity || "--" }
                        WeatherStat { icon: "air"; label: "Wind"; value: `${Weather.data.wind || "--"} ${Weather.data.windDir || ""}` }
                        WeatherStat { icon: "wb_sunny"; label: "UV Index"; value: `${Weather.data.uv ?? "--"}` }
                        WeatherStat { icon: "visibility"; label: "Visibility"; value: Weather.data.visib || "--" }
                        WeatherStat { icon: "compress"; label: "Pressure"; value: Weather.data.press || "--" }
                        WeatherStat { icon: "umbrella"; label: "Precip"; value: Weather.data.precip || "--" }
                    }
                }

                // Sunrise/Sunset
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sunRow.implicitHeight + 16
                    radius: Appearance?.rounding.normal ?? 12
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                    RowLayout {
                        id: sunRow
                        anchors { fill: parent; margins: 8 }
                        spacing: 16

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            MaterialSymbol { text: "wb_twilight"; iconSize: 22; color: "#FFB74D" }
                            ColumnLayout {
                                spacing: 0
                                StyledText { text: "Sunrise"; font.pixelSize: 11; opacity: 0.4 }
                                StyledText { text: Weather.data.sunrise || "--"; font.pixelSize: 16; font.weight: Font.DemiBold; font.family: Appearance?.font.family.numbers ?? "monospace" }
                            }
                        }

                        Rectangle { implicitWidth: 1; Layout.fillHeight: true; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.2 }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            MaterialSymbol { text: "wb_twilight"; iconSize: 22; color: "#AB47BC"; rotation: 180 }
                            ColumnLayout {
                                spacing: 0
                                StyledText { text: "Sunset"; font.pixelSize: 11; opacity: 0.4 }
                                StyledText { text: Weather.data.sunset || "--"; font.pixelSize: 16; font.weight: Font.DemiBold; font.family: Appearance?.font.family.numbers ?? "monospace" }
                            }
                        }
                    }
                }

                // Last refresh + refresh button
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    StyledText { text: `Last: ${Weather.data.lastRefresh || "never"}`; font.pixelSize: 10; opacity: 0.3; Layout.fillWidth: true }
                    ToolbarButton { iconName: "refresh"; iconSize: 18; onClicked: Weather.getData(); toolTipText: "Refresh weather" }
                }
            }
        }
    }

    component WeatherStat: ColumnLayout {
        property string icon: ""; property string label: ""; property string value: ""
        spacing: 2; Layout.fillWidth: true
        MaterialSymbol { text: icon; iconSize: 20; color: Appearance?.colors.colPrimary ?? "#65558F"; Layout.alignment: Qt.AlignHCenter }
        StyledText { text: value; font.pixelSize: Appearance?.font.pixelSize.small ?? 14; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter; font.family: Appearance?.font.family.mono ?? "monospace" }
        StyledText { text: label; font.pixelSize: 10; opacity: 0.4; Layout.alignment: Qt.AlignHCenter }
    }
}

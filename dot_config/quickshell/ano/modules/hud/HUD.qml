import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.spectrum
import qs.services

/**
 * HUD (Heads-Up Display) — a floating dashboard overlay showing system
 * vitals at a glance. Toggled via IPC or keybind.
 *
 * Shows: CPU/RAM/Battery gauges, network speed, uptime, time,
 * audio spectrum visualizer, current media track.
 *
 * Inspired by caelestia's HUD and ilyamiro's system popups.
 */
Scope {
    id: root

    readonly property bool hudEnabled: Config.options?.hud?.enable ?? true

    PanelWindow {
        id: hudWindow
        visible: GlobalStates.hudVisible && root.hudEnabled

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:hud"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.hudVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }

        Keys.onPressed: event => { if (event.key === Qt.Key_Escape) GlobalStates.hudVisible = false }

        // Register spectrum when HUD is open
        Connections {
            target: GlobalStates
            function onHudVisibleChanged() {
                if (GlobalStates.hudVisible) SpectrumService.registerComponent("hud")
                else SpectrumService.unregisterComponent("hud")
            }
        }

        // Scrim
        Rectangle {
            anchors.fill: parent; color: "#000000"
            opacity: GlobalStates.hudVisible ? 0.55 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
            MouseArea { anchors.fill: parent; onClicked: GlobalStates.hudVisible = false }
        }

        // HUD card
        Rectangle {
            id: hudCard
            anchors.centerIn: parent
            width: Math.min(520, parent.width * 0.6)
            height: hudContent.implicitHeight + 48
            radius: Appearance?.rounding.windowRounding ?? 20
            color: Appearance?.m3colors.m3background ?? "#1C1B1F"
            border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
            clip: true

            opacity: GlobalStates.hudVisible ? 1 : 0
            scale: GlobalStates.hudVisible ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: hudContent
                anchors { fill: parent; margins: 24 }
                spacing: 20

                // ─── Clock + Date ────────────────────────────────────
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2

                    StyledText {
                        text: DateTime.time
                        font.pixelSize: 56
                        font.weight: Font.Bold
                        font.family: Appearance?.font.family.numbers ?? "monospace"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    StyledText {
                        text: DateTime.collapsedCalendarFormat
                        font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                        opacity: 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // ─── System gauges row ───────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: gaugeRow.implicitHeight + 20
                    radius: Appearance?.rounding.normal ?? 12
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                    RowLayout {
                        id: gaugeRow
                        anchors { fill: parent; margins: 10 }
                        spacing: 0

                        // CPU
                        HudGauge {
                            label: "CPU"
                            value: ResourceUsage.cpuUsage
                            valueText: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                            subText: ResourceUsage.maxAvailableCpuString
                            gaugeColor: Appearance?.colors.colPrimary ?? "#65558F"
                            Layout.fillWidth: true
                        }

                        // Separator
                        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.2; Layout.topMargin: 8; Layout.bottomMargin: 8 }

                        // RAM
                        HudGauge {
                            label: "RAM"
                            value: ResourceUsage.memoryUsedPercentage
                            valueText: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed)
                            subText: `/ ${ResourceUsage.maxAvailableMemoryString}`
                            gaugeColor: "#42A5F5"
                            Layout.fillWidth: true
                        }

                        // Separator
                        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.2; Layout.topMargin: 8; Layout.bottomMargin: 8 }

                        // Battery or Swap
                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: Battery.available ? batteryGauge : swapGauge
                        }
                    }
                }

                // ─── Network speed ───────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: netRow.implicitHeight + 16
                    radius: Appearance?.rounding.normal ?? 12
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                    RowLayout {
                        id: netRow
                        anchors { fill: parent; margins: 8 }
                        spacing: 16

                        // Connection
                        RowLayout {
                            spacing: 6
                            MaterialSymbol { text: Network.materialSymbol; iconSize: 20; color: Appearance?.colors.colPrimary ?? "#65558F" }
                            StyledText {
                                text: Network.wifi ? Network.networkName : (Network.ethernet ? "Ethernet" : "Disconnected")
                                font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                                elide: Text.ElideRight; Layout.maximumWidth: 120
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Down
                        RowLayout {
                            spacing: 4
                            MaterialSymbol { text: "arrow_downward"; iconSize: 16; color: "#81C784" }
                            StyledText {
                                text: formatSpeed(ResourceUsage.networkDownloadSpeed)
                                font.pixelSize: 13; font.family: Appearance?.font.family.mono ?? "monospace"
                            }
                        }

                        // Up
                        RowLayout {
                            spacing: 4
                            MaterialSymbol { text: "arrow_upward"; iconSize: 16; color: "#E57373" }
                            StyledText {
                                text: formatSpeed(ResourceUsage.networkUploadSpeed)
                                font.pixelSize: 13; font.family: Appearance?.font.family.mono ?? "monospace"
                            }
                        }
                    }
                }

                // ─── Audio spectrum (only if cava available) ─────────
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: active ? 48 : 0
                    active: SpectrumService.registeredCount > 0 && !SpectrumService.isIdle

                    sourceComponent: Rectangle {
                        radius: Appearance?.rounding.normal ?? 12
                        color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                        MirroredSpectrum {
                            anchors { fill: parent; margins: 4 }
                            fillColor: Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.6)
                            cornerRadius: 3
                        }
                    }
                }

                // ─── Media (if playing) ──────────────────────────────
                Loader {
                    Layout.fillWidth: true
                    active: MprisController.activePlayer != null
                    visible: active

                    sourceComponent: Rectangle {
                        implicitHeight: mediaRow.implicitHeight + 16
                        radius: Appearance?.rounding.normal ?? 12
                        color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                        RowLayout {
                            id: mediaRow
                            anchors { fill: parent; margins: 8 }
                            spacing: 10

                            MaterialSymbol {
                                text: MprisController.isPlaying ? "music_note" : "pause"
                                iconSize: 22; fill: 1
                                color: Appearance?.colors.colPrimary ?? "#65558F"
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 1
                                StyledText {
                                    text: MprisController.activeTrack?.title ?? ""
                                    font.pixelSize: 14; font.weight: Font.DemiBold
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                StyledText {
                                    text: MprisController.activeTrack?.artist ?? ""
                                    font.pixelSize: 12; opacity: 0.5
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                // ─── Uptime ──────────────────────────────────────────
                StyledText {
                    text: `Up ${DateTime.uptime} • ${CompositorService.compositor}`
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                    opacity: 0.3
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return `${Math.round(bytesPerSec)} B/s`
        if (bytesPerSec < 1048576) return `${(bytesPerSec / 1024).toFixed(1)} KB/s`
        return `${(bytesPerSec / 1048576).toFixed(1)} MB/s`
    }

    // Gauge component
    component HudGauge: ColumnLayout {
        property string label: ""
        property real value: 0
        property string valueText: ""
        property string subText: ""
        property color gaugeColor: Appearance?.colors.colPrimary ?? "#65558F"
        spacing: 6

        CircularProgress {
            Layout.alignment: Qt.AlignHCenter
            implicitSize: 56; lineWidth: 4
            value: parent.value
            colPrimary: gaugeColor
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: valueText
            font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
            font.weight: Font.Bold
            font.family: Appearance?.font.family.numbers ?? "monospace"
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: label
            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
            font.weight: Font.DemiBold
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: subText; visible: subText.length > 0
            font.pixelSize: 10; opacity: 0.4
        }
    }

    Component {
        id: batteryGauge
        HudGauge {
            label: Battery.isCharging ? "Charging" : "Battery"
            value: Battery.percentage
            valueText: `${Math.round(Battery.percentage * 100)}%`
            subText: Battery.isCharging && Battery.timeToFull > 0 ? `${Math.round(Battery.timeToFull / 60)}min` : ""
            gaugeColor: Battery.isLow && !Battery.isCharging ? "#EF5350" : Battery.isCharging ? "#81C784" : "#FFB74D"
        }
    }

    Component {
        id: swapGauge
        HudGauge {
            label: "Swap"
            value: ResourceUsage.swapUsedPercentage
            valueText: ResourceUsage.kbToGbString(ResourceUsage.swapUsed)
            subText: `/ ${ResourceUsage.maxAvailableSwapString}`
            gaugeColor: "#AB47BC"
        }
    }

    IpcHandler {
        target: "hud"
        function toggle(): void { GlobalStates.hudVisible = !GlobalStates.hudVisible }
        function open(): void { GlobalStates.hudVisible = true }
        function close(): void { GlobalStates.hudVisible = false }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * System info panel — CPU, RAM, swap usage with circular indicators and graphs.
 * Inspired by ilyamiro's battery popup stats and inir's sysmon widget.
 */
Rectangle {
    id: root
    implicitHeight: infoCol.implicitHeight + 20
    radius: Appearance?.rounding.normal ?? 12
    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

    ColumnLayout {
        id: infoCol
        anchors { fill: parent; margins: 10 }
        spacing: 10

        StyledText {
            text: "System"
            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
            font.weight: Font.DemiBold
        }

        // CPU + RAM + Battery gauges
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // CPU
            GaugeItem {
                label: "CPU"
                value: ResourceUsage.cpuUsage
                valueText: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                Layout.fillWidth: true
            }

            // RAM
            GaugeItem {
                label: "RAM"
                value: ResourceUsage.memoryUsedPercentage
                valueText: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed)
                Layout.fillWidth: true
            }

            // Swap
            GaugeItem {
                label: "Swap"
                value: ResourceUsage.swapUsedPercentage
                valueText: ResourceUsage.kbToGbString(ResourceUsage.swapUsed)
                visible: ResourceUsage.swapTotal > 0
                Layout.fillWidth: true
            }

            // Battery (if laptop)
            Loader {
                Layout.fillWidth: true
                active: Battery.available
                visible: active
                sourceComponent: GaugeItem {
                    label: Battery.isCharging ? "Charging" : "Battery"
                    value: Battery.percentage
                    valueText: `${Math.round(Battery.percentage * 100)}%`
                    gaugeColor: Battery.isLow && !Battery.isCharging
                        ? Appearance?.m3colors.m3error ?? "#BA1A1A"
                        : Battery.isCharging
                            ? "#81C784"
                            : Appearance?.colors.colPrimary ?? "#65558F"
                }
            }
        }

        // Network speed
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            MaterialSymbol { text: "arrow_downward"; iconSize: 16; color: "#81C784" }
            StyledText {
                text: formatSpeed(ResourceUsage.networkDownloadSpeed)
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                font.family: Appearance?.font.family.mono ?? "monospace"
            }
            MaterialSymbol { text: "arrow_upward"; iconSize: 16; color: "#E57373" }
            StyledText {
                text: formatSpeed(ResourceUsage.networkUploadSpeed)
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                font.family: Appearance?.font.family.mono ?? "monospace"
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: `Up ${DateTime.uptime}`
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                opacity: 0.5
            }
        }
    }

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return `${Math.round(bytesPerSec)} B/s`
        if (bytesPerSec < 1024 * 1024) return `${(bytesPerSec / 1024).toFixed(1)} KB/s`
        return `${(bytesPerSec / 1024 / 1024).toFixed(1)} MB/s`
    }

    // Circular gauge component
    component GaugeItem: ColumnLayout {
        property string label: ""
        property real value: 0
        property string valueText: ""
        property color gaugeColor: Appearance?.colors.colPrimary ?? "#65558F"
        spacing: 4

        CircularProgress {
            Layout.alignment: Qt.AlignHCenter
            implicitSize: 48; lineWidth: 3
            value: parent.value
            colPrimary: gaugeColor
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: valueText
            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
            font.weight: Font.DemiBold
            font.family: Appearance?.font.family.mono ?? "monospace"
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: label
            font.pixelSize: Appearance?.font.pixelSize.smallest ?? 10
            opacity: 0.5
        }
    }
}

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * System resources bar module with rich hover popup showing
 * CPU/RAM/Swap gauges, CPU history graph, and system details.
 */
Item {
    id: root
    implicitWidth: row.implicitWidth + 12
    implicitHeight: Appearance.sizes.barHeight
    property bool hovered: resMA.containsMouse

    RowLayout {
        id: row; anchors.centerIn: parent; spacing: 4
        CombinedCircularProgress { implicitSize: 22; outerLineWidth: 2; innerLineWidth: 2; outerValue: ResourceUsage.cpuUsage; innerValue: ResourceUsage.memoryUsedPercentage; Layout.alignment: Qt.AlignVCenter }
        StyledText { text: `${Math.round(ResourceUsage.cpuUsage * 100)}%`; font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12; color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5" }
    }

    MouseArea { id: resMA; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton; onClicked: GlobalStates.hudVisible = !GlobalStates.hudVisible }

    BarModulePopout {
        shown: root.hovered
        popupWidth: 280; popupHeight: resPopupCol.implicitHeight + 24

        ColumnLayout {
            id: resPopupCol; anchors.fill: parent; spacing: 10

            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Repeater {
                    model: [
                        { label: "CPU", value: ResourceUsage.cpuUsage, text: `${Math.round(ResourceUsage.cpuUsage * 100)}%`, color: Appearance?.colors.colPrimary ?? "#65558F" },
                        { label: "RAM", value: ResourceUsage.memoryUsedPercentage, text: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed), color: "#42A5F5" },
                    ]
                    ColumnLayout {
                        required property var modelData; Layout.fillWidth: true; spacing: 4
                        CircularProgress { implicitSize: 48; lineWidth: 3; value: modelData.value; colPrimary: modelData.color; Layout.alignment: Qt.AlignHCenter }
                        StyledText { text: modelData.text; font.pixelSize: 14; font.weight: Font.Bold; font.family: Appearance?.font.family.numbers ?? "monospace"; Layout.alignment: Qt.AlignHCenter }
                        StyledText { text: modelData.label; font.pixelSize: 10; opacity: 0.4; Layout.alignment: Qt.AlignHCenter }
                    }
                }
                Loader {
                    Layout.fillWidth: true; active: ResourceUsage.swapTotal > 1024; visible: active
                    sourceComponent: ColumnLayout {
                        spacing: 4
                        CircularProgress { implicitSize: 48; lineWidth: 3; value: ResourceUsage.swapUsedPercentage; colPrimary: "#AB47BC"; Layout.alignment: Qt.AlignHCenter }
                        StyledText { text: ResourceUsage.kbToGbString(ResourceUsage.swapUsed); font.pixelSize: 14; font.weight: Font.Bold; font.family: Appearance?.font.family.numbers ?? "monospace"; Layout.alignment: Qt.AlignHCenter }
                        StyledText { text: "Swap"; font.pixelSize: 10; opacity: 0.4; Layout.alignment: Qt.AlignHCenter }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 32; radius: 6
                color: Appearance?.colors.colLayer2 ?? "#2B2930"
                Graph {
                    anchors { fill: parent; margins: 2 }
                    values: ResourceUsage.cpuUsageHistory
                    color: Appearance?.colors.colPrimary ?? "#65558F"
                    fillOpacity: 0.3
                    alignment: Graph.Alignment.Right
                }
            }

            Repeater {
                model: [{ label: "CPU max", value: ResourceUsage.maxAvailableCpuString }, { label: "RAM total", value: ResourceUsage.maxAvailableMemoryString }, { label: "Uptime", value: DateTime.uptime }]
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true; spacing: 8
                    StyledText { text: modelData.label; font.pixelSize: 11; opacity: 0.4; Layout.fillWidth: true }
                    StyledText { text: modelData.value; font.pixelSize: 11; font.family: Appearance?.font.family.mono ?? "monospace" }
                }
            }

            StyledText { text: "Click to open HUD"; font.pixelSize: 9; opacity: 0.3; Layout.alignment: Qt.AlignHCenter }
        }
    }
}

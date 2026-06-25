import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Network status icon with rich hover popup showing connection details,
 * signal strength, network speed, and WiFi toggle.
 */
Item {
    id: root
    implicitWidth: icon.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight
    property bool hovered: netMA.containsMouse

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        text: Network.materialSymbol
        iconSize: Appearance?.font.pixelSize.larger ?? 20
        color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
    }

    MouseArea {
        id: netMA; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
    }

    BarModulePopout {
        shown: root.hovered
        popupWidth: 260; popupHeight: netPopupCol.implicitHeight + 24

        ColumnLayout {
            id: netPopupCol
            anchors.fill: parent; spacing: 8

            RowLayout {
                Layout.fillWidth: true; spacing: 10
                MaterialSymbol { text: Network.materialSymbol; iconSize: 28; color: Appearance?.colors.colPrimary ?? "#65558F"; fill: 1 }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 1
                    StyledText { text: Network.ethernet ? "Ethernet" : (Network.wifi ? Network.networkName : "Disconnected"); font.pixelSize: 16; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                    StyledText { text: Network.wifiStatus; font.pixelSize: 11; opacity: 0.5 }
                }
            }

            Loader {
                Layout.fillWidth: true; active: Network.wifi; visible: active
                sourceComponent: ColumnLayout {
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: "Signal"; font.pixelSize: 11; opacity: 0.5; Layout.fillWidth: true }
                        StyledText { text: `${Network.networkStrength}%`; font.pixelSize: 12; font.family: Appearance?.font.family.mono ?? "monospace" }
                    }
                    StyledProgressBar { Layout.fillWidth: true; valueBarHeight: 4; value: Network.networkStrength / 100 }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                RowLayout {
                    spacing: 4
                    MaterialSymbol { text: "arrow_downward"; iconSize: 14; color: "#81C784" }
                    StyledText { text: formatSpeed(ResourceUsage.networkDownloadSpeed); font.pixelSize: 11; font.family: Appearance?.font.family.mono ?? "monospace" }
                }
                RowLayout {
                    spacing: 4
                    MaterialSymbol { text: "arrow_upward"; iconSize: 14; color: "#E57373" }
                    StyledText { text: formatSpeed(ResourceUsage.networkUploadSpeed); font.pixelSize: 11; font.family: Appearance?.font.family.mono ?? "monospace" }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 8
                StyledText { text: "WiFi"; font.pixelSize: 12; Layout.fillWidth: true }
                StyledSwitch { checked: Network.wifiEnabled; onCheckedChanged: Network.enableWifi(checked) }
            }
        }
    }

    function formatSpeed(bps) { return bps < 1024 ? `${Math.round(bps)} B/s` : bps < 1048576 ? `${(bps / 1024).toFixed(1)} KB/s` : `${(bps / 1048576).toFixed(1)} MB/s` }
}

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * Network detail expansion — bandwidth (rx/tx) + VPN status.
 *
 * Bandwidth row only renders when Config.options.network.usage.enable is
 * true (NetworkUsage service is otherwise dormant). VPN row renders when
 * Config.options.vpn.enable is true and at least one provider is
 * configured. The whole panel hides itself when neither has anything to
 * show, so the sidebar doesn't gain an empty card on default configs.
 */
Rectangle {
    id: root

    readonly property bool showBandwidth: Config.options?.network?.usage?.enable ?? false
    readonly property bool showVpn: (Config.options?.vpn?.enable ?? true)
                                    && (Config.options?.vpn?.providers?.length ?? 0) > 0
    readonly property bool hasContent: showBandwidth || showVpn

    visible: hasContent
    implicitHeight: hasContent ? (col.implicitHeight + 20) : 0
    radius: Appearance?.rounding.normal ?? 12
    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 10 }
        spacing: 10

        StyledText {
            text: "Network"
            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
            font.weight: Font.DemiBold
            color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
        }

        // ── Bandwidth ─────────────────────────────────────────────────
        Loader {
            Layout.fillWidth: true
            active: root.showBandwidth
            visible: active
            sourceComponent: RowLayout {
                spacing: 12

                // Download
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    RowLayout {
                        spacing: 4
                        MaterialSymbol {
                            text: "download"; iconSize: 16
                            color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                        }
                        StyledText {
                            text: "Down"
                            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                            color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                        }
                    }
                    StyledText {
                        readonly property var fmt: NetworkUsage.formatBytes(NetworkUsage.downloadSpeed)
                        text: `${fmt.value < 10 ? fmt.value.toFixed(1) : Math.round(fmt.value)} ${fmt.unit}`
                        font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                        font.weight: Font.DemiBold
                        font.family: Appearance?.font.family.numbers
                        color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                    }
                    StyledText {
                        readonly property var tot: NetworkUsage.formatBytesTotal(NetworkUsage.downloadTotal)
                        text: `Total ${tot.value < 10 ? tot.value.toFixed(1) : Math.round(tot.value)} ${tot.unit}`
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Appearance?.colors.colOutlineVariant ?? "#49454F"
                    opacity: 0.4
                }

                // Upload
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    RowLayout {
                        spacing: 4
                        MaterialSymbol {
                            text: "upload"; iconSize: 16
                            color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                        }
                        StyledText {
                            text: "Up"
                            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                            color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                        }
                    }
                    StyledText {
                        readonly property var fmt: NetworkUsage.formatBytes(NetworkUsage.uploadSpeed)
                        text: `${fmt.value < 10 ? fmt.value.toFixed(1) : Math.round(fmt.value)} ${fmt.unit}`
                        font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                        font.weight: Font.DemiBold
                        font.family: Appearance?.font.family.numbers
                        color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                    }
                    StyledText {
                        readonly property var tot: NetworkUsage.formatBytesTotal(NetworkUsage.uploadTotal)
                        text: `Total ${tot.value < 10 ? tot.value.toFixed(1) : Math.round(tot.value)} ${tot.unit}`
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                    }
                }
            }
        }

        // ── VPN ───────────────────────────────────────────────────────
        Loader {
            Layout.fillWidth: true
            active: root.showVpn
            visible: active
            sourceComponent: RowLayout {
                spacing: 8

                MaterialSymbol {
                    text: VPN.connected ? "vpn_lock" : (VPN.connecting ? "vpn_key" : "vpn_key_off")
                    iconSize: 22
                    color: VPN.connected
                        ? (Appearance?.colors.colPrimary ?? "#65558F")
                        : (Appearance?.colors.colSubtext ?? "#CAC4D0")
                    fill: VPN.connected ? 1 : 0
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    StyledText {
                        text: (VPN.currentConfig?.displayName) || VPN.providerName || "VPN"
                        font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                        font.weight: Font.DemiBold
                        color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: VPN.connecting
                            ? "Connecting…"
                            : VPN.connected
                                ? "Connected"
                                : (VPN.status?.state === "needs-auth"
                                    ? "Sign-in required"
                                    : (VPN.status?.reason || "Disconnected"))
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Toggle button
                Rectangle {
                    implicitWidth: toggleRow.implicitWidth + 16
                    implicitHeight: 32
                    radius: height / 2
                    color: VPN.connected
                        ? Qt.rgba((Appearance?.colors.colPrimary?.r ?? 0.4),
                                  (Appearance?.colors.colPrimary?.g ?? 0.33),
                                  (Appearance?.colors.colPrimary?.b ?? 0.56), 0.2)
                        : Appearance?.colors.colLayer2 ?? "#2B2930"
                    opacity: VPN.connecting ? 0.6 : 1
                    Behavior on color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        id: toggleRow
                        anchors.centerIn: parent
                        spacing: 4
                        StyledText {
                            text: VPN.connecting
                                ? "…"
                                : VPN.connected ? "Disconnect" : "Connect"
                            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                            font.weight: Font.DemiBold
                            color: VPN.connected
                                ? (Appearance?.colors.colPrimary ?? "#65558F")
                                : (Appearance?.colors.colOnLayer1 ?? "#E6E1E5")
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: VPN.connecting ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !VPN.connecting
                        onClicked: VPN.toggle()
                    }
                }
            }
        }
    }
}

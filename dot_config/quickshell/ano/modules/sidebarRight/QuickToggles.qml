import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * Quick toggle grid — WiFi, Bluetooth, DND, Idle inhibit, Night light.
 * Inspired by ilyamiro's SysPill system and Android-style toggle panels.
 */
Rectangle {
    id: root
    property bool nightLightExpanded: false

    implicitHeight: contentCol.implicitHeight + 16
    radius: Appearance?.rounding.normal ?? 12
    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

    ColumnLayout {
        id: contentCol
        anchors { fill: parent; margins: 8 }
        spacing: 6

    GridLayout {
        id: toggleGrid
        Layout.fillWidth: true
        columns: 3; columnSpacing: 6; rowSpacing: 6

        // WiFi
        TogglePill {
            iconName: Network.materialSymbol
            label: Network.wifi ? Network.networkName : (Network.wifiEnabled ? "Disconnected" : "Off")
            active: Network.wifi
            activeColor: Appearance?.colors.colPrimary ?? "#65558F"
            onClicked: Network.toggleWifi()
            Layout.fillWidth: true
        }

        // Hotspot — broadcasts a WiFi network from this machine. SSID +
        // password configured via Config.options.network.hotspot. Password
        // auto-generated on first enable when empty.
        TogglePill {
            iconName: Network.hotspotActive ? "wifi_tethering" : "wifi_tethering_off"
            label: Network.hotspotBusy ? "..." : (Network.hotspotActive ? "Hotspot" : "Off")
            active: Network.hotspotActive
            activeColor: "#FFA726"
            onClicked: Network.toggleHotspot()
            Layout.fillWidth: true
        }

        // Bluetooth
        TogglePill {
            iconName: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
            label: BluetoothStatus.connected ? `${BluetoothStatus.activeDeviceCount} dev` : (BluetoothStatus.enabled ? "On" : "Off")
            active: BluetoothStatus.connected
            activeColor: "#B388FF"
            visible: BluetoothStatus.available
            Layout.fillWidth: true
        }

        // DND
        TogglePill {
            iconName: Notifications.silent ? "notifications_paused" : "notifications_active"
            label: Notifications.silent ? "Silent" : "Alerts"
            active: Notifications.silent
            activeColor: "#FFB74D"
            onClicked: Notifications.silent = !Notifications.silent
            Layout.fillWidth: true
        }

        // Idle inhibit
        TogglePill {
            iconName: Idle.inhibit ? "coffee" : "coffee_maker"
            label: Idle.inhibit ? "Awake" : "Idle"
            active: Idle.inhibit
            activeColor: "#4DB6AC"
            onClicked: Idle.toggleInhibit()
            Layout.fillWidth: true
        }

        // Night light — tap pill to toggle, chevron to expand inline slider
        TogglePill {
            iconName: NightLight.enabled ? "nightlight" : "wb_sunny"
            label: NightLight.enabled
                ? `${NightLight.nightTemp}K`
                : "Day"
            active: NightLight.enabled
            activeColor: "#FFB74D"
            onClicked: NightLight.toggle()
            showChevron: true
            chevronRotation: root.nightLightExpanded ? 180 : 0
            onChevronClicked: root.nightLightExpanded = !root.nightLightExpanded
            Layout.fillWidth: true
        }

        // Battery (if laptop)
        Loader {
            Layout.fillWidth: true
            active: Battery.available
            visible: active
            sourceComponent: TogglePill {
                iconName: Battery.isCharging ? "battery_charging_full" : (Battery.percentage > 0.2 ? "battery_full" : "battery_alert")
                label: `${Math.round(Battery.percentage * 100)}%`
                active: Battery.isCharging
                activeColor: "#81C784"
            }
        }

        // Keyboard layout
        Loader {
            Layout.fillWidth: true
            active: KeyboardLayoutService.layoutCodes.length > 1
            visible: active
            sourceComponent: TogglePill {
                iconName: "keyboard"
                label: KeyboardLayoutService.currentLayoutCode.toUpperCase()
                active: false
            }
        }
    }

        // ── Night light inline expander ──
        // Animated reveal of a temperature slider when the night-light pill's
        // chevron is tapped. Stays out of the layout entirely when collapsed.
        Item {
            Layout.fillWidth: true
            clip: true
            implicitHeight: root.nightLightExpanded ? expanderCol.implicitHeight + 8 : 0
            opacity: root.nightLightExpanded ? 1 : 0
            Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180 } }

            ColumnLayout {
                id: expanderCol
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 4 }
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    MaterialSymbol {
                        text: "thermostat"; iconSize: 16
                        color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                    }
                    StyledText {
                        text: `${NightLight.nightTemp}K`
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        font.family: Appearance?.font.family.numbers
                        color: NightLight.enabled
                            ? "#FFB74D"
                            : (Appearance?.colors.colOnLayer1 ?? "#E6E1E5")
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: NightLight.enabled ? "On" : "Off"
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        opacity: 0.7
                        color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                    }
                }

                Slider {
                    id: tempSlider
                    Layout.fillWidth: true
                    from: 2500; to: 6500; stepSize: 100
                    value: NightLight.nightTemp
                    onMoved: Config.setNestedValue("nightLight.nightTemp", Math.round(value))
                }
            }
        }
    }

    // Toggle pill component
    component TogglePill: Rectangle {
        id: pill
        property string iconName: ""
        property string label: ""
        property bool active: false
        property color activeColor: Appearance?.colors.colPrimary ?? "#65558F"
        property bool showChevron: false
        property real chevronRotation: 0
        signal clicked()
        signal chevronClicked()

        implicitHeight: 44
        radius: Appearance?.rounding.small ?? 8
        color: active ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.2) : Appearance?.colors.colLayer2 ?? "#2B2930"
        border.width: active ? 1 : 0
        border.color: Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.4)

        Behavior on color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol {
                text: pill.iconName; iconSize: 18
                fill: pill.active ? 1 : 0
                color: pill.active ? pill.activeColor : Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
            }
            StyledText {
                text: pill.label
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.maximumWidth: pill.showChevron ? 50 : 70
                color: pill.active ? pill.activeColor : Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
            }
            MaterialSymbol {
                visible: pill.showChevron
                text: "expand_more"; iconSize: 16
                rotation: pill.chevronRotation
                color: pill.active ? pill.activeColor : Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pill.chevronClicked()
                }
            }
        }

        // Main click area excludes the chevron region when one is shown
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: pill.showChevron ? 26 : 0
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }
}

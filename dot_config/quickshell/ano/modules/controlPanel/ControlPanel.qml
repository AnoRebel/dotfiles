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
 * Control Panel — floating quick-access panel with system controls.
 * Shows quick toggles, sliders, media, battery, and network at a glance.
 * This is a standalone overlay distinct from the right sidebar — more like
 * Android's notification shade or macOS Control Center.
 *
 * Triggered via IPC, keybind, or bar click action "controlPanel".
 */
Scope {
    id: root

    IpcHandler {
        target: "controlPanel"
        function toggle(): void { GlobalStates.controlPanelOpen = !GlobalStates.controlPanelOpen }
        function open(): void { GlobalStates.controlPanelOpen = true }
        function close(): void { GlobalStates.controlPanelOpen = false }
    }

    PanelWindow {
        id: cpWindow
        visible: GlobalStates.controlPanelOpen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:controlPanel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.controlPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }
        Keys.onPressed: event => { if (event.key === Qt.Key_Escape) GlobalStates.controlPanelOpen = false }

        Rectangle {
            anchors.fill: parent; color: "#000000"
            opacity: GlobalStates.controlPanelOpen ? 0.4 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MouseArea { anchors.fill: parent; onClicked: GlobalStates.controlPanelOpen = false }
        }

        // Panel card — positioned at top-right like a notification shade
        Rectangle {
            id: cpCard
            anchors { top: parent.top; right: parent.right; margins: (Config.options?.appearance?.bezel ?? 0) + 8 }
            anchors.topMargin: (Config.options?.bar?.layout?.height ?? 42) + (Config.options?.appearance?.bezel ?? 0) + 12
            width: Math.min(380, parent.width * 0.4)
            height: Math.min(cpContent.implicitHeight + 32, parent.height * 0.7)
            radius: Appearance?.rounding.windowRounding ?? 20
            color: Appearance?.m3colors.m3background ?? "#1C1B1F"
            border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
            clip: true

            opacity: GlobalStates.controlPanelOpen ? 1 : 0
            transform: Translate { y: GlobalStates.controlPanelOpen ? 0 : -20 }
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            StyledFlickable {
                anchors { fill: parent; margins: 16 }
                contentHeight: cpContent.implicitHeight
                clip: true

                ColumnLayout {
                    id: cpContent
                    width: parent.width; spacing: 12

                    // User + time header
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        StyledText {
                            text: DateTime.time
                            font.pixelSize: Appearance?.font.pixelSize.huger ?? 24
                            font.weight: Font.Bold
                            font.family: Appearance?.font.family.numbers ?? "monospace"
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: DateTime.shortDate
                            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                            opacity: 0.5
                        }
                    }

                    // Quick toggles (compact 2x3 grid)
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3; columnSpacing: 6; rowSpacing: 6

                        CPToggle { iconName: Network.materialSymbol; label: Network.wifi ? Network.networkName : "WiFi"; active: Network.wifi; onClicked: Network.toggleWifi() }
                        CPToggle { iconName: BluetoothStatus.connected ? "bluetooth_connected" : "bluetooth"; label: "Bluetooth"; active: BluetoothStatus.connected; visible: BluetoothStatus.available }
                        CPToggle { iconName: Notifications.silent ? "notifications_paused" : "notifications_active"; label: Notifications.silent ? "Silent" : "Alerts"; active: Notifications.silent; onClicked: Notifications.silent = !Notifications.silent }
                        CPToggle { iconName: Idle.inhibit ? "coffee" : "coffee_maker"; label: Idle.inhibit ? "Awake" : "Idle"; active: Idle.inhibit; onClicked: Idle.toggleInhibit() }
                        CPToggle { iconName: "dark_mode"; label: "Night"; active: false }
                        CPToggle { iconName: "settings"; label: "Settings"; active: false; onClicked: { GlobalStates.controlPanelOpen = false; GlobalStates.settingsOpen = true } }
                    }

                    // Sliders
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: sliderCol.implicitHeight + 16
                        radius: Appearance?.rounding.normal ?? 12
                        color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                        ColumnLayout {
                            id: sliderCol
                            anchors { fill: parent; margins: 8 }
                            spacing: 10

                            RowLayout {
                                spacing: 8
                                MaterialSymbol { text: "brightness_6"; iconSize: 18; color: Appearance?.colors.colPrimary ?? "#65558F" }
                                StyledSlider { Layout.fillWidth: true; configuration: StyledSlider.Configuration.S; value: Brightness.monitors[0]?.brightness ?? 0; onMoved: Brightness.monitors[0]?.setBrightness(value); stopIndicatorValues: [] }
                            }
                            RowLayout {
                                spacing: 8
                                MaterialSymbol {
                                    text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"; iconSize: 18
                                    color: Audio.sink?.audio?.muted ? Appearance?.m3colors.m3error ?? "#BA1A1A" : Appearance?.colors.colPrimary ?? "#65558F"
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Audio.toggleMute() }
                                }
                                StyledSlider { Layout.fillWidth: true; configuration: StyledSlider.Configuration.S; value: Audio.sink?.audio?.volume ?? 0; onMoved: { if (Audio.sink?.audio) Audio.sink.audio.volume = value }
                                stopIndicatorValues: [1] }
                            }
                        }
                    }

                    // Media (if playing)
                    Loader {
                        Layout.fillWidth: true
                        active: MprisController.activePlayer != null; visible: active
                        sourceComponent: Rectangle {
                            implicitHeight: mediaRow.implicitHeight + 16
                            radius: Appearance?.rounding.normal ?? 12
                            color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
                            RowLayout {
                                id: mediaRow; anchors { fill: parent; margins: 8 }
                                spacing: 10
                                MaterialSymbol { text: MprisController.isPlaying ? "music_note" : "pause"; iconSize: 20; fill: 1; color: Appearance?.colors.colPrimary ?? "#65558F" }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 1
                                    StyledText { text: MprisController.activeTrack?.title ?? ""; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                                    StyledText { text: MprisController.activeTrack?.artist ?? ""; font.pixelSize: 11; opacity: 0.4; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                ToolbarButton { iconName: "skip_previous"; iconSize: 18; onClicked: MprisController.previous() }
                                ToolbarButton { iconName: MprisController.isPlaying ? "pause" : "play_arrow"; iconSize: 20; onClicked: MprisController.togglePlaying() }
                                ToolbarButton { iconName: "skip_next"; iconSize: 18; onClicked: MprisController.next() }
                            }
                        }
                    }

                    // System gauges (compact)
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        CombinedCircularProgress {
                            implicitSize: 40; outerLineWidth: 3; innerLineWidth: 3
                            outerValue: ResourceUsage.cpuUsage; innerValue: ResourceUsage.memoryUsedPercentage
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            StyledText { text: `CPU ${Math.round(ResourceUsage.cpuUsage * 100)}% • RAM ${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`; font.pixelSize: 12; font.family: Appearance?.font.family.mono ?? "monospace" }
                            StyledText { text: `Up ${DateTime.uptime}`; font.pixelSize: 10; opacity: 0.3 }
                        }
                        Loader {
                            active: Battery.available; visible: active
                            sourceComponent: RowLayout {
                                spacing: 4
                                CircularProgress { implicitSize: 24; lineWidth: 2; value: Battery.percentage; colPrimary: Battery.isCharging ? "#81C784" : Appearance?.colors.colPrimary ?? "#65558F" }
                                StyledText { text: `${Math.round(Battery.percentage * 100)}%`; font.pixelSize: 12; font.family: Appearance?.font.family.mono ?? "monospace" }
                            }
                        }
                    }

                    // Power row
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        Item { Layout.fillWidth: true }
                        ToolbarButton { iconName: "lock"; iconSize: 18; toolTipText: "Lock"; onClicked: { GlobalStates.controlPanelOpen = false; Quickshell.execDetached(["loginctl", "lock-session"]) } }
                        ToolbarButton { iconName: "power_settings_new"; iconSize: 18; toolTipText: "Session"; onClicked: { GlobalStates.controlPanelOpen = false; GlobalStates.sessionOpen = true } }
                    }
                }
            }
        }
    }

    component CPToggle: Rectangle {
        property string iconName: ""; property string label: ""; property bool active: false
        signal clicked()
        Layout.fillWidth: true; implicitHeight: 44
        radius: Appearance?.rounding.small ?? 8
        color: active ? Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.2) : Appearance?.colors.colLayer1 ?? "#E5E1EC"
        border.width: active ? 1 : 0; border.color: Appearance?.colors.colPrimary ?? "#65558F"
        Behavior on color { ColorAnimation { duration: 150 } }
        ColumnLayout { anchors.centerIn: parent; spacing: 1
            MaterialSymbol { text: iconName; iconSize: 18; fill: active ? 1 : 0; color: active ? Appearance?.colors.colPrimary ?? "#65558F" : Appearance?.colors.colOnLayer1 ?? "#E6E1E5"; Layout.alignment: Qt.AlignHCenter }
            StyledText { text: label; font.pixelSize: 10; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.maximumWidth: 80; Layout.alignment: Qt.AlignHCenter; color: active ? Appearance?.colors.colPrimary ?? "#65558F" : Appearance?.colors.colOnLayer1 ?? "#E6E1E5" }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }
}

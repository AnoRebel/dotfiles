import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Session/Power screen — fullscreen overlay with lock, logout, suspend, reboot, shutdown.
 * Each button requires a hold-to-confirm (progress ring fills as you hold).
 * Inspired by ilyamiro's battery popup power actions.
 */
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: sessionWindow
            required property var modelData
            screen: modelData

            visible: GlobalStates.sessionOpen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.sessionOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            Keys.onPressed: event => { if (event.key === Qt.Key_Escape) GlobalStates.sessionOpen = false }

            // Blurred dim backdrop
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: GlobalStates.sessionOpen ? 0.7 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                MouseArea { anchors.fill: parent; onClicked: GlobalStates.sessionOpen = false }
            }

            // Content
            Item {
                anchors.centerIn: parent
                width: 600; height: 350
                opacity: GlobalStates.sessionOpen ? 1 : 0
                scale: GlobalStates.sessionOpen ? 1 : 0.85
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 32

                    // User avatar + greeting
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        // Circular avatar
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 72; height: 72; radius: 36
                            color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
                            border.width: 2; border.color: Appearance?.colors.colPrimary ?? "#65558F"

                            Image {
                                anchors.centerIn: parent
                                width: 64; height: 64
                                source: `file://${Directories.userAvatarPathFace}`
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle { width: 64; height: 64; radius: 32 }
                                }
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "person"; iconSize: 36
                                color: Appearance?.colors.colPrimary ?? "#65558F"
                                visible: parent.children[0].status !== Image.Ready
                            }
                        }

                        StyledText {
                            text: Quickshell.env("USER") || "user"
                            font.pixelSize: Appearance?.font.pixelSize.huger ?? 24
                            font.weight: Font.Bold
                            color: "white"
                            font.capitalization: Font.Capitalize
                            Layout.alignment: Qt.AlignHCenter
                        }
                        StyledText {
                            text: `Up ${DateTime.uptime}`
                            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                            color: "white"; opacity: 0.5
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // Power action buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20

                        SessionButton {
                            iconName: "lock"
                            label: "Lock"
                            accentColor: "#42A5F5"
                            holdDuration: 500
                            onActivated: { GlobalStates.sessionOpen = false; Quickshell.execDetached(["loginctl", "lock-session"]) }
                        }
                        SessionButton {
                            iconName: "logout"
                            label: "Logout"
                            accentColor: "#FFB74D"
                            holdDuration: 1200
                            onActivated: {
                                GlobalStates.sessionOpen = false
                                if (CompositorService.compositor === "hyprland") Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                                else Quickshell.execDetached(["loginctl", "terminate-session", Quickshell.env("XDG_SESSION_ID") || ""])
                            }
                        }
                        SessionButton {
                            iconName: "dark_mode"
                            label: "Sleep"
                            accentColor: "#AB47BC"
                            holdDuration: 1000
                            onActivated: { GlobalStates.sessionOpen = false; Quickshell.execDetached(["systemctl", "suspend"]) }
                        }
                        SessionButton {
                            iconName: "restart_alt"
                            label: "Reboot"
                            accentColor: "#66BB6A"
                            holdDuration: 2000
                            onActivated: { GlobalStates.sessionOpen = false; Quickshell.execDetached(["systemctl", "reboot"]) }
                        }
                        SessionButton {
                            iconName: "power_settings_new"
                            label: "Shutdown"
                            accentColor: "#EF5350"
                            holdDuration: 2500
                            onActivated: { GlobalStates.sessionOpen = false; Quickshell.execDetached(["systemctl", "poweroff"]) }
                        }
                    }

                    // Hint
                    StyledText {
                        text: "Hold to confirm • Press Escape to cancel"
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        color: "white"; opacity: 0.3
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    // Hold-to-confirm button with circular progress fill
    component SessionButton: Item {
        id: btn
        property string iconName: ""
        property string label: ""
        property color accentColor: "#65558F"
        property int holdDuration: 1500
        signal activated()

        width: 80; height: 100

        property real holdProgress: 0
        property bool isHolding: false

        NumberAnimation {
            id: holdAnim
            target: btn; property: "holdProgress"
            from: 0; to: 1; duration: btn.holdDuration
            easing.type: Easing.Linear
        }

        onHoldProgressChanged: {
            if (holdProgress >= 1) {
                holdProgress = 0
                isHolding = false
                holdAnim.stop()
                btn.activated()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 6

            // Button circle with progress ring
            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 64; height: 64

                // Background circle
                Rectangle {
                    anchors.fill: parent; radius: 32
                    color: Qt.rgba(btn.accentColor.r, btn.accentColor.g, btn.accentColor.b, btnMA.containsMouse || btn.isHolding ? 0.25 : 0.1)
                    border.width: 2
                    border.color: Qt.rgba(btn.accentColor.r, btn.accentColor.g, btn.accentColor.b, 0.4)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    scale: btnMA.pressed ? 0.92 : (btnMA.containsMouse ? 1.05 : 1)
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }

                // Progress ring (fills as you hold)
                Canvas {
                    id: holdCanvas
                    anchors.fill: parent
                    visible: btn.holdProgress > 0
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.beginPath()
                        ctx.arc(width / 2, height / 2, width / 2 - 3, -Math.PI / 2, -Math.PI / 2 + (btn.holdProgress * 2 * Math.PI))
                        ctx.strokeStyle = btn.accentColor
                        ctx.lineWidth = 4
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }
                    // Repaint whenever btn.holdProgress ticks. The earlier
                    // dual-handler version had an unattached onHoldProgressChanged
                    // on Canvas (Canvas has no such signal) — Quickshell 0.3
                    // flagged it. One Connections targeting btn is enough.
                    Connections {
                        target: btn
                        function onHoldProgressChanged() { holdCanvas.requestPaint() }
                    }
                }

                // Icon
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: btn.iconName; iconSize: 28; fill: btn.isHolding ? 1 : 0
                    color: btn.isHolding ? btn.accentColor : "white"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: btnMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: { btn.isHolding = true; btn.holdProgress = 0; holdAnim.start() }
                    onReleased: { btn.isHolding = false; holdAnim.stop(); btn.holdProgress = 0 }
                    onCanceled: { btn.isHolding = false; holdAnim.stop(); btn.holdProgress = 0 }
                }
            }

            StyledText {
                text: btn.label
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                font.weight: Font.DemiBold
                color: btn.isHolding ? btn.accentColor : "white"
                Layout.alignment: Qt.AlignHCenter
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }

    IpcHandler {
        target: "session"
        function toggle(): void { GlobalStates.sessionOpen = !GlobalStates.sessionOpen }
        function open(): void { GlobalStates.sessionOpen = true }
        function close(): void { GlobalStates.sessionOpen = false }
    }
}

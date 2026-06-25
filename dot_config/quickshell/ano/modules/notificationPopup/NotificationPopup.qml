import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Floating notification popups. Appear at a configurable screen corner,
 * stack vertically with stagger animation, auto-dismiss on timeout,
 * swipe/click to dismiss. Per-screen aware.
 */
Scope {
    id: root

    readonly property string position: Config.options?.notifications?.position ?? "topRight"
    readonly property bool isTop: position.startsWith("top")
    readonly property bool isLeft: position.endsWith("Left")
    readonly property int edgeMargin: Config.options?.notifications?.edgeMargin ?? 8

    PanelWindow {
        id: popupWindow
        visible: Notifications.popupList.length > 0 && !GlobalStates.screenLocked

        screen: {
            if (CompositorService.compositor === "niri")
                return Quickshell.screens.find(s => s.name === NiriService.currentOutput) ?? Quickshell.screens[0]
            return Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        }

        WlrLayershell.namespace: "quickshell:notifPopup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: 380
        implicitHeight: Math.min(notifColumn.implicitHeight + root.edgeMargin * 2, (screen?.height ?? 1080) * 0.6)

        anchors {
            top: root.isTop
            bottom: !root.isTop
            left: root.isLeft
            right: !root.isLeft
        }

        margins {
            top: root.isTop ? root.edgeMargin : 0
            bottom: !root.isTop ? root.edgeMargin : 0
            left: root.isLeft ? root.edgeMargin : 0
            right: !root.isLeft ? root.edgeMargin : 0
        }

        mask: Region { item: notifColumn }

        ColumnLayout {
            id: notifColumn
            anchors {
                top: root.isTop ? parent.top : undefined
                bottom: !root.isTop ? parent.bottom : undefined
                left: root.isLeft ? parent.left : undefined
                right: !root.isLeft ? parent.right : undefined
                margins: root.edgeMargin
            }
            width: popupWindow.implicitWidth - root.edgeMargin * 2
            spacing: 6
            layoutDirection: Qt.LeftToRight

            // Staggered notification items
            Repeater {
                model: Notifications.popupList

                Item {
                    id: popupDelegate
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: notifCard.implicitHeight
                    clip: true

                    // Entry animation — slide in from edge + fade
                    property real slideOffset: root.isLeft ? -20 : 20
                    property real entryOpacity: 0

                    Component.onCompleted: {
                        entryTimer.interval = index * 40 // Stagger each notification
                        entryTimer.start()
                    }
                    Timer {
                        id: entryTimer
                        onTriggered: { popupDelegate.slideOffset = 0; popupDelegate.entryOpacity = 1 }
                    }

                    opacity: entryOpacity
                    transform: Translate { x: popupDelegate.slideOffset }
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on transform { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    // Swipe to dismiss tracking
                    property real swipeX: 0
                    property bool swiping: false

                    // Notification card with shadow
                    Rectangle {
                        id: notifCard
                        width: parent.width
                        x: popupDelegate.swipeX
                        implicitHeight: cardContent.implicitHeight + 20
                        radius: Appearance?.rounding.normal ?? 12
                        color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
                        border.width: 1
                        border.color: Appearance?.colors.colLayer0Border ?? "#44444488"

                        // Subtle shadow
                        layer.enabled: true
                        layer.effect: StyledDropShadow { radius: 12; verticalOffset: 3 }

                        // Hover glow
                        Rectangle {
                            anchors.fill: parent; radius: parent.radius
                            color: "transparent"
                            border.width: cardHover.containsMouse ? 1 : 0
                            border.color: Appearance?.colors.colPrimary ?? "#65558F"
                            Behavior on border.width { NumberAnimation { duration: 100 } }
                        }

                        RowLayout {
                            id: cardContent
                            anchors { fill: parent; margins: 10 }
                            spacing: 10

                            // App icon
                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                width: 32; height: 32; radius: 16
                                color: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"

                                StyledImage {
                                    anchors.centerIn: parent; width: 20; height: 20
                                    source: modelData?.image?.length > 0 ? modelData.image : modelData?.appIcon?.length > 0 ? modelData.appIcon : ""
                                    visible: source.toString().length > 0
                                }
                                MaterialSymbol {
                                    anchors.centerIn: parent; text: "notifications"; iconSize: 16
                                    visible: !parent.children[0].visible
                                    color: Appearance?.m3colors.m3onSecondaryContainer ?? "#1D1B20"
                                }
                            }

                            // Content
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: modelData?.summary ?? ""
                                        font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight; Layout.fillWidth: true
                                    }
                                    StyledText {
                                        text: modelData?.appName ?? ""
                                        font.pixelSize: 10; opacity: 0.4
                                    }
                                }

                                StyledText {
                                    text: modelData?.body ?? ""
                                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                                    wrapMode: Text.Wrap; maximumLineCount: 3
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                    visible: text.length > 0
                                }

                                // Actions
                                RowLayout {
                                    spacing: 4; visible: (modelData?.actions?.length ?? 0) > 0
                                    Layout.fillWidth: true
                                    Repeater {
                                        model: modelData?.actions ?? []
                                        RippleButton {
                                            required property var modelData
                                            buttonText: modelData.text
                                            buttonRadius: 4; implicitHeight: 24
                                            colBackground: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
                                            onClicked: Notifications.attemptInvokeAction(popupDelegate.modelData.notificationId, modelData.identifier)
                                        }
                                    }
                                }
                            }

                            // Dismiss X
                            ToolbarButton {
                                Layout.alignment: Qt.AlignTop
                                iconName: "close"; iconSize: 14
                                implicitWidth: 24; implicitHeight: 24
                                onClicked: Notifications.discardNotification(modelData.notificationId)
                            }
                        }

                        // Click to open sidebar
                        MouseArea {
                            id: cardHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            z: -1 // Below dismiss button
                            onClicked: {
                                Notifications.timeoutNotification(modelData.notificationId)
                                GlobalStates.sidebarLeftOpen = true
                            }

                            // Swipe handling
                            property real pressX: 0
                            onPressed: mouse => { pressX = mouse.x; popupDelegate.swiping = true }
                            onPositionChanged: mouse => {
                                if (popupDelegate.swiping) {
                                    popupDelegate.swipeX = mouse.x - pressX
                                }
                            }
                            onReleased: {
                                popupDelegate.swiping = false
                                if (Math.abs(popupDelegate.swipeX) > 100) {
                                    Notifications.discardNotification(modelData.notificationId)
                                } else {
                                    popupDelegate.swipeX = 0
                                }
                            }
                        }
                        Behavior on x { enabled: !popupDelegate.swiping; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}

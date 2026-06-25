import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * Left sidebar content — tabbed view: AI Chat | Notifications + media player.
 */
Rectangle {
    id: root
    color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
    radius: Appearance?.rounding.normal ?? 12
    border.width: 1
    border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
    clip: true

    property int currentTab: 0 // 0 = AI Chat, 1 = Notifications, 2 = Translator

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Tab switcher
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            GroupButton {
                label: "AI"
                iconName: "neurology"
                toggled: root.currentTab === 0
                onClicked: root.currentTab = 0
                Layout.fillWidth: true
            }
            GroupButton {
                label: "Notifs"
                iconName: "notifications"
                toggled: root.currentTab === 1
                onClicked: root.currentTab = 1
                Layout.fillWidth: true

                // Unread badge
                Rectangle {
                    visible: Notifications.unread > 0
                    anchors { top: parent.top; right: parent.right; margins: -2 }
                    width: 16; height: 16; radius: 8
                    color: Appearance?.colors.colPrimary ?? "#65558F"
                    StyledText {
                        anchors.centerIn: parent
                        text: Notifications.unread > 9 ? "9+" : `${Notifications.unread}`
                        font.pixelSize: 9; color: Appearance?.m3colors.m3onPrimary ?? "white"
                    }
                }
            }

            GroupButton {
                label: "Translate"
                iconName: "translate"
                toggled: root.currentTab === 2
                onClicked: root.currentTab = 2
                Layout.fillWidth: true
            }
        }

        // Tab content
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // AI Chat tab
            Loader {
                anchors.fill: parent
                active: root.currentTab === 0
                visible: active
                sourceComponent: AiChat {}
            }

            // Notifications tab
            Loader {
                anchors.fill: parent
                active: root.currentTab === 1
                visible: active
                sourceComponent: ColumnLayout {
                    spacing: 8

                    // Notification header
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: "Notifications"
                            font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }
                        ToolbarButton {
                            iconName: Notifications.silent ? "notifications_paused" : "notifications_active"
                            iconSize: 18; toolTipText: Notifications.silent ? "Unmute" : "Mute"
                            onClicked: Notifications.silent = !Notifications.silent
                        }
                        ToolbarButton {
                            iconName: "delete_sweep"; iconSize: 18; toolTipText: "Clear all"
                            onClicked: Notifications.discardAllNotifications()
                        }
                    }

                    // Notification list
                    StyledFlickable {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        contentHeight: notifColumn.implicitHeight; clip: true

                        ColumnLayout {
                            id: notifColumn
                            width: parent.width; spacing: 6

                            StyledText {
                                visible: Notifications.list.length === 0
                                text: "No notifications"
                                font.pixelSize: Appearance?.font.pixelSize.small ?? 14; opacity: 0.5
                                Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 40
                            }

                            Repeater {
                                model: Notifications.appNameList
                                ColumnLayout {
                                    required property string modelData
                                    Layout.fillWidth: true; spacing: 4
                                    StyledText {
                                        text: modelData
                                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                                        font.weight: Font.DemiBold
                                        color: Appearance?.colors.colPrimary ?? "#65558F"
                                        Layout.fillWidth: true
                                    }
                                    Repeater {
                                        model: Notifications.groupsByAppName[modelData]?.notifications ?? []
                                        NotificationItem {
                                            required property var modelData
                                            notification: modelData; Layout.fillWidth: true
                                            onDismissed: id => Notifications.discardNotification(id)
                                            onActionInvoked: (id, identifier) => Notifications.attemptInvokeAction(id, identifier)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Compact media player
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? mediaCol.implicitHeight + 16 : 0
                        visible: MprisController.activePlayer != null
                        color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
                        radius: Appearance?.rounding.normal ?? 12

                        ColumnLayout {
                            id: mediaCol
                            anchors { fill: parent; margins: 8 }
                            spacing: 4
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                StyledText { text: MprisController.activeTrack?.title ?? ""; font.pixelSize: Appearance?.font.pixelSize.small ?? 14; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                                StyledText { text: MprisController.activeTrack?.artist ?? ""; font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12; opacity: 0.6; elide: Text.ElideRight; Layout.maximumWidth: 120 }
                            }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 4; Layout.alignment: Qt.AlignHCenter
                                ToolbarButton { iconName: "skip_previous"; iconSize: 20; onClicked: MprisController.previous(); enabled: MprisController.canGoPrevious }
                                ToolbarButton { iconName: MprisController.isPlaying ? "pause" : "play_arrow"; iconSize: 24; onClicked: MprisController.togglePlaying(); enabled: MprisController.canTogglePlaying }
                                ToolbarButton { iconName: "skip_next"; iconSize: 20; onClicked: MprisController.next(); enabled: MprisController.canGoNext }
                            }
                        }
                    }
                }
            }

            // Translator tab
            Loader {
                anchors.fill: parent
                active: root.currentTab === 2
                visible: active
                sourceComponent: Translator {}
            }
        }
    }
}

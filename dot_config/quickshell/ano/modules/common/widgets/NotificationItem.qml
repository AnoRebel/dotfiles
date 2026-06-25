pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * A single notification item with icon, summary, body, actions, and dismiss.
 */
Item {
    id: root
    required property var notification
    property bool compact: false
    property bool showActions: true

    signal dismissed(int notificationId)
    signal actionInvoked(int notificationId, string identifier)

    implicitWidth: parent?.width ?? 360
    implicitHeight: layout.implicitHeight + 16

    Rectangle {
        anchors.fill: parent
        radius: Appearance?.rounding.normal ?? 12
        color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

        RowLayout {
            id: layout
            anchors { fill: parent; margins: 8 }
            spacing: 8

            // App icon
            Rectangle {
                Layout.alignment: Qt.AlignTop
                width: 36; height: 36
                radius: 18
                color: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"

                StyledImage {
                    anchors.centerIn: parent
                    width: 24; height: 24
                    source: root.notification?.image?.length > 0
                        ? root.notification.image
                        : root.notification?.appIcon?.length > 0
                            ? root.notification.appIcon : ""
                    visible: source.toString().length > 0
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "notifications"
                    iconSize: 20
                    visible: parent.children[0].source?.toString().length === 0
                    color: Appearance?.m3colors.m3onSecondaryContainer ?? "#1D1B20"
                }
            }

            // Content
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: root.notification?.summary ?? ""
                        font.weight: Font.DemiBold
                        font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: root.notification?.appName ?? ""
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        opacity: 0.5
                        visible: !root.compact
                    }
                }

                StyledText {
                    text: root.notification?.body ?? ""
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
                    wrapMode: Text.Wrap
                    maximumLineCount: root.compact ? 2 : 6
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text.length > 0
                }

                // Actions
                RowLayout {
                    spacing: 4
                    visible: root.showActions && (root.notification?.actions?.length ?? 0) > 0
                    Layout.fillWidth: true
                    Repeater {
                        model: root.notification?.actions ?? []
                        RippleButton {
                            required property var modelData
                            buttonText: modelData.text
                            buttonRadius: Appearance?.rounding.verysmall ?? 4
                            implicitHeight: 28
                            colBackground: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
                            onClicked: root.actionInvoked(root.notification.notificationId, modelData.identifier)
                        }
                    }
                }
            }

            // Dismiss
            ToolbarButton {
                Layout.alignment: Qt.AlignTop
                iconName: "close"
                iconSize: 16
                implicitWidth: 28; implicitHeight: 28
                onClicked: root.dismissed(root.notification.notificationId)
            }
        }
    }
}

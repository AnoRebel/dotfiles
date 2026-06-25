import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * Compact notification center for right sidebar.
 * Shows recent notifications grouped by app.
 */
Rectangle {
    id: root
    implicitHeight: notifCol.implicitHeight + 20
    radius: Appearance?.rounding.normal ?? 12
    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
    visible: Notifications.list.length > 0

    ColumnLayout {
        id: notifCol
        anchors { fill: parent; margins: 10 }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "Notifications"
                font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            StyledText {
                text: `${Notifications.list.length}`
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                opacity: 0.5
            }
            ToolbarButton {
                iconName: "delete_sweep"; iconSize: 16
                toolTipText: "Clear all"
                onClicked: Notifications.discardAllNotifications()
            }
        }

        // Show max 5 most recent
        Repeater {
            model: Notifications.list.slice(-5).reverse()

            NotificationItem {
                required property var modelData
                notification: modelData
                compact: true
                showActions: false
                Layout.fillWidth: true
                onDismissed: id => Notifications.discardNotification(id)
                onActionInvoked: (id, identifier) => Notifications.attemptInvokeAction(id, identifier)
            }
        }
    }
}

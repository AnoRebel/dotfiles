import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import QtQuick
import QtQuick.Layouts

/**
 * Notification indicator with morph-capable popout showing recent notifications.
 */
Item {
    id: root
    visible: Notifications.silent || Notifications.unread > 0 || Notifications.list.length > 0
    implicitWidth: visible ? nRow.implicitWidth + 8 : 0
    implicitHeight: Appearance.sizes.barHeight
    property bool hovered: notifMA.containsMouse

    RowLayout {
        id: nRow; anchors.centerIn: parent; spacing: 2
        MaterialSymbol {
            text: Notifications.silent ? "notifications_paused" : "notifications"
            iconSize: Appearance?.font.pixelSize.larger ?? 20
            fill: Notifications.unread > 0 ? 1 : 0
            color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"; Layout.alignment: Qt.AlignVCenter
        }
        StyledText {
            visible: Notifications.unread > 0
            text: Notifications.unread > 99 ? "99+" : `${Notifications.unread}`
            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
            color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"; Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: notifMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: { Notifications.silent = !Notifications.silent; if (!Notifications.silent) Notifications.markAllRead() }
    }

    BarModulePopout {
        shown: root.hovered && Notifications.list.length > 0
        popupWidth: 320; popupHeight: Math.min(notifPopupCol.implicitHeight + 24, 350)

        ColumnLayout {
            id: notifPopupCol; anchors.fill: parent; spacing: 6

            RowLayout {
                Layout.fillWidth: true; spacing: 8
                StyledText { text: "Notifications"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
                StyledText { text: `${Notifications.list.length}`; font.pixelSize: 11; opacity: 0.4 }
                ToolbarButton { iconName: "delete_sweep"; iconSize: 14; onClicked: Notifications.discardAllNotifications() }
            }

            StyledFlickable {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 250
                contentHeight: notifList.implicitHeight; clip: true

                ColumnLayout {
                    id: notifList; width: parent.width; spacing: 4
                    Repeater {
                        model: Notifications.list.slice(-6).reverse()
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: nItemRow.implicitHeight + 8; radius: 6
                            color: Appearance?.colors.colLayer2 ?? "#2B2930"

                            RowLayout {
                                id: nItemRow; anchors { fill: parent; margins: 4 }
                                spacing: 6
                                MaterialSymbol { text: "notifications"; iconSize: 14; opacity: 0.4 }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    StyledText { text: modelData?.summary ?? ""; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                                    StyledText { text: modelData?.body ?? ""; font.pixelSize: 10; opacity: 0.5; elide: Text.ElideRight; maximumLineCount: 1; Layout.fillWidth: true }
                                }
                                ToolbarButton { iconName: "close"; iconSize: 12; implicitWidth: 20; implicitHeight: 20; onClicked: Notifications.discardNotification(modelData.notificationId) }
                            }
                        }
                    }
                }
            }
        }
    }
}

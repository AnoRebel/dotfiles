import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "."

/**
 * Notification list rendered on the lock screen. Subscribes to
 * Notifications service while GlobalStates.screenLocked is true and
 * captures every incoming notification into a local model. Visual is
 * intentionally minimal — title + body + appName, no actions, no
 * dismiss buttons (the user has to unlock to interact).
 *
 * Visible only when Config.options.lock.notifications.enable is true
 * (default false).
 */
ColumnLayout {
    id: root
    spacing: 6

    visible: (Config.options?.lock?.notifications?.enable ?? false)
             && lockNotifModel.count > 0

    // Local model — populated only while locked. Cleared on unlock so
    // the next lock session starts empty.
    ListModel { id: lockNotifModel }

    Connections {
        target: Notifications
        function onNotify(n) {
            if (!GlobalStates.screenLocked) return
            lockNotifModel.insert(0, {
                appName: n?.appName ?? "",
                summary: n?.summary ?? "",
                body: n?.body ?? "",
                ts: Date.now()
            })
            // Cap to most-recent N — keep the lock screen from drowning
            // in chatty apps during long locks.
            const cap = Config.options?.lock?.notifications?.maxItems ?? 5
            while (lockNotifModel.count > cap)
                lockNotifModel.remove(lockNotifModel.count - 1)
        }
    }

    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (!GlobalStates.screenLocked) lockNotifModel.clear()
        }
    }

    Repeater {
        model: lockNotifModel

        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: notifCol.implicitHeight + 12
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.10)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)

            ColumnLayout {
                id: notifCol
                anchors.fill: parent
                anchors.margins: 6
                spacing: 1

                StyledText {
                    text: modelData.appName || "Notification"
                    font.pixelSize: 9
                    color: "white"
                    opacity: 0.55
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                StyledText {
                    text: modelData.summary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "white"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                StyledText {
                    visible: text.length > 0
                    text: modelData.body
                    font.pixelSize: 11
                    color: "white"
                    opacity: 0.75
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }
    }
}

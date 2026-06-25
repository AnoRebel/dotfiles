import qs.modules.common
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Restart-required marker. Place next to a Settings field's label to
 * signal that changes only apply after a shell reload. Clicking the
 * pill triggers `Quickshell.reload(true)` so the user can apply pending
 * changes without hunting for the rail's "Reload Shell" button.
 *
 * Usage:
 *   RowLayout {
 *       StyledText { text: "Default compositor" }
 *       RestartRequiredBadge {}
 *   }
 *
 * Tooltip text is fixed across the codebase to keep the language
 * uniform — pages SHOULD NOT customise it.
 */
Rectangle {
    id: root
    implicitWidth: row.implicitWidth + 12
    implicitHeight: row.implicitHeight + 4

    radius: Appearance?.rounding.full ?? height / 2
    color: ma.containsMouse
        ? (Appearance?.colors.colLayer1Hover ?? "#3C3947")
        : "transparent"
    border.width: 1
    border.color: Appearance?.colors.colOutlineVariant ?? "#49454F"
    opacity: ma.containsMouse ? 1.0 : 0.7

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on opacity { NumberAnimation { duration: 120 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: "restart_alt"
            iconSize: 12
            color: Appearance?.colors.colSubtext ?? "#CAC4D0"
        }
        StyledText {
            text: "Reload"
            font.pixelSize: Appearance?.font.pixelSize.smallest ?? 10
            color: Appearance?.colors.colSubtext ?? "#CAC4D0"
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.reload(true)
    }

    StyledToolTip {
        text: "This setting takes effect after Reload Shell. Click to reload now."
        visible: ma.containsMouse
    }
}

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick

/**
 * Idle inhibitor toggle in bar. Shows a coffee cup when active.
 */
Item {
    id: root
    implicitWidth: icon.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        text: Idle.inhibit ? "coffee" : "coffee_maker"
        iconSize: Appearance?.font.pixelSize.larger ?? 20
        fill: Idle.inhibit ? 1 : 0
        color: Idle.inhibit
            ? Appearance?.colors.colPrimary ?? "#65558F"
            : Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: Idle.toggleInhibit()
        StyledToolTip { text: Idle.inhibit ? "Idle inhibited (click to disable)" : "Allow idle (click to inhibit)" }
    }
}

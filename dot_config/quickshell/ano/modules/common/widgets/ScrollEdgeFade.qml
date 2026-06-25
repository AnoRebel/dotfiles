import QtQuick
import qs.modules.common

/**
 * Fade overlay at the top/bottom edges of a scrollable area.
 */
Item {
    id: root
    property Flickable target
    property real fadeHeight: 20
    property color fadeColor: Appearance?.colors.colLayer0 ?? "#1C1B1F"

    anchors.fill: target

    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: root.fadeHeight
        opacity: root.target.contentY > 5 ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.fadeColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: root.fadeHeight
        opacity: (root.target.contentY < root.target.contentHeight - root.target.height - 5) ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: root.fadeColor }
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}

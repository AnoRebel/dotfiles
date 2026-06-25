import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * An info/warning/error notice box.
 */
Rectangle {
    id: root
    property string text: ""
    property string iconName: "info"
    property string level: "info" // "info", "warning", "error"
    property color levelColor: level === "error" ? Appearance?.m3colors.m3error ?? "#BA1A1A"
        : level === "warning" ? "#E8A800"
        : Appearance?.colors.colPrimary ?? "#65558F"

    implicitHeight: layout.implicitHeight + 16
    radius: Appearance?.rounding.small ?? 4
    color: Qt.rgba(levelColor.r, levelColor.g, levelColor.b, 0.12)
    border.color: Qt.rgba(levelColor.r, levelColor.g, levelColor.b, 0.3)
    border.width: 1
    Layout.fillWidth: true

    RowLayout {
        id: layout
        anchors { fill: parent; margins: 8 }
        spacing: 8
        MaterialSymbol { text: root.iconName; iconSize: 20; color: root.levelColor }
        StyledText { text: root.text; wrapMode: Text.Wrap; Layout.fillWidth: true; font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13 }
    }
}

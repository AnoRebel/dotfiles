import qs.modules.common
import QtQuick
import QtQuick.Layouts

/**
 * A horizontal row of GroupButton items with uniform rounding.
 */
Rectangle {
    id: root
    property alias buttons: layout.data

    implicitHeight: layout.implicitHeight
    implicitWidth: layout.implicitWidth
    color: "transparent"
    radius: Appearance?.rounding.normal ?? 12

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 2
    }
}

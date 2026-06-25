import qs.modules.common
import QtQuick
import QtQuick.Layouts

/**
 * A horizontal toolbar container with consistent styling.
 */
Rectangle {
    id: root
    property alias content: layout.data
    property real toolbarPadding: 6
    property real toolbarSpacing: 4

    implicitHeight: layout.implicitHeight + 2 * toolbarPadding
    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
    radius: Appearance?.rounding.normal ?? 12

    RowLayout {
        id: layout
        anchors {
            fill: parent
            margins: root.toolbarPadding
        }
        spacing: root.toolbarSpacing
    }
}

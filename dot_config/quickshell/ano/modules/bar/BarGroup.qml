import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import "."

/**
 * A rounded pill container for bar module groups.
 */
Item {
    id: root
    property bool vertical: false
    property real padding: 5
    // Background is configurable so callers tune it via properties instead
    // of injecting a child Rectangle (the default alias routes children into
    // the inner GridLayout, where anchored items are undefined behavior).
    property bool showBackground: true
    property color backgroundColor: Appearance?.colors.colLayer1 ?? "#E5E1EC"
    property real backgroundRadius: Appearance?.rounding.small ?? 8
    default property alias items: gridLayout.children

    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + padding * 2)
    implicitHeight: vertical ? (gridLayout.implicitHeight + padding * 2) : Appearance.sizes.baseBarHeight

    Rectangle {
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : 4
            bottomMargin: root.vertical ? 0 : 4
            leftMargin: root.vertical ? 4 : 0
            rightMargin: root.vertical ? 4 : 0
        }
        visible: root.showBackground
        color: root.backgroundColor
        radius: root.backgroundRadius
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors {
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            left: root.vertical ? undefined : parent.left
            right: root.vertical ? undefined : parent.right
            top: root.vertical ? parent.top : undefined
            bottom: root.vertical ? parent.bottom : undefined
            margins: root.padding
        }
        columnSpacing: 4
        rowSpacing: 12
    }
}

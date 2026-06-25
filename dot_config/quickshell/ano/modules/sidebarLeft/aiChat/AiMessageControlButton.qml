import qs.modules.common
import qs.modules.common.widgets
import QtQuick

/**
 * Small icon button for message actions (copy, delete, regen, etc.)
 */
RippleButton {
    id: root
    property string buttonIcon: ""
    property bool activated: false

    implicitWidth: 28; implicitHeight: 28
    buttonRadius: Appearance?.rounding.full ?? 9999
    colBackground: "transparent"
    colBackgroundHover: Appearance?.colors.colLayer1Hover ?? "#E5DFED"

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        text: root.buttonIcon
        iconSize: 14
        fill: root.activated ? 1 : 0
        color: root.activated ? Appearance?.colors.colPrimary ?? "#65558F" : Appearance?.colors.colSubtext ?? "#999"
    }
}

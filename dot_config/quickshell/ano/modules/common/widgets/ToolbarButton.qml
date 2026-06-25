import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * A simple icon-only toolbar button with tooltip.
 */
RippleButton {
    id: root
    property string iconName: ""
    property real iconSize: Appearance?.font.pixelSize.normal ?? 18
    property real iconFill: 0
    property string toolTipText: ""

    implicitWidth: 36
    implicitHeight: 36
    buttonRadius: Appearance?.rounding.full ?? 9999

    contentItem: MaterialSymbol {
        text: root.iconName
        iconSize: root.iconSize
        fill: root.iconFill
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    StyledToolTip {
        text: root.toolTipText
        visible: root.toolTipText.length > 0 && root.hovered
    }
}

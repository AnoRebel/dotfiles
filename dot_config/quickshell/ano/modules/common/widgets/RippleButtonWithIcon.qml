import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * RippleButton with a leading MaterialSymbol icon and text label.
 */
RippleButton {
    id: root
    property string iconName: ""
    property real iconSize: Appearance?.font.pixelSize.normal ?? 18
    property real iconFill: 0

    contentItem: RowLayout {
        spacing: 6
        MaterialSymbol {
            text: root.iconName
            iconSize: root.iconSize
            fill: root.iconFill
            visible: root.iconName.length > 0
            Layout.alignment: Qt.AlignVCenter
        }
        StyledText {
            text: root.buttonText
            visible: root.buttonText.length > 0
            Layout.alignment: Qt.AlignVCenter
        }
    }
}

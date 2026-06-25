import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * A toggleable button for use in ButtonGroup rows.
 */
RippleButton {
    id: root
    property string iconName: ""
    property real iconSize: Appearance?.font.pixelSize.small ?? 16
    property real iconFill: toggled ? 1 : 0
    property string label: ""
    property bool showLabel: true

    buttonRadius: Appearance?.rounding.small ?? 4
    colBackgroundToggled: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
    colBackgroundToggledHover: Appearance?.colors.colSecondaryContainerHover ?? "#DDD3EE"

    implicitHeight: 36

    contentItem: RowLayout {
        spacing: 4
        MaterialSymbol {
            text: root.iconName
            iconSize: root.iconSize
            fill: root.iconFill
            visible: root.iconName.length > 0
            Layout.alignment: Qt.AlignVCenter
        }
        StyledText {
            text: root.label
            visible: root.showLabel && root.label.length > 0
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 14
        }
    }
}

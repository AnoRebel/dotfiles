import qs.modules.common
import qs.modules.common.widgets
import QtQuick

/**
 * A styled keyboard key indicator for the cheatsheet.
 */
Rectangle {
    id: root
    property string keyText: ""
    property real keyPadding: 6

    implicitWidth: keyLabel.implicitWidth + 2 * keyPadding
    implicitHeight: keyLabel.implicitHeight + 2 * keyPadding
    radius: Appearance?.rounding.verysmall ?? 4
    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
    border.color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"
    border.width: 1

    StyledText {
        id: keyLabel
        anchors.centerIn: parent
        text: root.keyText
        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
        font.family: Appearance?.font.family.mono ?? "monospace"
    }
}

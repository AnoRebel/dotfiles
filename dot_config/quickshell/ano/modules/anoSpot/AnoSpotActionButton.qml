import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import "."

/**
 * Compact icon+label button used in the AnoSpot stash popout's action
 * toolbar (LocalSend / Open / Copy / Move / Reveal + user-defined rules).
 */
RippleButton {
    id: root
    property string icon: "play_arrow"
    property string label: ""
    property color accent: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
    signal activated()

    implicitHeight: 32
    implicitWidth: contentRow.implicitWidth + 18
    buttonRadius: 8
    colBackground: Appearance?.colors?.colLayer1 ?? "#2b2930"

    contentItem: RowLayout {
        id: contentRow
        spacing: 6
        anchors.leftMargin: 9
        anchors.rightMargin: 9

        MaterialSymbol {
            text: root.icon
            iconSize: 14
            color: root.accent
        }
        StyledText {
            text: root.label
            font.pixelSize: 11
            color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
        }
    }

    onClicked: root.activated()
}

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import "."

/**
 * Search/filter box for AnoView. Type to filter windows by title/class.
 */
Rectangle {
    id: searchBar
    width: Math.min(parent.width * 0.6, 480)
    height: 40
    radius: 20
    color: Appearance?.colors.colLayer1 ?? "#66000000"
    border.width: 1
    border.color: Appearance?.colors.colOutlineVariant ?? "#33ffffff"
    anchors.horizontalCenter: parent.horizontalCenter

    signal textChanged(string text)

    function reset() { searchInput.text = "" }

    StyledTextInput {
        id: searchInput
        anchors.fill: parent
        anchors.leftMargin: 16; anchors.rightMargin: 16
        verticalAlignment: TextInput.AlignVCenter
        color: Appearance?.m3colors.m3onBackground ?? "white"
        font.pixelSize: 16
        activeFocusOnTab: false
        focus: true

        onTextChanged: searchBar.textChanged(searchInput.text)

        StyledText {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            color: Appearance?.colors.colOnLayer1Inactive ?? "#88ffffff"
            font.pixelSize: 14
            text: "Type to filter windows..."
            visible: !searchInput.text || searchInput.text.length === 0
        }
    }
}

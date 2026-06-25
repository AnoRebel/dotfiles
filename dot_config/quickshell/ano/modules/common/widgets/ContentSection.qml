import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * A titled content section for settings/sidebar pages.
 */
ColumnLayout {
    id: root
    property string title: ""
    property real sectionSpacing: 8
    property real contentSpacing: 6

    spacing: sectionSpacing
    Layout.fillWidth: true

    StyledText {
        text: root.title
        visible: root.title.length > 0
        font.pixelSize: Appearance?.font.pixelSize.small ?? 15
        font.weight: Font.DemiBold
        color: Appearance?.colors.colPrimary ?? "#65558F"
        Layout.fillWidth: true
    }

    ColumnLayout {
        spacing: root.contentSpacing
        Layout.fillWidth: true
        Layout.leftMargin: 4
    }
}

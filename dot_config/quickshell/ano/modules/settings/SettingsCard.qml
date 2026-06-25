import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import "."

/**
 * A collapsible settings card with icon, title, subtitle, and expandable content.
 * Used as the main grouping element in settings pages.
 */
Rectangle {
    id: root
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool expanded: true
    property bool collapsible: true
    default property alias content: contentColumn.data

    // Config keys this card owns — used by the Ctrl+K command palette to
    // resolve a typed search query (e.g. "bar.layout.height") to a card
    // and scroll the page flickable to it. Each entry can be a top-level
    // root ("audio") or a dotted path ("bar.layout.height"). The palette
    // scrolls to the first card whose configKeys list covers the query.
    property var configKeys: []

    Layout.fillWidth: true
    implicitHeight: cardColumn.implicitHeight + 2
    radius: Appearance?.rounding.normal ?? 12
    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
    border.width: 1
    border.color: Appearance?.colors.colLayer0Border ?? "#44444488"

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    ColumnLayout {
        id: cardColumn
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
        spacing: 0

        // Header
        MouseArea {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + 20
            cursorShape: root.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: { if (root.collapsible) root.expanded = !root.expanded }

            RowLayout {
                id: headerRow
                anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 10; bottomMargin: 10 }
                spacing: 12

                // Icon in accent circle
                Rectangle {
                    width: 36; height: 36; radius: 10
                    color: Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.15)
                    visible: root.icon.length > 0

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.icon; iconSize: 20
                        color: Appearance?.colors.colPrimary ?? "#65558F"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    StyledText {
                        text: root.title
                        font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        text: root.subtitle
                        visible: root.subtitle.length > 0
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        opacity: 0.5
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }

                // Expand/collapse chevron
                MaterialSymbol {
                    visible: root.collapsible
                    text: root.expanded ? "expand_less" : "expand_more"
                    iconSize: 24
                    color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"

                    Behavior on text { SequentialAnimation {
                        NumberAnimation { target: parent; property: "rotation"; to: root.expanded ? -180 : 180; duration: 0 }
                        NumberAnimation { target: parent; property: "rotation"; to: 0; duration: 200; easing.type: Easing.OutCubic }
                    }}
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 16; Layout.rightMargin: 16
            implicitHeight: 1
            color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"
            opacity: root.expanded ? 0.3 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // Content
        Item {
            Layout.fillWidth: true
            implicitHeight: root.expanded ? contentColumn.implicitHeight + 16 : 0
            clip: true
            Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: contentColumn
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16; topMargin: 8 }
                spacing: 12
                opacity: root.expanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }
}

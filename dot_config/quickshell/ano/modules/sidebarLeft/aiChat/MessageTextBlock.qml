import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

/**
 * Renders a text segment of an AI message.
 * Supports basic markdown rendering via Qt rich text.
 * Code blocks are rendered in monospace with background.
 */
ColumnLayout {
    id: root
    property string segmentContent: ""
    property var messageData
    property var segment: ({ type: "text", content: segmentContent })

    spacing: 4

    Repeater {
        model: root.segmentContent.split(/```(\w*)\n/)

        Loader {
            required property string modelData
            required property int index
            Layout.fillWidth: true

            // Odd indices are language tags, even indices are content
            // Pattern: [text, lang, code, text, lang, code, ...]
            // Actually simpler: just detect if previous was a lang tag
            property bool isCode: index > 0 && index % 3 === 2
            property string langTag: index > 0 && index % 3 === 1 ? modelData : ""

            active: !langTag.length || isCode || index === 0 || index % 3 === 0
            visible: active

            sourceComponent: isCode ? codeBlockComponent : textBlockComponent
        }
    }

    Component {
        id: textBlockComponent
        StyledText {
            text: modelData
            wrapMode: Text.Wrap
            textFormat: Text.MarkdownText
            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
            color: root.messageData?.role === "interface"
                ? Appearance?.colors.colSubtext ?? "#888"
                : Appearance?.m3colors.m3onBackground ?? "#E6E1E5"
            onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
        }
    }

    Component {
        id: codeBlockComponent
        Rectangle {
            implicitHeight: codeText.implicitHeight + 16
            radius: Appearance?.rounding.small ?? 8
            color: Appearance?.colors.colLayer2 ?? "#2B2930"
            Layout.fillWidth: true

            RowLayout {
                anchors { top: parent.top; right: parent.right; margins: 4 }
                spacing: 4

                StyledText {
                    text: langTag || "code"
                    font.pixelSize: Appearance?.font.pixelSize.smallest ?? 11
                    opacity: 0.5
                }

                RippleButton {
                    implicitWidth: 24; implicitHeight: 24
                    buttonRadius: 12
                    colBackground: "transparent"
                    onClicked: Quickshell.clipboardText = modelData

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "content_copy"; iconSize: 14
                        color: Appearance?.colors.colSubtext ?? "#888"
                    }
                }
            }

            StyledText {
                id: codeText
                anchors { fill: parent; margins: 8; topMargin: 24 }
                text: modelData
                wrapMode: Text.Wrap
                font.family: Appearance?.font.family.mono ?? "monospace"
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
                color: Appearance?.m3colors.m3onBackground ?? "#E6E1E5"
            }
        }
    }
}

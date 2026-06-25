import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

/**
 * A single AI chat message bubble with role header, content, and action buttons.
 */
Rectangle {
    id: root
    property int messageIndex
    property var messageData
    property var messageInputField

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: columnLayout.implicitHeight + 14

    radius: Appearance?.rounding.normal ?? 12
    color: messageData?.role === "user"
        ? Appearance?.colors.colLayer1 ?? "#E5E1EC"
        : messageData?.role === "interface"
            ? "transparent"
            : Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"

    ColumnLayout {
        id: columnLayout
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 7 }
        spacing: 3

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                iconSize: 16
                color: Appearance?.colors.colSubtext ?? "#999"
                text: messageData?.role === "user" ? "person" :
                    messageData?.role === "interface" ? "settings" : "neurology"
            }

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                color: Appearance?.colors.colSubtext ?? "#999"
                text: messageData?.role === "user" ? "You" :
                    messageData?.role === "interface" ? "System" :
                    (Ai.models[messageData?.model]?.name ?? "Assistant")
            }

            // Action buttons
            RowLayout {
                spacing: 2

                AiMessageControlButton {
                    buttonIcon: "refresh"
                    visible: messageData?.role === "assistant"
                    onClicked: Ai.regenerate(root.messageIndex)
                    StyledToolTip { text: "Regenerate" }
                }
                AiMessageControlButton {
                    id: copyBtn
                    buttonIcon: copyBtn.activated ? "inventory" : "content_copy"
                    onClicked: {
                        Quickshell.clipboardText = root.messageData?.content
                        copyBtn.activated = true; copyTimer.restart()
                    }
                    Timer { id: copyTimer; interval: 1500; onTriggered: copyBtn.activated = false }
                    StyledToolTip { text: "Copy" }
                }
                AiMessageControlButton {
                    buttonIcon: "close"
                    onClicked: Ai.removeMessage(root.messageIndex)
                    StyledToolTip { text: "Delete" }
                }
            }
        }

        // Loading indicator
        Loader {
            Layout.fillWidth: true
            active: messageData && !messageData.done && (!messageData.content || messageData.content.length === 0)
            visible: active
            sourceComponent: RowLayout {
                spacing: 4
                MaterialSymbol { text: "hourglass_top"; iconSize: 16; color: Appearance?.colors.colPrimary ?? "#65558F" }
                StyledText { text: "Thinking..."; font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13; opacity: 0.6 }
            }
        }

        // Message content — rendered as styled text with code block detection
        MessageTextBlock {
            Layout.fillWidth: true
            visible: messageData?.content?.length > 0
            segmentContent: messageData?.content ?? ""
            messageData: root.messageData
        }
    }
}

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import qs.modules.sidebarLeft.aiChat
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

/**
 * AI Chat view — the main chat UI in the left sidebar.
 * Supports slash commands (/model, /key, /clear, /temp, /save, /load, /prompt),
 * streaming responses, message list with auto-scroll, Enter to send, Shift+Enter for newline.
 */
Item {
    id: root
    property real padding: 4
    property string commandPrefix: "/"

    onFocusChanged: focus => { if (focus) messageInputField.forceActiveFocus() }

    Keys.onPressed: event => {
        messageInputField.forceActiveFocus()
        if (event.key === Qt.Key_PageUp) {
            messageListView.contentY = Math.max(0, messageListView.contentY - messageListView.height / 2)
            event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
            messageListView.contentY = Math.min(messageListView.contentHeight - messageListView.height / 2, messageListView.contentY + messageListView.height / 2)
            event.accepted = true
        }
        if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_O) Ai.clearMessages()
    }

    property var allCommands: [
        { name: "model", description: "Choose model" },
        { name: "key", description: "Set API key" },
        { name: "clear", description: "Clear chat" },
        { name: "temp", description: "Set temperature (0–2)" },
        { name: "prompt", description: "Set system prompt" },
        { name: "save", description: "Save chat" },
        { name: "load", description: "Load chat" },
    ]

    function handleInput(inputText) {
        if (inputText.startsWith(root.commandPrefix)) {
            const parts = inputText.split(" "); const cmd = parts[0].substring(1); const args = parts.slice(1)
            switch (cmd) {
                case "model": Ai.setModel(args[0] ?? ""); break
                case "key": Ai.setApiKey(args.join(" ")); break
                case "clear": Ai.clearMessages(); break
                case "temp": Ai.setTemperature(args[0] ?? "0.5"); break
                case "prompt": Ai.loadPrompt(args.join(" ")); break
                case "save": Ai.saveChat(args.join(" ")); break
                case "load": Ai.loadChat(args.join(" ")); break
                default: Ai.addMessage("Unknown command: " + cmd, Ai.interfaceRole)
            }
        } else {
            Ai.sendUserMessage(inputText)
        }
        messageListView.positionViewAtEnd()
    }

    ColumnLayout {
        anchors { fill: parent; margins: root.padding }
        spacing: root.padding

        // Status bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: statusRow.implicitHeight + 8
            radius: Appearance?.rounding.small ?? 8
            color: Appearance?.colors.colLayer2 ?? "#2B2930"

            RowLayout {
                id: statusRow
                anchors.centerIn: parent
                spacing: 10

                MaterialSymbol {
                    iconSize: 16; color: Appearance?.colors.colSubtext ?? "#999"
                    text: Ai.currentModelHasApiKey ? "key" : "key_off"
                }
                StyledText {
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                    color: Appearance?.colors.colSubtext ?? "#999"
                    text: Ai.getModel()?.name ?? "No model"
                }
                Rectangle { implicitWidth: 4; implicitHeight: 4; radius: 2; color: Appearance?.colors.colOutlineVariant ?? "#666" }
                StyledText {
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                    color: Appearance?.colors.colSubtext ?? "#999"
                    text: `T: ${Ai.temperature.toFixed(1)}`
                }
                Loader {
                    active: Ai.tokenCount.total > 0
                    visible: active
                    sourceComponent: RowLayout {
                        spacing: 4
                        Rectangle { implicitWidth: 4; implicitHeight: 4; radius: 2; color: Appearance?.colors.colOutlineVariant ?? "#666" }
                        MaterialSymbol { iconSize: 14; text: "token"; color: Appearance?.colors.colSubtext ?? "#999" }
                        StyledText {
                            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                            color: Appearance?.colors.colSubtext ?? "#999"
                            text: Ai.tokenCount.total
                        }
                    }
                }
            }
        }

        // Message list
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledFlickable {
                id: messageListView
                anchors.fill: parent
                contentHeight: messageColumn.implicitHeight
                clip: true

                onContentHeightChanged: { if (atYEnd) Qt.callLater(positionViewAtEnd) }

                function positionViewAtEnd() {
                    contentY = Math.max(0, contentHeight - height)
                }

                ColumnLayout {
                    id: messageColumn
                    width: parent.width
                    spacing: 6

                    // Placeholder
                    Item {
                        visible: Ai.messageIDs.length === 0
                        Layout.fillWidth: true
                        Layout.topMargin: 60
                        implicitHeight: placeholderCol.implicitHeight

                        ColumnLayout {
                            id: placeholderCol
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            MaterialSymbol { text: "neurology"; iconSize: 48; color: Appearance?.colors.colPrimary ?? "#65558F"; Layout.alignment: Qt.AlignHCenter }
                            StyledText { text: "AI Chat"; font.pixelSize: Appearance?.font.pixelSize.huger ?? 22; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
                            StyledText { text: "Type /key to set your API key\n/model to select a model"; font.pixelSize: Appearance?.font.pixelSize.small ?? 14; opacity: 0.5; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                        }
                    }

                    Repeater {
                        model: Ai.messageIDs.filter(id => Ai.messageByID[id]?.visibleToUser ?? true)

                        AiMessage {
                            required property var modelData
                            required property int index
                            messageIndex: index
                            messageData: Ai.messageByID[modelData]
                            messageInputField: root
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            ScrollEdgeFade { target: messageListView }
        }

        // Command suggestions
        Loader {
            Layout.fillWidth: true
            active: messageInputField.text.startsWith(root.commandPrefix) && messageInputField.text.length > 0 && messageInputField.text.length < 20
            visible: active
            sourceComponent: Flow {
                spacing: 4
                Repeater {
                    model: root.allCommands.filter(cmd => cmd.name.startsWith(messageInputField.text.substring(1)))
                    RippleButton {
                        required property var modelData
                        buttonText: `/${modelData.name}`
                        buttonRadius: Appearance?.rounding.verysmall ?? 4
                        implicitHeight: 26
                        colBackground: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
                        onClicked: { messageInputField.text = `/${modelData.name} `; messageInputField.cursorPosition = messageInputField.text.length; messageInputField.forceActiveFocus() }
                        StyledToolTip { text: modelData.description }
                    }
                }
            }
        }

        // Input area
        Rectangle {
            Layout.fillWidth: true
            radius: Appearance?.rounding.normal ?? 12
            color: Appearance?.colors.colLayer2 ?? "#2B2930"
            implicitHeight: Math.max(inputRow.implicitHeight + 10, 45)

            RowLayout {
                id: inputRow
                anchors { fill: parent; margins: 5 }
                spacing: 0

                StyledTextArea {
                    id: messageInputField
                    Layout.fillWidth: true
                    wrapMode: TextArea.Wrap
                    padding: 10
                    placeholderText: `Message the model... "${root.commandPrefix}" for commands`
                    background: null

                    Keys.onPressed: event => {
                        if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                messageInputField.insert(messageInputField.cursorPosition, "\n")
                                event.accepted = true
                            } else {
                                const text = messageInputField.text
                                messageInputField.clear()
                                root.handleInput(text)
                                event.accepted = true
                            }
                        }
                    }
                }

                RippleButton {
                    Layout.alignment: Qt.AlignTop
                    Layout.rightMargin: 5
                    implicitWidth: 40; implicitHeight: 40
                    buttonRadius: Appearance?.rounding.small ?? 8
                    enabled: messageInputField.text.length > 0
                    toggled: enabled

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: 22
                        color: parent.parent.enabled ? Appearance?.m3colors.m3onPrimary ?? "white" : Appearance?.colors.colOnLayer2Disabled ?? "#666"
                        text: "arrow_upward"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            const text = messageInputField.text
                            messageInputField.clear()
                            root.handleInput(text)
                        }
                    }
                }
            }
        }
    }
}

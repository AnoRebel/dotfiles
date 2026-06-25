import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.sidebarLeft.translator
import "."

/**
 * Translator widget. Uses `trans` CLI tool (translate-shell) for translation
 * with auto-detect source language. Falls back to AI translation if trans
 * is not installed. Supports language switching, auto-translate on pause,
 * and clipboard integration.
 *
 * Ported from inir/end-4.
 */
Item {
    id: root
    property real padding: 4
    property string translatedText: ""
    property string targetLanguage: Config.options?.language?.translator?.targetLanguage ?? "en"
    property string sourceLanguage: Config.options?.language?.translator?.sourceLanguage ?? "auto"
    property bool showLanguageSelector: false
    property bool useAiFallback: false

    onFocusChanged: focus => { if (focus) Qt.callLater(() => inputArea.forceActiveFocus()) }

    // Auto-translate timer (translate after user stops typing)
    Timer {
        id: translateTimer
        interval: Config.options?.sidebar?.translator?.delay ?? 600
        onTriggered: {
            if (inputArea.text.trim().length > 0) {
                if (root.useAiFallback) aiTranslate()
                else transProcess.running = true
            } else root.translatedText = ""
        }
    }

    // trans CLI process
    Process {
        id: transProcess
        running: false
        command: ["trans", "-brief", `${root.sourceLanguage}:${root.targetLanguage}`, "--", inputArea.text.trim()]
        stdout: StdioCollector {
            id: transCollector
            onStreamFinished: root.translatedText = transCollector.text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && !root.useAiFallback) {
                root.useAiFallback = true
                aiTranslate()
            }
        }
    }

    // AI fallback translation
    function aiTranslate() {
        const text = inputArea.text.trim()
        if (text.length === 0) return
        const prompt = `Translate the following text to ${root.targetLanguage}. Only output the translation, nothing else:\n\n${text}`
        aiTranslateProcess.command = ["bash", "-c", `echo '${prompt.replace(/'/g, "'\\''")}' | curl -s 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key='$(cat ~/.config/quickshell/ano/api_keys.json 2>/dev/null | jq -r '.google_gemini // empty') -H 'Content-Type: application/json' -d '{"contents":[{"parts":[{"text":"'"${prompt.replace(/'/g, "'\\''").replace(/"/g, '\\"')}"'"}]}]}' | jq -r '.candidates[0].content.parts[0].text // "Translation unavailable"'`]
        aiTranslateProcess.running = true
    }

    Process {
        id: aiTranslateProcess
        stdout: StdioCollector {
            id: aiCollector
            onStreamFinished: root.translatedText = aiCollector.text.trim()
        }
    }

    // Check if trans is available
    Process {
        id: transCheckProcess
        running: true
        command: ["bash", "-c", "command -v trans"]
        onExited: (exitCode) => { root.useAiFallback = (exitCode !== 0) }
    }

    ColumnLayout {
        anchors { fill: parent; margins: root.padding }
        spacing: 8

        // Language selector row
        RowLayout {
            Layout.fillWidth: true; spacing: 8

            LanguageSelectorButton {
                label: root.sourceLanguage === "auto" ? "Auto" : root.sourceLanguage.toUpperCase()
                onClicked: {
                    // Cycle common languages
                    const langs = ["auto", "en", "es", "fr", "de", "ja", "ko", "zh", "ar", "ru", "pt", "sw"]
                    const idx = langs.indexOf(root.sourceLanguage)
                    root.sourceLanguage = langs[(idx + 1) % langs.length]
                    Config.setNestedValue("language.translator.sourceLanguage", root.sourceLanguage)
                    translateTimer.restart()
                }
            }

            MaterialSymbol { text: "arrow_forward"; iconSize: 20; opacity: 0.4 }

            LanguageSelectorButton {
                label: root.targetLanguage.toUpperCase()
                onClicked: {
                    const langs = ["en", "es", "fr", "de", "ja", "ko", "zh", "ar", "ru", "pt", "sw"]
                    const idx = langs.indexOf(root.targetLanguage)
                    root.targetLanguage = langs[(idx + 1) % langs.length]
                    Config.setNestedValue("language.translator.targetLanguage", root.targetLanguage)
                    translateTimer.restart()
                }
            }

            Item { Layout.fillWidth: true }

            // Swap button
            ToolbarButton {
                iconName: "swap_horiz"; iconSize: 18
                toolTipText: "Swap languages"
                enabled: root.sourceLanguage !== "auto"
                onClicked: {
                    const tmp = root.sourceLanguage
                    root.sourceLanguage = root.targetLanguage
                    root.targetLanguage = tmp
                    Config.setNestedValue("language.translator.sourceLanguage", root.sourceLanguage)
                    Config.setNestedValue("language.translator.targetLanguage", root.targetLanguage)
                    // Also swap text content
                    if (root.translatedText.length > 0) {
                        inputArea.text = root.translatedText
                        translateTimer.restart()
                    }
                }
            }

            // Method indicator
            StyledText {
                text: root.useAiFallback ? "AI" : "trans"
                font.pixelSize: 9; opacity: 0.3
                font.family: Appearance?.font.family.mono ?? "monospace"
            }
        }

        // Input area
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 80
            radius: Appearance?.rounding.small ?? 8
            color: Appearance?.colors.colLayer2 ?? "#2B2930"

            StyledTextArea {
                id: inputArea
                anchors { fill: parent; margins: 8 }
                placeholderText: "Type text to translate..."
                wrapMode: TextArea.Wrap
                background: null
                onTextChanged: translateTimer.restart()
            }
        }

        // Divider with arrow
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.2 }
            MaterialSymbol { text: "arrow_downward"; iconSize: 16; opacity: 0.3 }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.2 }
        }

        // Output area
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 80
            radius: Appearance?.rounding.small ?? 8
            color: Appearance?.colors.colLayer2 ?? "#2B2930"

            StyledFlickable {
                anchors { fill: parent; margins: 8 }
                contentHeight: outputText.implicitHeight
                clip: true

                StyledText {
                    id: outputText
                    width: parent.width
                    text: root.translatedText || (transProcess.running || aiTranslateProcess.running ? "Translating..." : "")
                    font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                    wrapMode: Text.Wrap
                    opacity: root.translatedText.length > 0 ? 1 : 0.4
                }
            }

            // Copy button
            ToolbarButton {
                anchors { top: parent.top; right: parent.right; margins: 4 }
                iconName: "content_copy"; iconSize: 14
                visible: root.translatedText.length > 0
                onClicked: Quickshell.clipboardText = root.translatedText
                toolTipText: "Copy translation"
            }
        }
    }
}

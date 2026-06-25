import QtQuick

/**
 * Represents a message in an AI conversation.
 * Follows OpenAI API message structure.
 */
QtObject {
    property string role        // "user", "assistant", "interface", "system"
    property string content
    property string rawContent
    property string model
    property string localFilePath
    property string fileMimeType
    property bool thinking: true
    property bool done: false
    property bool visibleToUser: true
    property var annotationSources: []
    property list<string> searchQueries: []
}

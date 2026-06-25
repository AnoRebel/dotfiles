import QtQuick

/**
 * An AI model definition.
 * - name: Friendly display name
 * - model: API model code (e.g. "gpt-4.1", "gemini-2.5-flash")
 * - endpoint: API endpoint URL
 * - api_format: "openai" or "gemini"
 * - requires_key: Whether an API key is needed
 * - key_id: Identifier for the API key (shared across models using same key)
 * - key_get_link: URL to obtain an API key
 * - description: Model description
 * - icon: Material symbol name or SVG path
 */
QtObject {
    property string name
    property string icon: "neurology"
    property string description
    property string endpoint
    property string model
    property bool requires_key: true
    property string key_id
    property string key_get_link
    property string api_format: "openai"
    property var extraParams: ({})
}

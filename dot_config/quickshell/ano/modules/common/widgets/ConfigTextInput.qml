import qs.modules.common
import QtQuick
import QtQuick.Layouts

/**
 * Settings-grade text input. Wraps StyledTextInput with affordances the
 * Settings pages need:
 *
 *   - placeholderText: shown faded when text is empty and not focused.
 *     Implemented as a non-interactive Text overlay (z: -1) — clicks pass
 *     through to the underlying TextInput.
 *
 *   - validator: either a regex (matches → ok) or a function
 *     (text) → null|"" for ok, or a string error message. Re-evaluated
 *     on each text change. When invalid, the input shows an error tint
 *     and the errorText row renders below.
 *
 *   - iconAction: optional trailing Material Symbol name. When set, a
 *     clickable icon button is rendered at the right; clicking emits
 *     iconClicked. Use for "browse" affordances (open file picker, etc.).
 *
 * Width: caller sets Layout.preferredWidth or implicitWidth on the root.
 */
ColumnLayout {
    id: root

    property alias text: input.text
    property alias readOnly: input.readOnly
    property string placeholderText: ""
    property var validator: null
    property string iconAction: ""

    // Computed validator state. Re-evaluates on text change.
    readonly property string _errorText: {
        const v = root.validator;
        if (!v) return "";
        if (input.text.length === 0) return ""; // empty is fine; required-ness is a separate concern
        if (typeof v === "function") {
            const result = v(input.text);
            return (typeof result === "string") ? result : "";
        }
        // Regex validator
        if (v.test && typeof v.test === "function") {
            return v.test(input.text) ? "" : "Invalid input";
        }
        return "";
    }
    readonly property bool valid: _errorText.length === 0

    signal iconClicked()
    signal editingFinished()

    spacing: 2

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inputRow.implicitHeight + 8
        radius: Appearance?.rounding.small ?? 8
        color: Appearance?.colors.colLayer2 ?? "#2B2930"
        border.width: 1
        border.color: !root.valid
            ? (Appearance?.m3colors.m3error ?? "#F2B8B5")
            : input.activeFocus
                ? (Appearance?.colors.colPrimary ?? "#65558F")
                : (Appearance?.colors.colOutlineVariant ?? "#49454F")

        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: inputRow
            anchors { fill: parent; leftMargin: 10; rightMargin: 6 }
            spacing: 4

            Item {
                Layout.fillWidth: true
                implicitHeight: input.implicitHeight

                StyledTextInput {
                    id: input
                    anchors.fill: parent
                    activeFocusOnTab: true
                    onEditingFinished: root.editingFinished()
                }

                // Placeholder overlay — visible only when input is empty
                // and unfocused. z: -1 so it can never intercept clicks
                // (defense in depth; the TextInput already covers it).
                Text {
                    z: -1
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: root.placeholderText
                    visible: input.text.length === 0 && !input.activeFocus && root.placeholderText.length > 0
                    color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                    opacity: 0.55
                    font: input.font
                    elide: Text.ElideRight
                }
            }

            // Trailing icon-action button (e.g. browse). Hidden when
            // iconAction is empty.
            Loader {
                Layout.alignment: Qt.AlignVCenter
                active: root.iconAction.length > 0
                visible: active
                sourceComponent: Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: Appearance?.rounding.small ?? 6
                    color: iconMA.containsMouse
                        ? (Appearance?.colors.colLayer1Hover ?? "#3C3947")
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.iconAction
                        iconSize: 18
                        color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                    }

                    MouseArea {
                        id: iconMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.iconClicked()
                    }
                }
            }
        }
    }

    // Inline error row — only renders when validator returns an error.
    Loader {
        Layout.fillWidth: true
        active: !root.valid
        visible: active
        sourceComponent: RowLayout {
            spacing: 4
            MaterialSymbol {
                text: "error"
                iconSize: 13
                color: Appearance?.m3colors.m3error ?? "#F2B8B5"
            }
            StyledText {
                text: root._errorText
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                color: Appearance?.m3colors.m3error ?? "#F2B8B5"
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
    }
}

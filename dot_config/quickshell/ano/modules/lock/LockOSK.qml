import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "."

/**
 * Minimal on-screen keyboard for the lock screen. Sends synthesized
 * key events to the focused TextInput via signals (no ydotool/uinput
 * dependency — the consumer handles the input).
 *
 * Visible only when Config.options.lock.osk.enable is true (default
 * false). 4-row QWERTY layout; Shift toggles uppercase + symbols on
 * the top row; Backspace + Submit + Space included.
 *
 * Designed for touch and mouse (no native key events; the consumer
 * binds to the `key(text)` and `submit()` signals).
 */
ColumnLayout {
    id: osk
    spacing: 4

    visible: Config.options?.lock?.osk?.enable ?? false

    signal key(string text)
    signal submit()
    signal backspace()

    property bool shifted: false

    readonly property var rows: shifted
        ? [
            ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"],
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
            ["Z", "X", "C", "V", "B", "N", "M"]
          ]
        : [
            ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
            ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
            ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
            ["z", "x", "c", "v", "b", "n", "m"]
          ]

    Repeater {
        model: osk.rows
        RowLayout {
            required property var modelData
            required property int index
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            // Indent rows 2 and 3 slightly for the QWERTY stagger
            Item {
                Layout.preferredWidth: index === 2 ? 16 : (index === 3 ? 30 : 0)
                Layout.preferredHeight: 1
                visible: index >= 2
            }

            Repeater {
                model: parent.modelData
                Rectangle {
                    required property string modelData
                    implicitWidth: 30; implicitHeight: 36
                    radius: 6
                    color: keyMa.containsPress ? Qt.rgba(1,1,1,0.25)
                         : keyMa.containsMouse ? Qt.rgba(1,1,1,0.18)
                         : Qt.rgba(1,1,1,0.10)
                    Behavior on color { ColorAnimation { duration: 80 } }
                    StyledText {
                        anchors.centerIn: parent
                        text: parent.modelData
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: "white"
                    }
                    MouseArea {
                        id: keyMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: osk.key(parent.modelData)
                    }
                }
            }

            // Shift on row 3 (left of Z), Backspace on row 3 (right of M)
            Loader {
                active: index === 3
                visible: active
                sourceComponent: RowLayout {
                    spacing: 4
                    Rectangle {
                        Layout.preferredWidth: 50; Layout.preferredHeight: 36
                        radius: 6
                        color: osk.shifted ? Qt.rgba(1,1,1,0.30) : Qt.rgba(1,1,1,0.10)
                        StyledText {
                            anchors.centerIn: parent
                            text: "Shift"
                            font.pixelSize: 11
                            color: "white"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: osk.shifted = !osk.shifted
                        }
                    }
                    Rectangle {
                        Layout.preferredWidth: 50; Layout.preferredHeight: 36
                        radius: 6
                        color: bsMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.10)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "backspace"
                            iconSize: 16
                            color: "white"
                        }
                        MouseArea {
                            id: bsMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: osk.backspace()
                        }
                    }
                }
            }
        }
    }

    // Bottom row: Space + Submit
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4

        Rectangle {
            Layout.preferredWidth: 200; Layout.preferredHeight: 34
            radius: 6
            color: spaceMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.10)
            Behavior on color { ColorAnimation { duration: 80 } }
            MouseArea {
                id: spaceMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: osk.key(" ")
            }
        }
        Rectangle {
            Layout.preferredWidth: 60; Layout.preferredHeight: 34
            radius: 6
            color: submitMa.containsMouse
                ? (Appearance?.colors.colPrimaryHover ?? "#80aaaa")
                : (Appearance?.colors.colPrimary ?? "#65558F")
            Behavior on color { ColorAnimation { duration: 80 } }
            MaterialSymbol {
                anchors.centerIn: parent
                text: "arrow_forward"
                iconSize: 18
                color: "white"
            }
            MouseArea {
                id: submitMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: osk.submit()
            }
        }
    }
}

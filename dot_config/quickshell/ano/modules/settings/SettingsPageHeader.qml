import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * Settings page header — title row with a "Reset this page" button on
 * the right. The button is hidden when no key under any of `configRoots`
 * is present in the user delta, so a freshly-defaulted page shows nothing.
 *
 * Pass the page's `title`, `subtitle` (optional), and `configRoots` —
 * the top-level config keys the page owns (e.g. `["bar"]` for BarConfig,
 * or `["lock", "anoSpot"]` for a multi-section page). When the user
 * clicks Reset, a confirmation prompt appears inline; only after
 * confirming does the wipe happen.
 */
ColumnLayout {
    id: root

    property string title: ""
    property string subtitle: ""
    property var configRoots: []

    // Re-evaluates whenever Config.hasUserOverrides changes (which fires
    // whenever the user delta is mutated). Cheap — hash-key lookup per root.
    readonly property bool hasOverrides:
        Config.hasUserOverrides && Config.hasOverridesForRoots(root.configRoots)

    property bool _confirming: false

    Layout.fillWidth: true
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            StyledText {
                text: root.title
                font.pixelSize: Appearance?.font.pixelSize.huge ?? 20
                font.weight: Font.DemiBold
            }
            StyledText {
                text: root.subtitle
                visible: root.subtitle.length > 0
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
                opacity: 0.6
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        // Reset action — collapsed when nothing to reset, two-step
        // confirmation when there is.
        Loader {
            Layout.alignment: Qt.AlignVCenter
            active: root.hasOverrides
            visible: active
            sourceComponent: root._confirming ? confirmRow : resetButton
        }
    }

    Component {
        id: resetButton
        RippleButton {
            implicitHeight: 32
            buttonRadius: Appearance?.rounding.small ?? 8
            contentItem: RowLayout {
                anchors { leftMargin: 10; rightMargin: 10 }
                spacing: 6
                MaterialSymbol {
                    text: "restart_alt"; iconSize: 16
                    color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                }
                StyledText {
                    text: "Reset"
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
                    color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                }
            }
            onClicked: root._confirming = true
        }
    }

    Component {
        id: confirmRow
        RowLayout {
            spacing: 6

            StyledText {
                text: "Reset this page?"
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
                color: Appearance?.colors.colError ?? "#F2B8B5"
            }

            RippleButton {
                implicitHeight: 28
                buttonRadius: Appearance?.rounding.small ?? 8
                contentItem: StyledText {
                    text: "Cancel"
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                }
                onClicked: root._confirming = false
            }

            RippleButton {
                implicitHeight: 28
                buttonRadius: Appearance?.rounding.small ?? 8
                colBackground: Appearance?.m3colors.m3errorContainer ?? "#5C1A1A"
                contentItem: StyledText {
                    text: "Reset"
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                    font.weight: Font.DemiBold
                    color: Appearance?.m3colors.m3onErrorContainer ?? "#F9DEDC"
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                }
                onClicked: {
                    Config.resetPaths(root.configRoots);
                    root._confirming = false;
                }
            }
        }
    }

    // Subtle separator below the header
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 4
        color: Appearance?.colors.colOutlineVariant ?? "#49454F"
        opacity: 0.3
    }
}

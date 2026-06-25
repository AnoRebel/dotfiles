import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Keyboard layout indicator. Shows a `language` Material Symbol prefix
 * plus the current XKB layout code (e.g. "us", "fr"). Visible only when
 * more than one layout is configured. Clicking the indicator on Niri
 * cycles to the next layout via `niri msg action switch-layout next`;
 * Hyprland-side cycling is left to the user's keybinds.
 *
 * Bar module IDs: "keyboard" (legacy, retained for existing user
 * configs) and "keyboardLayout" (alias added per spec
 * ano-deferred-features-batch-2026 ▸ bar-status-indicators). Both
 * resolve to this module.
 */
Item {
    id: root
    visible: KeyboardLayoutService.layoutCodes.length > 1
    implicitWidth: visible ? row.implicitWidth + 14 : 0
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        MaterialSymbol {
            text: "language"
            iconSize: 16
            color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
        }
        StyledText {
            text: KeyboardLayoutService.currentLayoutCode.toUpperCase()
            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
            color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: CompositorService.isNiri ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            // Niri-only: cycle to the next layout. Hyprland's keyboard-
            // layout cycling needs a different IPC and is left to keybinds.
            if (CompositorService.isNiri) {
                Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"])
            }
        }
        StyledToolTip { text: KeyboardLayoutService.currentLayoutName }
    }
}

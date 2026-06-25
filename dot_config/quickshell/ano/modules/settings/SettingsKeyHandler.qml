import QtQuick
import qs
import "."

/**
 * Shared keyboard navigation for both Settings shells (overlay + standalone).
 *
 * Contract:
 *   - Up / Down — move currentPage by ±1, clamped to [0, pageCount).
 *   - Tab / Shift+Tab — move currentPage by ±1 when no input has focus.
 *     When an input is focused, default Tab traversal applies (the
 *     handler doesn't see the event because Keys.priority delays us
 *     until the focused item declines it).
 *   - Ctrl+1..9 — jump to page (N-1).
 *   - Ctrl+0 — jump to last page.
 *   - Esc — invoke closeAction (parent shell wires this to the right
 *     close behaviour: GlobalStates.settingsOpen=false for the overlay,
 *     Quickshell.quit() for the standalone).
 *
 * Usage:
 *   SettingsKeyHandler {
 *       anchors.fill: parent
 *       focus: true
 *       currentPage: root.currentPage
 *       pageCount: root.pages.length
 *       onPageRequested: (idx) => root.currentPage = idx
 *       onCloseRequested: GlobalStates.settingsOpen = false
 *   }
 *
 * Keys.priority: AfterItem so a focused TextInput / Slider handles digits
 * first. The handler only fires when the focused item declined the event.
 */
Item {
    id: root

    // Inputs from the parent shell
    property int currentPage: 0
    property int pageCount: 1

    // Outputs back to the parent shell
    signal pageRequested(int index)
    signal closeRequested()

    Keys.priority: Keys.AfterItem

    Keys.onPressed: event => {
        // Ctrl+K — open the command palette. Toggles open if already shown.
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_K) {
            GlobalStates.settingsCommandPaletteOpen = !GlobalStates.settingsCommandPaletteOpen;
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Up) {
            const next = Math.max(0, root.currentPage - 1);
            if (next !== root.currentPage) root.pageRequested(next);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Down) {
            const next = Math.min(root.pageCount - 1, root.currentPage + 1);
            if (next !== root.currentPage) root.pageRequested(next);
            event.accepted = true;
            return;
        }

        // Tab / Shift+Tab fall through naturally for inputs (because of
        // AfterItem priority); we only see them when no input is focused.
        if (event.key === Qt.Key_Tab) {
            const next = Math.min(root.pageCount - 1, root.currentPage + 1);
            if (next !== root.currentPage) root.pageRequested(next);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Backtab) {
            const next = Math.max(0, root.currentPage - 1);
            if (next !== root.currentPage) root.pageRequested(next);
            event.accepted = true;
            return;
        }

        // Ctrl+1..9 → page index N-1
        if ((event.modifiers & Qt.ControlModifier)
            && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            const idx = event.key - Qt.Key_1;
            if (idx < root.pageCount) {
                root.pageRequested(idx);
                event.accepted = true;
            }
            return;
        }

        // Ctrl+0 → last page
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_0) {
            root.pageRequested(root.pageCount - 1);
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
            return;
        }
    }
}

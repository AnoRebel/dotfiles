import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.focusTime
import "."
/**
 * FocusTime Panel — app usage tracker overlay.
 * Adapted from ilyamiro's FocusTimePopup for Ano Shell.
 * Uses Appearance singleton for theming, compositor-agnostic.
 */
PanelWindow {
    id: panel

    anchors { top: true; bottom: true; left: true; right: true }

    property int panelWidth: Math.min(820, panel.screen?.width * 0.55 ?? 820)
    property int panelHeight: Math.min(680, panel.screen?.height * 0.75 ?? 680)

    screen: GlobalStates.primaryScreen
    visible: GlobalStates.focusTimeOpen
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true

    // Namespace for layer rules
    property string ns: "quickshell:focusTime"
    WlrLayershell.namespace: ns
    WlrLayershell.layer: WlrLayer.Overlay

    color: "transparent"

    // ═══════════════════════════════════════════════════════════════════════
    // IPC
    // ═══════════════════════════════════════════════════════════════════════
    IpcHandler {
        target: "focusTime"
        function toggle(): void { GlobalStates.focusTimeOpen = !GlobalStates.focusTimeOpen }
        function open(): void { GlobalStates.focusTimeOpen = true }
        function close(): void { GlobalStates.focusTimeOpen = false }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Close on click outside
    // ═══════════════════════════════════════════════════════════════════════
    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.focusTimeOpen = false
        z: -1
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Content
    // ═══════════════════════════════════════════════════════════════════════
    FocusTimeContent {
        id: content
        anchors.fill: parent
        visible: GlobalStates.focusTimeOpen
    }
}

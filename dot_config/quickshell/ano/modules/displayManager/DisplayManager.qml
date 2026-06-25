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
import qs.modules.displayManager
import "."
/**
 * Display Manager — visual monitor configuration overlay.
 * Adapted from ilyamiro's MonitorPopup for Ano Shell.
 * Hyprland-only (uses hyprctl for monitor queries and apply).
 */
PanelWindow {
    id: panel

    // Full-screen anchored window; the actual content is a centered card
    // inside (Quickshell 0.3 dropped anchors.rect.{x,y,w,h} positioning).
    anchors { top: true; bottom: true; left: true; right: true }

    property int panelWidth: Math.min(860, panel.screen?.width * 0.55 ?? 860)
    property int panelHeight: Math.min(420, panel.screen?.height * 0.45 ?? 420)

    screen: GlobalStates.primaryScreen
    visible: GlobalStates.displayManagerOpen && CompositorService.isHyprland
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true

    property string ns: "quickshell:displayManager"
    WlrLayershell.namespace: ns
    WlrLayershell.layer: WlrLayer.Overlay

    color: "transparent"

    // ═══════════════════════════════════════════════════════════════════════
    // IPC
    // ═══════════════════════════════════════════════════════════════════════
    IpcHandler {
        target: "displayManager"
        function toggle(): void { GlobalStates.displayManagerOpen = !GlobalStates.displayManagerOpen }
        function open(): void { GlobalStates.displayManagerOpen = true }
        function close(): void { GlobalStates.displayManagerOpen = false }
    }

    // Close on click outside
    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.displayManagerOpen = false
        z: -1
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Content
    // ═══════════════════════════════════════════════════════════════════════
    DisplayManagerContent {
        id: content
        anchors.fill: parent
        visible: GlobalStates.displayManagerOpen
    }
}

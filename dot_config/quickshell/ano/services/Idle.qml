pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * Idle inhibitor service. Toggles a Wayland IdleInhibitor surface
 * to prevent the system from going idle (e.g., during presentations).
 */
Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: false

    function toggleInhibit(active = null) {
        if (active !== null) root.inhibit = active
        else root.inhibit = !root.inhibit
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            anchors {
                right: true
                bottom: true
            }
            mask: Region { item: null }
        }
    }

    IpcHandler {
        target: "idle"
        function toggle(): void { root.toggleInhibit() }
        function enable(): void { root.toggleInhibit(true) }
        function disable(): void { root.toggleInhibit(false) }
    }
}

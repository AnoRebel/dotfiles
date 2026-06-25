import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.bar
import "."
/**
 * BarManager — Creates and manages N bars per monitor.
 * Reads bar definitions from config.json "bars" array.
 * Each bar can be on any edge (top/bottom/left/right) and has its own module set.
 * Falls back to a single default bar if no "bars" array is configured.
 */
Scope {
    id: root

    // Default bar definition when no explicit bars are configured
    readonly property var defaultBars: [{
        "id": "main",
        "edge": "top",
        "modules": {
            "left": ["sidebarButton", "activeWindow"],
            "center": ["workspaces"],
            "right": ["clock", "battery", "network", "bluetooth", "tray", "sidebarButton"]
        },
        "autoHide": false,
        "showBackground": true
    }]

    readonly property var barDefinitions: Config.options?.bars ?? defaultBars

    // Per-screen bar instances.
    //
    // Variants (not Repeater) is required at every level here: Repeater only
    // instantiates delegates into a visual parent, but a Quickshell Scope is
    // non-visual, so a Repeater nested in one creates nothing. Variants is the
    // model→instance primitive for non-item objects and acts as a reload scope.
    Variants {
        id: screenVariants
        model: {
            const screens = Quickshell.screens
            const screenList = Config.options?.bar?.screenList ?? []
            if (!screenList || screenList.length === 0) return screens
            return screens.filter(screen => screenList.includes(screen.name))
        }

        delegate: Scope {
            id: screenScope
            required property var modelData

            // One BarWindow per bar definition on this screen.
            Variants {
                model: root.barDefinitions

                delegate: BarWindow {
                    required property var modelData
                    // Skip bars that use morphingPanel — those are rendered by TopLayerPanel.
                    readonly property bool _shouldShow: GlobalStates.barOpen
                        && !GlobalStates.screenLocked
                        && !(modelData?.morphingPanel ?? false)

                    screen: screenScope.modelData
                    barConfig: modelData
                    barIndex: 0
                    visible: _shouldShow
                }
            }
        }
    }

    // IPC
    IpcHandler {
        target: "bar"
        function toggle(): void { GlobalStates.barOpen = !GlobalStates.barOpen }
        function close(): void { GlobalStates.barOpen = false }
        function open(): void { GlobalStates.barOpen = true }
    }

    // GlobalShortcuts (Hyprland only)
    Loader {
        active: CompositorService.compositor === "hyprland"
        sourceComponent: Item {
            GlobalShortcut { name: "barToggle"; description: "Toggle bar"; onPressed: GlobalStates.barOpen = !GlobalStates.barOpen }
            GlobalShortcut { name: "barOpen"; description: "Open bar"; onPressed: GlobalStates.barOpen = true }
            GlobalShortcut { name: "barClose"; description: "Close bar"; onPressed: GlobalStates.barOpen = false }
        }
    }
}

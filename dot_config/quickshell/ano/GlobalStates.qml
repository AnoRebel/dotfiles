pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// GlobalStates: Central state singleton for all panel/overlay open/close states.
// Compositor-aware: uses Loader for Hyprland-only GlobalShortcuts.
Singleton {
    id: root

    // ═══════════════════════════════════════════════════════════════════════
    // Panel & Overlay States
    // ═══════════════════════════════════════════════════════════════════════
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool osdMediaOpen: false
    property string osdMediaAction: "play" // "play", "pause", "next", "previous"
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool taskViewOpen: false
    property bool altSwitcherOpen: false
    property bool clipboardOpen: false
    property bool controlPanelOpen: false
    property bool cheatsheetOpen: false
    property bool settingsOverlayOpen: false
    property bool settingsOpen: false
    property bool settingsCommandPaletteOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool weatherPanelOpen: false
    property bool focusTimeOpen: false
    property bool displayManagerOpen: false
    property bool anoSpotStashOpen: false
    property bool anoSpotWorkspacePreviewOpen: false
    property bool calendarOpen: false

    // Lock screen
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false

    // Session
    property bool sessionOpen: false

    // Keyboard state
    property bool superDown: false
    property bool superReleaseMightTrigger: true

    // Wallpaper selector
    property bool wallpaperSelectorOpen: false
    property bool coverflowSelectorOpen: false
    property string wallpaperSelectionTarget: "main" // "main", "backdrop"
    property string wallpaperSelectorTargetMonitor: ""
    onWallpaperSelectorOpenChanged: {
        if (!wallpaperSelectorOpen) {
            wallpaperSelectionTarget = "main";
            wallpaperSelectorTargetMonitor = "";
        }
    }
    onCoverflowSelectorOpenChanged: {
        if (!coverflowSelectorOpen) {
            wallpaperSelectionTarget = "main";
            wallpaperSelectorTargetMonitor = "";
        }
    }

    // Workspace numbers overlay
    property bool workspaceShowNumbers: false

    // HUD
    property bool hudVisible: false

    // Panel family transition
    property bool familyTransitionActive: false
    property string familyTransitionDirection: "left"

    // Cross-panel dialog requests
    property bool requestWifiDialog: false
    property bool requestBluetoothDialog: false

    // ═══════════════════════════════════════════════════════════════════════
    // Signals
    // ═══════════════════════════════════════════════════════════════════════
    signal requestRipple(real x, real y, string screenName)

    // ═══════════════════════════════════════════════════════════════════════
    // Primary Screen (user-configured or fallback to first screen)
    // ═══════════════════════════════════════════════════════════════════════
    readonly property var primaryScreen: {
        const name = Config.options?.display?.primaryMonitor ?? ""
        if (name.length > 0) {
            const s = Quickshell.screens.find(scr => scr.name === name)
            if (s) return s
        }
        return Quickshell.screens[0]
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Sidebar notification integration
    // ═══════════════════════════════════════════════════════════════════════
    onSidebarRightOpenChanged: {
        if (root.sidebarRightOpen) {
            // Mark notifications as read when opening notification sidebar
            // (Notifications service will be available in Phase 2)
            try {
                Notifications.timeoutAll();
                Notifications.markAllRead();
            } catch (e) {}
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Screen Zoom (Hyprland-only)
    // ═══════════════════════════════════════════════════════════════════════
    property real screenZoom: 1
    onScreenZoomChanged: {
        if (!CompositorService.isHyprland) return;
        Quickshell.execDetached(["hyprctl", "keyword", "cursor:zoom_factor", root.screenZoom.toString()]);
    }
    Behavior on screenZoom {
        animation: NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Compositor-guarded shortcuts (only load on Hyprland)
    // ═══════════════════════════════════════════════════════════════════════
    Loader {
        active: CompositorService.isHyprland
        sourceComponent: GlobalShortcut {
            name: "workspaceNumber"
            description: "Hold to show workspace numbers, release to show icons"
            onPressed: root.superDown = true
            onReleased: root.superDown = false
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // IPC Handlers (compositor-agnostic)
    // ═══════════════════════════════════════════════════════════════════════
    IpcHandler {
        target: "zoom"
        function zoomIn(): void { screenZoom = Math.min(screenZoom + 0.4, 3.0) }
        function zoomOut(): void { screenZoom = Math.max(screenZoom - 0.4, 1) }
    }

    // Test alive handler — used by Hyprland keybinds to check if shell is running
    IpcHandler {
        target: "TEST_ALIVE"
        // Just existing is enough — if this IPC call succeeds, the shell is alive
    }
}

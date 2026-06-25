//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"

import QtQuick
import Quickshell
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════════════════
// Ano Shell — Entry Point
// 175 QML components. Compositor-agnostic: Hyprland + Niri.
//
// Panel families are defined in panelFamilies/*.qml
// The active family is loaded dynamically based on Config.options.panelFamily
// ═══════════════════════════════════════════════════════════════════════════
ShellRoot {
    id: root

    function _log(msg: string): void {
        if (Quickshell.env("QS_DEBUG") === "1") console.log("[Ano] " + msg);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Singleton Force-Init
    // ═══════════════════════════════════════════════════════════════════════
    Component.onCompleted: {
        root._log(`Initializing Ano shell on ${CompositorService.compositor}`);
        root._log(`Shell root: ${Directories.shellRoot}`);
        // Touch autonomous singletons so they instantiate even when no UI
        // currently reads them. Each runs purely on side-effects:
        //   PowerProfilePersistence — restores profile on Config.ready
        //   AntiFlashbang           — IPC-controlled shader on Hyprland
        //   MinimizedWindows        — Niri minimize-emulation registry
        void PowerProfilePersistence;
        void AntiFlashbang;
        void MinimizedWindows;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Config Ready Hook
    // ═══════════════════════════════════════════════════════════════════════
    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready) return;
            root._log("Config ready, initializing services");
            MaterialThemeLoader.reapplyTheme();
            Wallpapers.load();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Panel Families — loaded from panelFamilies/*.qml
    // ═══════════════════════════════════════════════════════════════════════
    property list<string> families: ["ano", "minimal", "hefty", "clean"]

    // Map family ID → QML source file
    readonly property var familySources: ({
        "ano": "panelFamilies/AnoFamily.qml",
        "minimal": "panelFamilies/MinimalFamily.qml",
        "hefty": "panelFamilies/HeftyFamily.qml",
        "clean": "panelFamilies/CleanFamily.qml",
    })

    // The active family loader — loads one family QML file at a time
    Loader {
        id: familyLoader
        active: Config.ready
        source: {
            const family = Config.options?.panelFamily ?? "ano"
            const src = root.familySources[family]
            if (src) return src
            root._log(`Unknown family "${family}", falling back to ano`)
            return root.familySources["ano"]
        }
        onLoaded: root._log(`Loaded panel family: ${Config.options?.panelFamily ?? "ano"}`)
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Family Transition
    // ═══════════════════════════════════════════════════════════════════════
    property string _pendingFamily: ""
    property bool _transitionInProgress: false

    function cyclePanelFamily() {
        const currentFamily = Config.options?.panelFamily ?? "ano";
        const currentIndex = families.indexOf(currentFamily);
        const nextIndex = (currentIndex + 1) % families.length;
        const nextFamily = families[nextIndex];
        root.startFamilyTransition(nextFamily);
    }

    function setPanelFamily(family: string) {
        const currentFamily = Config.options?.panelFamily ?? "ano";
        if (families.includes(family) && family !== currentFamily) {
            root.startFamilyTransition(family);
        }
    }

    function startFamilyTransition(targetFamily: string) {
        if (_transitionInProgress) return;
        if (!(Config.options?.familyTransitionAnimation ?? true)) {
            // Instant switch — no animation
            root._applyFamily(targetFamily);
            return;
        }
        _transitionInProgress = true;
        _pendingFamily = targetFamily;
        GlobalStates.familyTransitionActive = true;
    }

    function applyPendingFamily() {
        if (_pendingFamily && families.includes(_pendingFamily)) {
            root._applyFamily(_pendingFamily);
        }
        _pendingFamily = "";
    }

    function _applyFamily(family: string) {
        Config.options.panelFamily = family;
        // Apply family-specific overrides
        switch (family) {
            case "hefty":
                Config.setNestedValue("bar.morphingPanels", true);
                break;
            case "minimal":
                Config.setNestedValue("dock.enable", false);
                Config.setNestedValue("screenCorners.enable", false);
                Config.setNestedValue("bar.morphingPanels", false);
                break;
            case "clean":
                Config.setNestedValue("dock.enable", false);
                Config.setNestedValue("bar.morphingPanels", false);
                break;
            default:
                Config.setNestedValue("bar.morphingPanels", false);
                break;
        }
        root._log(`Applied family: ${family}`);
    }

    function finishFamilyTransition() {
        _transitionInProgress = false;
        GlobalStates.familyTransitionActive = false;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // IPC Handlers
    // ═══════════════════════════════════════════════════════════════════════
    IpcHandler {
        target: "panelFamily"
        function cycle(): void { root.cyclePanelFamily() }
        function set(family: string): void { root.setPanelFamily(family) }
    }

    IpcHandler {
        target: "shell"
        function reload(): void { Quickshell.reload(true) }
        function quit(): void { Quickshell.quit() }
        function _applyPending(): void { root.applyPendingFamily() }
        function _finishTransition(): void { root.finishFamilyTransition() }
    }

    // Launch standalone settings window
    IpcHandler {
        target: "settingsStandalone"
        function open(): void {
            Quickshell.execDetached(["/usr/bin/qs", "-n", "-p", Quickshell.shellPath("settings.qml")])
        }
    }
}

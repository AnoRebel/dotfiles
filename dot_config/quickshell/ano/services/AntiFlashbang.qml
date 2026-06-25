pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Anti-Flashbang Shader Service (Hyprland-only).
 * Applies a GLSL shader that darkens bright screens to prevent eye strain at night.
 * Ported from end-4/ii.
 */
Singleton {
    id: root

    readonly property string shaderPath: Quickshell.shellPath("services/antiFlashbang/anti-flashbang.glsl")
    property bool enabled: false

    function enable(): void {
        Quickshell.execDetached(["hyprctl", "--batch",
            "keyword decoration:screen_shader " + root.shaderPath +
            " ; keyword debug:damage_tracking 1"
        ]);
        root.enabled = true;
    }

    function disable(): void {
        Quickshell.execDetached(["hyprctl", "--batch",
            "keyword decoration:screen_shader [[EMPTY]] ; keyword debug:damage_tracking 2"
        ]);
        root.enabled = false;
    }

    function toggle(): void {
        if (root.enabled) disable();
        else enable();
    }

    IpcHandler {
        target: "antiFlashbang"
        function toggle(): void { root.toggle() }
        function enable(): void { root.enable() }
        function disable(): void { root.disable() }
    }
}

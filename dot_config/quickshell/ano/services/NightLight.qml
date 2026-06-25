pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * Night light — warm-shift the display via wlsunset. Cross-compositor:
 * works on any wlroots-based session (Hyprland, Niri, sway, etc.).
 *
 * Two modes:
 *   "manual"    — single fixed temperature while active.
 *   "schedule"  — automatic transition between day and night temperatures
 *                 at sunrise/sunset for the configured latitude/longitude
 *                 (wlsunset's native -l/-L behaviour).
 *
 * Service is dormant when Config.options.nightLight.enable is false (no
 * process spawned, no config writes). On enable, spawns one wlsunset
 * process with the requested args; toggling state restarts it.
 *
 * The active flag is purely process-state — we don't try to detect what
 * the compositor's current gamma actually is, since there's no
 * cross-compositor API for that.
 */
Singleton {
    id: root

    readonly property bool enabled: Config.options?.nightLight?.enable ?? false
    readonly property string mode: Config.options?.nightLight?.mode ?? "manual"
    readonly property int dayTemp: Config.options?.nightLight?.dayTemp ?? 6500
    readonly property int nightTemp: Config.options?.nightLight?.nightTemp ?? 4000
    readonly property real latitude: Config.options?.nightLight?.latitude ?? 0
    readonly property real longitude: Config.options?.nightLight?.longitude ?? 0

    property bool active: proc.running

    function toggle(): void {
        Config.setNestedValue("nightLight.enable", !enabled)
    }

    function _buildArgs() {
        const args = ["wlsunset"]
        if (mode === "schedule") {
            args.push("-T", String(dayTemp))
            args.push("-t", String(nightTemp))
            args.push("-l", String(latitude))
            args.push("-L", String(longitude))
        } else {
            // Manual: hold at nightTemp permanently (-d 0 disables fade).
            // wlsunset still wants both -t and -T; we set them equal so
            // it never transitions back during the day.
            args.push("-T", String(nightTemp + 1))
            args.push("-t", String(nightTemp))
            args.push("-l", "0")
            args.push("-L", "0")
            args.push("-d", "0")
        }
        return args
    }

    Process {
        id: proc
        command: root._buildArgs()
        running: root.enabled && Config.ready
        // Restart when temperature/mode/coords change while running
        onCommandChanged: {
            if (root.enabled && Config.ready) {
                running = false
                Qt.callLater(() => running = true)
            }
        }
    }
}

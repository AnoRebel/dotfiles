pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * Compositor-agnostic gamemode detector.
 *
 * Polls `gamemoded -s` periodically (2s default) and exposes:
 *   active       — true while at least one client has gamemode activated
 *   clientCount  — best-effort count of registered clients (parsed from
 *                  `gamemoded -r` output when active; 0 otherwise)
 *
 * NOT a controller — gamemoded is normally activated by individual games
 * via libgamemode, or by the user's existing `~/.config/hypr/scripts/gamemode`
 * helper. This service only watches state so the bar indicator can render.
 *
 * Service is dormant when `Config.options.gameMode.enable` is false (default
 * false) or when `gamemoded` isn't on PATH.
 */
Singleton {
    id: root

    readonly property bool serviceEnabled: Config.options?.gameMode?.enable ?? false
    readonly property int pollIntervalMs: Config.options?.gameMode?.pollIntervalMs ?? 2000

    property bool active: false
    property int clientCount: 0

    Timer {
        running: root.serviceEnabled && Config.ready
        interval: root.pollIntervalMs
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }

    Process {
        id: statusProc
        command: ["gamemoded", "-s"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = (this.text || "").toLowerCase();
                root.active = out.indexOf("active") >= 0 && out.indexOf("inactive") < 0;
                if (root.active && !clientsProc.running)
                    clientsProc.running = true;
                else if (!root.active)
                    root.clientCount = 0;
            }
        }
        onExited: (code, _) => {
            // gamemoded may not be installed — silently mark inactive.
            if (code !== 0) root.active = false;
        }
    }

    Process {
        id: clientsProc
        command: ["gamemoded", "-r"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Output format: "<N> clients are registered" or similar
                const m = (this.text || "").match(/(\d+)\s+client/i);
                root.clientCount = m ? parseInt(m[1], 10) : (root.active ? 1 : 0);
            }
        }
    }
}

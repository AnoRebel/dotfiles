pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * FocusTime Service — manages the focus tracking daemon lifecycle.
 * Launches focus_daemon.py on startup, kills on shutdown.
 * Provides IPC target for toggling the FocusTime panel.
 */
Singleton {
    id: root

    readonly property string scriptsDir: Quickshell.shellPath("scripts/focustime")
    readonly property string daemonScript: root.scriptsDir + "/focus_daemon.py"
    readonly property string statsScript: root.scriptsDir + "/get_stats.py"
    readonly property string xdgRuntime: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string stateFile: root.xdgRuntime + "/focustime_state.json"

    property bool daemonRunning: false

    Component.onCompleted: {
        root.startDaemon();
    }

    Component.onDestruction: {
        root.stopDaemon();
    }

    function startDaemon(): void {
        if (root.daemonRunning) return;
        // Kill any existing daemon first
        Quickshell.execDetached(["bash", "-c",
            `pkill -f 'python3.*focus_daemon.py' 2>/dev/null; sleep 0.2; python3 '${root.daemonScript}' &`
        ]);
        root.daemonRunning = true;
    }

    function stopDaemon(): void {
        Quickshell.execDetached(["pkill", "-f", "python3.*focus_daemon.py"]);
        root.daemonRunning = false;
    }

    function restartDaemon(): void {
        root.stopDaemon();
        Qt.callLater(root.startDaemon);
    }
}

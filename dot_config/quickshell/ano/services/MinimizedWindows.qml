pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

/**
 * Service to manage "minimized" windows in Niri.
 * Niri has no native minimize. We emulate it by moving the window to a
 * far-away workspace and recording its identity so we can restore later.
 * Ported from inir/services/MinimizedWindows.qml.
 */
Singleton {
    id: root

    readonly property int minimizedWorkspaceIndex: 99

    property var minimizedWindows: ({})
    property list<int> minimizedIds: []

    function isMinimized(windowId) {
        return minimizedIds.includes(windowId);
    }

    function getMinimizedForApp(appId) {
        const pattern = appId.toLowerCase();
        return minimizedIds.filter(id => {
            const info = minimizedWindows[id];
            return info && info.appId.toLowerCase().includes(pattern);
        });
    }

    function countMinimizedForApp(appId) {
        return getMinimizedForApp(appId).length;
    }

    function minimize(windowId = null) {
        if (!CompositorService.isNiri) return;

        let targetWindow;
        if (windowId) {
            targetWindow = NiriService.windows?.find(w => w.id === windowId);
        } else {
            targetWindow = NiriService.activeWindow;
            windowId = targetWindow?.id;
        }

        if (!targetWindow || !windowId) return;
        if (isMinimized(windowId)) return;

        const info = {
            appId: targetWindow.app_id || "",
            title: targetWindow.title || "",
            originalWorkspace: NiriService.focusedWorkspaceIndex
        };

        minimizedWindows[windowId] = info;
        minimizedIds = [...minimizedIds, windowId];

        const allWorkspaces = NiriService.allWorkspaces ?? [];
        const maxWsIndex = allWorkspaces.length > 0
            ? Math.max(...allWorkspaces.map(ws => ws.idx), 1)
            : 1;
        const targetWs = maxWsIndex + 10;

        moveToWorkspaceProc.command = [
            "niri", "msg", "action", "move-window-to-workspace",
            "--window-id", windowId.toString(),
            "--focus", "false",
            targetWs.toString()
        ];
        moveToWorkspaceProc.running = true;
    }

    function restore(windowId) {
        if (!CompositorService.isNiri) return;
        if (!isMinimized(windowId)) return;

        const info = minimizedWindows[windowId];
        if (!info) return;

        delete minimizedWindows[windowId];
        minimizedIds = minimizedIds.filter(id => id !== windowId);

        const targetWorkspace = NiriService.focusedWorkspaceIndex;

        restoreProc.command = [
            "niri", "msg", "action", "move-window-to-workspace",
            "--window-id", windowId.toString(),
            targetWorkspace.toString()
        ];
        restoreProc.running = true;
    }

    function restoreApp(appId) {
        const windowIds = getMinimizedForApp(appId);
        for (const id of windowIds) {
            restore(id);
        }
    }

    function restoreLatestForApp(appId) {
        const windowIds = getMinimizedForApp(appId);
        if (windowIds.length > 0) {
            restore(windowIds[windowIds.length - 1]);
        }
    }

    Process {
        id: moveToWorkspaceProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("[MinimizedWindows] Failed to move window");
            }
        }
    }

    Process {
        id: restoreProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                Qt.callLater(() => {
                    const windowId = parseInt(restoreProc.command[5]);
                    NiriService.focusWindow(windowId);
                });
            }
        }
    }

    IpcHandler {
        target: "minimize"

        function minimize(): void {
            root.minimize();
        }

        function restore(windowId: int): void {
            root.restore(windowId);
        }
    }
}

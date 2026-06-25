pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

/**
 * Extended Hyprland data service. Provides window lists, workspace data,
 * monitor info, and layer info via hyprctl JSON. Only active on Hyprland.
 */
Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var activeWindow: null
    property var monitors: []
    property var layers: ({})

    // Convenience
    function toplevelsForWorkspace(workspace) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`
            return root.windowByAddress[address]?.workspace?.id === workspace
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace.id === workspace)
    }

    function clientForToplevel(toplevel) {
        if (!toplevel?.HyprlandToplevel) return null
        return root.windowByAddress[`0x${toplevel.HyprlandToplevel.address}`]
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windows = root.windowList.filter(w => w.workspace.id === workspaceId)
        return windows.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0)
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0)
            return winArea > maxArea ? win : maxWin
        }, null)
    }

    // Update functions
    function updateWindows() { getClients.running = true; getActiveWindow.running = true }
    function updateLayers() { getLayers.running = true }
    function updateMonitors() { getMonitors.running = true }
    function updateWorkspaces() { getWorkspaces.running = true; getActiveWorkspace.running = true }
    function updateAll() { updateWindows(); updateMonitors(); updateLayers(); updateWorkspaces() }

    Component.onCompleted: {
        if (CompositorService.compositor === "hyprland") updateAll()
    }

    Connections {
        enabled: CompositorService.compositor === "hyprland"
        target: Hyprland
        function onRawEvent(event) {
            if (["openlayer", "closelayer", "screencast"].includes(event.name)) return
            updateAll()
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                root.windowList = JSON.parse(clientsCollector.text)
                let temp = {}
                for (const win of root.windowList) temp[win.address] = win
                root.windowByAddress = temp
                root.addresses = root.windowList.map(win => win.address)
            }
        }
    }

    Process {
        id: getActiveWindow
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            id: activeWindowCollector
            onStreamFinished: root.activeWindow = JSON.parse(activeWindowCollector.text)
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: root.monitors = JSON.parse(monitorsCollector.text)
        }
    }

    Process {
        id: getLayers
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: root.layers = JSON.parse(layersCollector.text)
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                root.workspaces = JSON.parse(workspacesCollector.text)
                let temp = {}
                for (const ws of root.workspaces) temp[ws.id] = ws
                root.workspaceById = temp
                root.workspaceIds = root.workspaces.map(ws => ws.id)
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text)
        }
    }
}

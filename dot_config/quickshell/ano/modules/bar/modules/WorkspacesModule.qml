import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Workspaces bar module — shows workspace indicators with click-to-switch.
 * Works on both Hyprland and Niri.
 */
Item {
    id: root
    property bool vertical: false

    readonly property int workspacesShown: Config.options?.bar?.workspaces?.shown ?? 10
    readonly property int currentWorkspaceNumber: {
        if (CompositorService.compositor === "niri")
            return NiriService.getCurrentWorkspaceNumber()
        // Hyprland
        const monitor = Hyprland.monitorFor(root.QsWindow.window?.screen)
        return monitor?.activeWorkspace?.id ?? 1
    }

    property list<bool> workspaceOccupied: []
    property int buttonSize: 26
    property real activeMargin: 2

    implicitWidth: vertical ? buttonSize : (buttonSize * workspacesShown)
    implicitHeight: vertical ? (buttonSize * workspacesShown) : Appearance.sizes.barHeight

    // Scroll to switch workspaces
    MouseArea {
        z: 10
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onWheel: (event) => {
            const delta = event.angleDelta.y
            if (delta === 0) return
            const direction = delta > 0 ? -1 : 1
            if (CompositorService.compositor === "niri") {
                if (direction > 0) NiriService.focusWorkspaceDown()
                else NiriService.focusWorkspaceUp()
            } else {
                Quickshell.execDetached(["hyprctl", "dispatch", direction > 0 ? "workspace r+1" : "workspace r-1"])
            }
        }
        onPressed: (event) => {
            if (event.button === Qt.RightButton) GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
    }

    function updateOccupied() {
        if (CompositorService.compositor === "niri") {
            const wsList = NiriService.currentOutputWorkspaces || []
            const windows = NiriService.windows || []
            const occupiedIds = new Set(windows.map(w => w.workspace_id))
            workspaceOccupied = Array.from({ length: workspacesShown }, (_, i) => {
                const ws = wsList.find(w => w.idx === i + 1)
                return ws ? occupiedIds.has(ws.id) : false
            })
        } else {
            workspaceOccupied = Array.from({ length: workspacesShown }, (_, i) =>
                Hyprland.workspaces.values.some(ws => ws.id === i + 1)
            )
        }
    }

    Component.onCompleted: updateOccupied()
    Connections {
        target: CompositorService.compositor === "hyprland" ? Hyprland.workspaces : null
        function onValuesChanged() { updateOccupied() }
    }
    Connections {
        target: CompositorService.compositor === "niri" ? NiriService : null
        function onAllWorkspacesChanged() { updateOccupied() }
        function onWindowsChanged() { updateOccupied() }
    }
    onCurrentWorkspaceNumberChanged: updateOccupied()

    // Occupied background
    Grid {
        z: 1; anchors.centerIn: parent
        columns: vertical ? 1 : workspacesShown; rowSpacing: 0; columnSpacing: 0
        Repeater {
            model: workspacesShown
            Rectangle {
                implicitWidth: buttonSize; implicitHeight: buttonSize; radius: width / 2
                color: Appearance?.m3colors.m3secondaryContainer ?? "#E8DEF8"
                opacity: (workspaceOccupied[index] && currentWorkspaceNumber !== index + 1) ? 0.6 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }
    }

    // Active indicator
    Rectangle {
        z: 2
        radius: Appearance?.rounding.full ?? 9999
        color: Appearance?.colors.colPrimary ?? "#65558F"
        property int idx: currentWorkspaceNumber - 1
        x: vertical ? activeMargin : idx * buttonSize + activeMargin
        y: vertical ? idx * buttonSize + activeMargin : activeMargin
        implicitWidth: vertical ? (buttonSize - activeMargin * 2) : (buttonSize - activeMargin * 2)
        implicitHeight: vertical ? (buttonSize - activeMargin * 2) : (buttonSize - activeMargin * 2)
        anchors.verticalCenter: vertical ? undefined : parent.verticalCenter
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }

    // Buttons
    Grid {
        z: 3; anchors.fill: parent
        columns: vertical ? 1 : workspacesShown; rowSpacing: 0; columnSpacing: 0
        Repeater {
            model: workspacesShown
            Button {
                implicitWidth: buttonSize; implicitHeight: vertical ? buttonSize : Appearance.sizes.barHeight
                onClicked: {
                    if (CompositorService.compositor === "niri") NiriService.switchToWorkspace(index + 1)
                    else Quickshell.execDetached(["hyprctl", "dispatch", `workspace ${index + 1}`])
                }
                background: Item {
                    Rectangle {
                        anchors.centerIn: parent
                        width: buttonSize * 0.18; height: width; radius: width / 2
                        color: (currentWorkspaceNumber === index + 1)
                            ? Appearance?.m3colors.m3onPrimary ?? "white"
                            : (workspaceOccupied[index] ? Appearance?.m3colors.m3onSecondaryContainer ?? "#1D1B20" : Appearance?.colors.colOnLayer1Inactive ?? "#A0A0A0")
                    }
                }
            }
        }
    }
}

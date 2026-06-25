import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.layouts
/**
 * Task View — separate from AnoView overview.
 * Shows only windows on the CURRENT workspace, using the configured
 * task view layout. Triggered by different keybind/IPC than overview.
 * Includes workspace strip at bottom for switching.
 */
Scope {
    id: root

    readonly property string layoutAlgorithm: Config.options?.taskView?.layout ?? "hero"

    IpcHandler {
        target: "taskView"
        function toggle(): void { GlobalStates.taskViewOpen = !GlobalStates.taskViewOpen }
        function open(): void { GlobalStates.taskViewOpen = true }
        function close(): void { GlobalStates.taskViewOpen = false }
    }

    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: tvLoader
            required property var modelData
            active: GlobalStates.taskViewOpen

            component: PanelWindow {
                id: tvRoot
                screen: tvLoader.modelData
                visible: GlobalStates.taskViewOpen
                color: "transparent"
                anchors { top: true; bottom: true; left: true; right: true }
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.exclusiveZone: -1
                WlrLayershell.keyboardFocus: GlobalStates.taskViewOpen ? 1 : 0
                WlrLayershell.namespace: "quickshell:taskview"

                property var lastPositions: ({})
                property bool animateWindows: false

                function getActiveAddress() {
                    if (CompositorService.compositor === "hyprland")
                        return Hyprland.activeToplevel?.lastIpcObject?.address ?? ""
                    const focusedWin = NiriService.windows?.find(w => w.is_focused)
                    return focusedWin?.id?.toString() ?? ""
                }

                function getCurrentWorkspaceId() {
                    if (CompositorService.compositor === "hyprland") {
                        const monitor = Hyprland.monitorFor(tvRoot.screen)
                        return monitor?.activeWorkspace?.id ?? 1
                    }
                    return NiriService.getCurrentWorkspaceNumber()
                }

                function buildWindowList() {
                    const wsId = getCurrentWorkspaceId()
                    var windowList = []

                    if (CompositorService.compositor === "hyprland") {
                        for (const it of (Hyprland.toplevels?.values ?? [])) {
                            const ci = it?.lastIpcObject ?? {}
                            if (ci?.workspace?.id !== wsId) continue
                            const size = ci?.size ?? [0, 0]
                            windowList.push({
                                win: it, clientInfo: ci, workspaceId: wsId,
                                width: size[0], height: size[1],
                                lastIpcObject: ci, address: ci.address
                            })
                        }
                    } else if (CompositorService.compositor === "niri") {
                        for (const nw of (NiriService.windows ?? [])) {
                            if (nw.workspace_id !== wsId) continue
                            windowList.push({
                                win: nw, clientInfo: nw, workspaceId: wsId,
                                width: nw.width ?? 800, height: nw.height ?? 600,
                                lastIpcObject: nw, address: nw.id?.toString() ?? ""
                            })
                        }
                    }
                    return windowList
                }

                function activateWindow(toplevel, clientInfo) {
                    GlobalStates.taskViewOpen = false
                    if (CompositorService.compositor === "hyprland") {
                        const addr = toplevel?.address ?? clientInfo?.address ?? ""
                        if (addr) Hyprland.dispatch("focuswindow address:0x" + addr)
                    } else if (CompositorService.compositor === "niri") {
                        const winId = toplevel?.id ?? clientInfo?.id
                        if (winId !== undefined) NiriService.focusWindow(winId)
                    }
                }

                // Dim backdrop
                Rectangle {
                    anchors.fill: parent; color: "#88000000"
                    opacity: GlobalStates.taskViewOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                MouseArea { anchors.fill: parent; z: -1; onClicked: GlobalStates.taskViewOpen = false }
                Keys.onPressed: event => { if (event.key === Qt.Key_Escape) GlobalStates.taskViewOpen = false }

                Item {
                    anchors { fill: parent; margins: 48 }

                    // Window layout area
                    Item {
                        id: windowArea
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: parent.height - workspaceStrip.height - 16

                        ScriptModel {
                            id: taskLayoutModel
                            property int areaW: windowArea.width
                            property int areaH: windowArea.height
                            property var _dep1: CompositorService.compositor === "hyprland" ? Hyprland.toplevels?.values : null
                            property var _dep2: CompositorService.compositor === "niri" ? NiriService.windows : null
                            values: {
                                if (areaW <= 0 || areaH <= 0) return []
                                return LayoutsManager.doLayout(root.layoutAlgorithm, tvRoot.buildWindowList(), areaW, areaH, tvRoot.getActiveAddress())
                            }
                        }

                        Repeater {
                            model: taskLayoutModel
                            delegate: Item {
                                x: modelData.x; y: modelData.y
                                width: modelData.width; height: modelData.height

                                Rectangle {
                                    anchors.fill: parent; anchors.margins: -4
                                    radius: 16; color: "#44000000"; z: -1
                                }

                                Loader {
                                    anchors.fill: parent
                                    active: !!modelData.win?.wayland
                                    sourceComponent: ScreencopyView {
                                        anchors.fill: parent
                                        captureSource: modelData.win?.wayland ?? null
                                        live: false; paintCursor: false
                                        layer.enabled: true
                                        layer.effect: OpacityMask { maskSource: Rectangle { width: parent.width; height: parent.height; radius: 12 } }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent; radius: 12; color: "transparent"
                                    border.width: tvItemMA.containsMouse ? 3 : 1
                                    border.color: tvItemMA.containsMouse ? Appearance?.colors.colPrimary ?? "#65558F" : "#44444444"
                                }

                                // Title badge
                                Rectangle {
                                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 8 }
                                    width: Math.min(titleText.implicitWidth + 16, parent.width * 0.8)
                                    height: titleText.implicitHeight + 8; radius: 10
                                    color: "#CC000000"
                                    StyledText { id: titleText; anchors.centerIn: parent; text: modelData.win?.title ?? ""; color: "white"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width - 12 }
                                }

                                MouseArea {
                                    id: tvItemMA; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    onClicked: event => {
                                        if (event.button === Qt.MiddleButton) {
                                            if (CompositorService.compositor === "hyprland") Hyprland.dispatch("closewindow address:0x" + (modelData.clientInfo?.address ?? ""))
                                            else if (CompositorService.compositor === "niri") NiriService.closeWindow(modelData.clientInfo?.id)
                                        } else tvRoot.activateWindow(modelData.win, modelData.clientInfo)
                                    }
                                }
                            }
                        }
                    }

                    // Workspace strip at bottom
                    Rectangle {
                        id: workspaceStrip
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        width: wsRow.implicitWidth + 24; height: 40; radius: 20
                        color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
                        border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"

                        RowLayout {
                            id: wsRow; anchors.centerIn: parent; spacing: 6
                            Repeater {
                                model: Config.options?.bar?.workspaces?.shown ?? 10
                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: tvRoot.getCurrentWorkspaceId() === index + 1
                                        ? Appearance?.colors.colPrimary ?? "#65558F"
                                        : wsMA.containsMouse ? Appearance?.colors.colLayer1 ?? "#E5E1EC" : "transparent"
                                    border.width: 1
                                    border.color: tvRoot.getCurrentWorkspaceId() === index + 1 ? "transparent" : "#33ffffff"
                                    StyledText { anchors.centerIn: parent; text: `${index + 1}`; font.pixelSize: 11; color: tvRoot.getCurrentWorkspaceId() === index + 1 ? "white" : "#aaa" }
                                    MouseArea {
                                        id: wsMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (CompositorService.compositor === "niri") NiriService.switchToWorkspace(index + 1)
                                            else Quickshell.execDetached(["hyprctl", "dispatch", `workspace ${index + 1}`])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

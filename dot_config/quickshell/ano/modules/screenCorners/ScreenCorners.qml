import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services

/**
 * Hot screen corners. Invisible hit zones at the 4 corners of each screen.
 * Hovering a corner triggers a configurable action (open sidebar, overview, etc.)
 * with a configurable dwell time to prevent accidental activation.
 */
Scope {
    id: root

    readonly property bool enabled: Config.options?.screenCorners?.enable ?? false
    readonly property int dwellMs: Config.options?.screenCorners?.dwellMs ?? 300
    readonly property int hitSize: Config.options?.screenCorners?.hitSize ?? 2

    // Corner actions: each corner maps to a GlobalStates property to toggle
    readonly property var actions: Config.options?.screenCorners?.actions ?? ({
        "topLeft": "sidebarLeftOpen",
        "topRight": "sidebarRightOpen",
        "bottomLeft": "overviewOpen",
        "bottomRight": "settingsOpen"
    })

    function triggerAction(corner) {
        const action = actions[corner] ?? ""
        if (action.length > 0 && GlobalStates.hasOwnProperty(action)) {
            GlobalStates[action] = !GlobalStates[action]
        }
    }

    Variants {
        model: root.enabled ? Quickshell.screens : []

        Scope {
            required property var modelData

            // One PanelWindow per corner per screen
            Repeater {
                model: [
                    { corner: "topLeft", top: true, left: true },
                    { corner: "topRight", top: true, left: false },
                    { corner: "bottomLeft", top: false, left: true },
                    { corner: "bottomRight", top: false, left: false },
                ]

                PanelWindow {
                    id: cornerWindow
                    required property var modelData
                    screen: parent.modelData

                    visible: root.enabled && (root.actions[modelData.corner] ?? "").length > 0
                    color: "transparent"
                    implicitWidth: root.hitSize
                    implicitHeight: root.hitSize
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.namespace: `quickshell:corner:${modelData.corner}`
                    WlrLayershell.layer: WlrLayer.Overlay

                    anchors {
                        top: modelData.top
                        bottom: !modelData.top
                        left: modelData.left
                        right: !modelData.left
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: dwellTimer.restart()
                        onExited: dwellTimer.stop()

                        Timer {
                            id: dwellTimer
                            interval: root.dwellMs
                            onTriggered: root.triggerAction(cornerWindow.modelData.corner)
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "screenCorners"
        function enable(): void { Config.setNestedValue("screenCorners.enable", true) }
        function disable(): void { Config.setNestedValue("screenCorners.enable", false) }
        function toggle(): void { Config.setNestedValue("screenCorners.enable", !root.enabled) }
    }
}

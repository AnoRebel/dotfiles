import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.sidebarRight
import "."
/**
 * Right sidebar — slides in from the right edge.
 * Contains quick toggles, sliders, notifications, calendar, system info.
 */
Scope {
    id: root
    property int sidebarWidth: Appearance?.sizes.sidebarWidth ?? 420
    readonly property bool instantOpen: Config.options?.sidebar?.instantOpen ?? false
    readonly property real globalMargin: Config.options?.appearance?.bezel ?? 0

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: sidebarRoot
            required property var modelData
            screen: modelData

            Component.onCompleted: visible = GlobalStates.sidebarRightOpen

            Connections {
                target: GlobalStates
                function onSidebarRightOpenChanged() {
                    if (GlobalStates.sidebarRightOpen) { _closeTimer.stop(); sidebarRoot.visible = true }
                    else if (root.instantOpen) { _closeTimer.stop(); sidebarRoot.visible = false }
                    else _closeTimer.restart()
                }
            }
            Timer { id: _closeTimer; interval: 300; onTriggered: sidebarRoot.visible = false }
            function hide() { GlobalStates.sidebarRightOpen = false }

            exclusiveZone: 0
            implicitWidth: screen?.width ?? 1920
            WlrLayershell.namespace: "quickshell:sidebarRight"
            WlrLayershell.keyboardFocus: GlobalStates.sidebarRightOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"
            anchors { top: true; right: true; bottom: true; left: true }

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    const lp = mapToItem(contentLoader, mouse.x, mouse.y)
                    if (lp.x < 0 || lp.x > contentLoader.width || lp.y < 0 || lp.y > contentLoader.height) sidebarRoot.hide()
                }
            }

            Loader {
                id: contentLoader
                active: GlobalStates.sidebarRightOpen || (Config?.options?.sidebar?.keepRightSidebarLoaded ?? true)
                anchors { top: parent.top; right: parent.right; bottom: parent.bottom; margins: root.globalMargin }
                width: root.sidebarWidth - root.globalMargin * 2

                transform: Translate {
                    x: GlobalStates.sidebarRightOpen ? 0 : (root.sidebarWidth + root.globalMargin)
                    Behavior on x {
                        enabled: !root.instantOpen
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }
                }

                focus: GlobalStates.sidebarRightOpen
                Keys.onPressed: event => { if (event.key === Qt.Key_Escape) sidebarRoot.hide() }

                sourceComponent: SidebarRightContent {
                    panelScreen: sidebarRoot.screen ?? null
                }
            }
        }
    }

    IpcHandler {
        target: "sidebarRight"
        function toggle(): void { GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen }
        function close(): void { GlobalStates.sidebarRightOpen = false }
        function open(): void { GlobalStates.sidebarRightOpen = true }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Multi-style dock — supports "pill" and "macos" styles.
 * Shows pinned apps + running apps from ToplevelManager.
 * Configurable position (top/bottom/left/right), auto-hide on hover,
 * show-on-desktop-only option, and app icon click-to-activate/launch.
 *
 * Ported from inir with simplification for compositor-agnostic use.
 */
Scope {
    id: root
    property bool pinned: Config.options?.dock?.pinnedOnStartup ?? false
    readonly property string position: Config.options?.dock?.position ?? "bottom"
    readonly property bool isVertical: position === "left" || position === "right"
    readonly property bool isTop: position === "top"
    readonly property bool isLeft: position === "left"
    readonly property bool isPillStyle: (Config.options?.dock?.style ?? "pill") === "pill"
    readonly property bool isMacosStyle: (Config.options?.dock?.style ?? "pill") === "macos"
    readonly property real dockHeight: Config.options?.dock?.height ?? 56
    readonly property real iconSize: Config.options?.dock?.iconSize ?? 40
    readonly property var pinnedApps: Config.options?.dock?.pinnedApps ?? ["kitty", "nemo", "zen-browser", "brave-browser"]
    readonly property real globalMargin: Config.options?.appearance?.bezel ?? 0

    // Running app list from ToplevelManager
    readonly property var runningAppIds: {
        const ids = new Set()
        for (const tl of ToplevelManager.toplevels.values) {
            if (tl.appId) ids.add(tl.appId)
        }
        return Array.from(ids)
    }

    // Merged list: pinned first, then running-only apps
    readonly property var dockItems: {
        const items = []
        // Pinned apps
        for (const appId of pinnedApps) {
            items.push({ appId: appId, pinned: true, running: runningAppIds.includes(appId) })
        }
        // Running but not pinned
        for (const appId of runningAppIds) {
            if (!pinnedApps.includes(appId)) {
                items.push({ appId: appId, pinned: false, running: true })
            }
        }
        return items
    }

    function activateApp(appId) {
        const tl = ToplevelManager.toplevels.values.find(t => t.appId === appId)
        if (tl) {
            tl.activated = true
            if (CompositorService.compositor === "hyprland") {
                const addr = tl.HyprlandToplevel?.address ?? ""
                if (addr) Quickshell.execDetached(["hyprctl", "dispatch", `focuswindow address:0x${addr}`])
            } else if (CompositorService.compositor === "niri") {
                // Niri focus by app-id
                NiriService.focusWindowByAppId(appId)
            }
        } else {
            // Not running — launch it
            Quickshell.execDetached([appId])
        }
    }

    Variants {
        model: {
            const screens = Quickshell.screens
            const list = Config.options?.dock?.screenList ?? []
            return (!list || list.length === 0) ? screens : screens.filter(s => list.includes(s.name))
        }

        PanelWindow {
            id: dockWindow
            required property var modelData
            screen: modelData
            visible: !GlobalStates.screenLocked && (Config.options?.dock?.enable ?? true)

            property bool reveal: root.pinned
                || dockHover.containsMouse
                || (Config.options?.dock?.showOnDesktop !== false && !ToplevelManager.activeToplevel?.activated)

            color: "transparent"
            exclusiveZone: root.pinned ? dockHeight : 0
            WlrLayershell.namespace: "quickshell:dock"
            WlrLayershell.layer: WlrLayer.Top

            anchors {
                top: root.isTop || root.isVertical
                bottom: !root.isTop || root.isVertical
                left: root.isLeft || !root.isVertical
                right: !root.isLeft || !root.isVertical
            }

            // Vertical bar fixes width, horizontal bar fixes height. 0 = let the
            // layout system pick the natural axis size.
            implicitWidth: root.isVertical ? (dockHeight + 16) : 0
            implicitHeight: root.isVertical ? 0 : (dockHeight + 16)

            mask: Region { item: dockBg }

            MouseArea {
                id: dockHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                // Dock background
                Rectangle {
                    id: dockBg
                    anchors.centerIn: parent
                    width: root.isVertical ? root.dockHeight : dockLayout.implicitWidth + 24
                    height: root.isVertical ? dockLayout.implicitHeight + 24 : root.dockHeight
                    radius: root.isPillStyle ? height / 2 : Appearance?.rounding.normal ?? 12
                    color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
                    border.width: 1
                    border.color: Appearance?.colors.colLayer0Border ?? "#44444488"

                    opacity: dockWindow.reveal ? 1 : 0
                    transform: Translate {
                        y: root.isVertical ? 0 : (dockWindow.reveal ? 0 : (root.isTop ? -root.dockHeight : root.dockHeight))
                        x: root.isVertical ? (dockWindow.reveal ? 0 : (root.isLeft ? -root.dockHeight : root.dockHeight)) : 0
                    }

                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    // App items layout
                    RowLayout {
                        id: dockLayout
                        anchors.centerIn: parent
                        spacing: root.isMacosStyle ? 2 : 6
                        layoutDirection: root.isVertical ? Qt.TopToBottom : Qt.LeftToRight

                        Repeater {
                            model: root.dockItems

                            Item {
                                required property var modelData
                                Layout.preferredWidth: root.iconSize + 8
                                Layout.preferredHeight: root.iconSize + 12

                                // App icon
                                Rectangle {
                                    id: iconBg
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    width: root.iconSize + 4; height: root.iconSize + 4
                                    radius: root.isMacosStyle ? Appearance?.rounding.small ?? 8 : (root.iconSize + 4) / 2
                                    color: iconMA.containsMouse
                                        ? Appearance?.colors.colLayer1Hover ?? "#E5DFED"
                                        : "transparent"

                                    scale: iconMA.pressed ? 0.85 : (iconMA.containsMouse ? 1.15 : 1)
                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    // Desktop icon from freedesktop
                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitWidth: root.iconSize
                                        implicitHeight: root.iconSize
                                        source: `image://icon/${modelData.appId}`
                                    }

                                    MouseArea {
                                        id: iconMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.activateApp(modelData.appId)
                                    }

                                    StyledToolTip {
                                        text: modelData.appId
                                        visible: iconMA.containsMouse
                                    }
                                }

                                // Running indicator dot
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: modelData.running ? 6 : 0
                                    height: 4; radius: 2
                                    color: Appearance?.colors.colPrimary ?? "#65558F"
                                    visible: modelData.running
                                    Behavior on width { NumberAnimation { duration: 150 } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "dock"
        function toggle(): void { root.pinned = !root.pinned }
        function pin(): void { root.pinned = true }
        function unpin(): void { root.pinned = false }
    }
}

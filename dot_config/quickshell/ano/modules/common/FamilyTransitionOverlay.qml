import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Family transition overlay — fullscreen animated transition when switching
 * between panel family presets. Shows a ripple circle expanding from center
 * with the shell logo, then fades out revealing the new family.
 */
Scope {
    id: root

    signal exitComplete()
    signal enterComplete()

    readonly property int enterDuration: Config.options?.animations?.enable ? 400 : 10
    readonly property int holdDuration: 250
    readonly property int exitDuration: Config.options?.animations?.enable ? 450 : 10

    property bool _phase: false // false = enter, true = exit
    property bool _active: false
    property real _overlayOpacity: 0

    Connections {
        target: GlobalStates
        function onFamilyTransitionActiveChanged() {
            if (GlobalStates.familyTransitionActive) {
                fadeOut.stop()
                root._phase = false
                root._active = true
                root._overlayOpacity = 1
                enterTimer.start()
            }
        }
    }

    Timer {
        id: enterTimer
        interval: root.enterDuration + 80
        onTriggered: { root.exitComplete(); holdTimer.start() }
    }

    Timer {
        id: holdTimer
        interval: root.holdDuration
        onTriggered: { root._phase = true; fadeOut.restart() }
    }

    NumberAnimation {
        id: fadeOut
        target: root; property: "_overlayOpacity"
        to: 0; duration: root.exitDuration
        easing.type: Easing.InOutCubic
        onFinished: { root._active = false; root.enterComplete() }
    }

    Loader {
        active: GlobalStates.familyTransitionActive || root._active

        sourceComponent: PanelWindow {
            visible: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: -1
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.namespace: "quickshell:familyTransition"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Item {
                anchors.fill: parent
                opacity: root._overlayOpacity

                // Background fill
                Rectangle {
                    anchors.fill: parent
                    color: Appearance?.m3colors.m3background ?? "#1C1B1F"
                }

                // Blurred wallpaper background with crossfade transition
                Item {
                    anchors.fill: parent
                    WallpaperCrossfader {
                        id: transitionWallpaper
                        anchors.fill: parent
                        source: {
                            const path = Config.options?.background?.wallpaperPath ?? ""
                            return path.length > 0 ? (path.startsWith("file://") ? path : "file://" + path) : ""
                        }
                        sourceSize: Qt.size(parent.width || 1920, parent.height || 1080)
                        visible: false
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: transitionWallpaper
                        visible: transitionWallpaper.source.toString().length > 0
                        blurEnabled: true; blur: 0.8; blurMax: 64
                        saturation: 0.3
                    }
                    Rectangle { anchors.fill: parent; color: Appearance?.m3colors.m3background ?? "#1C1B1F"; opacity: 0.3 }
                }

                // Expanding ripple circle
                Rectangle {
                    id: ripple
                    anchors.centerIn: parent
                    readonly property real maxRadius: Math.sqrt(parent.width * parent.width + parent.height * parent.height) / 2 + 100
                    property bool expanded: false

                    Component.onCompleted: Qt.callLater(() => expanded = true)

                    width: expanded && !root._phase ? maxRadius * 2 : 0
                    height: width; radius: width / 2
                    color: Qt.rgba((Appearance?.colors.colPrimaryContainer ?? "#4A4458").r, (Appearance?.colors.colPrimaryContainer ?? "#4A4458").g, (Appearance?.colors.colPrimaryContainer ?? "#4A4458").b, 0.4)
                    opacity: root._phase ? 0 : 1

                    Behavior on width { NumberAnimation { duration: root._phase ? root.exitDuration * 0.7 : root.enterDuration; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: root.exitDuration; easing.type: Easing.OutQuad } }
                }

                // Secondary ripple ring
                Rectangle {
                    anchors.centerIn: parent
                    width: ripple.expanded && !root._phase ? ripple.maxRadius * 2.1 : 0
                    height: width; radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.3)
                    opacity: root._phase ? 0 : 1

                    Behavior on width { NumberAnimation { duration: root._phase ? root.exitDuration * 0.6 : root.enterDuration + 80; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: root.exitDuration * 0.8 } }
                }

                // Center content
                Column {
                    id: centerContent
                    anchors.centerIn: parent; spacing: 14
                    property bool showContent: false
                    Component.onCompleted: Qt.callLater(() => showContentTimer.start())
                    Timer { id: showContentTimer; interval: 180; onTriggered: centerContent.showContent = true }

                    opacity: root._phase ? 0 : (centerContent.showContent ? 1 : 0)
                    scale: root._phase ? 0.9 : (centerContent.showContent ? 1 : 0.75)
                    Behavior on opacity { NumberAnimation { duration: root._phase ? 200 : 280; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: root._phase ? 200 : 350; easing.type: Easing.OutCubic } }

                    // Logo circle
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64; height: 64; radius: 32
                        color: Appearance?.colors.colPrimaryContainer ?? "#4A4458"
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "terminal"; iconSize: 36; fill: 1
                            color: Appearance?.m3colors.m3onPrimaryContainer ?? "#EADDFF"
                        }
                    }

                    // Title
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 2
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Ano Shell"
                            font.pixelSize: Appearance?.font.pixelSize.title ?? 24
                            font.weight: Font.Medium
                            color: Appearance?.m3colors.m3onSurface ?? "#E6E1E5"
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Loading configuration..."
                            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                            color: Appearance?.m3colors.m3onSurface ?? "#E6E1E5"; opacity: 0.6
                        }
                    }
                }
            }
        }
    }
}

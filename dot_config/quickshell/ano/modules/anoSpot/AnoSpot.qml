import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * AnoSpot — dynamic-island-style overlay aggregating Mpris, Notifications,
 * Recording, and Clock/Weather. Compositor-agnostic: never reads HyprlandData
 * directly; all compositor state flows through CompositorService.
 *
 * Toggle:    Config.options.anoSpot.enable
 * Position:  Config.options.anoSpot.position ∈ {top, bottom, left, right}
 *            (invalid values fall back to "top")
 */
Scope {
    id: root

    readonly property bool enabled: Config.options?.anoSpot?.enable ?? false
    readonly property string rawPosition: Config.options?.anoSpot?.position ?? "top"
    readonly property string position: ["top", "bottom", "left", "right"].indexOf(rawPosition) >= 0
                                        ? rawPosition : "top"
    readonly property int widthPx: Config.options?.anoSpot?.widthPx ?? 420
    readonly property int heightPx: Config.options?.anoSpot?.heightPx ?? 36
    readonly property bool isVertical: position === "left" || position === "right"

    readonly property bool showMpris: Config.options?.anoSpot?.showMpris ?? true
    readonly property bool showNotification: Config.options?.anoSpot?.showNotification ?? true
    readonly property bool showRecording: Config.options?.anoSpot?.showRecording ?? true
    readonly property bool showClockWeather: Config.options?.anoSpot?.showClockWeather ?? true
    readonly property bool showBattery: Config.options?.anoSpot?.showBattery ?? true
    readonly property bool showWorkspace: Config.options?.anoSpot?.showWorkspace ?? true

    readonly property var actions: Config.options?.anoSpot?.actions ?? ({})
    readonly property bool draggable: Config.options?.anoSpot?.draggable ?? true
    readonly property bool acceptDrops: Config.options?.anoSpot?.acceptDrops ?? true

    // Snap a free pointer position to one of the four screen edges based
    // on which edge it ended up closest to. Returns "top"/"bottom"/"left"/"right".
    function _nearestEdge(globalX, globalY, screenW, screenH) {
        const dTop = globalY;
        const dBottom = screenH - globalY;
        const dLeft = globalX;
        const dRight = screenW - globalX;
        const minD = Math.min(dTop, dBottom, dLeft, dRight);
        if (minD === dTop)    return "top";
        if (minD === dBottom) return "bottom";
        if (minD === dLeft)   return "left";
        return "right";
    }

    function _dispatchClick(button) {
        let target = "";
        if (button === Qt.LeftButton)        target = root.actions.leftClick   ?? "mediaControls";
        else if (button === Qt.RightButton)  target = root.actions.rightClick  ?? "controlPanel";
        else if (button === Qt.MiddleButton) target = root.actions.middleClick ?? "anoview";
        if (target.length > 0) {
            Quickshell.execDetached(["qs", "-c", "ano", "ipc", "call", target, "toggle"]);
        }
    }

    // ─── Event border ────────────────────────────────────────────────────
    // Animated gradient halo behind the pill that pulses on configured
    // events. The current renderer (per-screen child below) uses a
    // ConicalGradient sweep as a placeholder; a Siri-style flowing-color
    // shader is planned to replace it later. The borderPulse signal is the
    // stable interface — swap the visual without touching this section.
    readonly property var eventBorderCfg: Config.options?.anoSpot?.eventBorder ?? ({})
    readonly property bool eventBorderEnabled: eventBorderCfg.enable ?? true
    readonly property int eventBorderHoldMs: eventBorderCfg.holdMs ?? 1500
    readonly property var eventBorderEvents: eventBorderCfg.events ?? ["notification", "track", "recording", "workspace"]

    signal borderPulse()

    function triggerBorder(eventType) {
        if (!eventBorderEnabled) return;
        if (eventBorderEvents.indexOf(eventType) < 0) return;
        root.borderPulse();
    }

    Connections {
        target: Notifications
        function onNotify(_) { root.triggerBorder("notification") }
    }
    Connections {
        target: MprisController
        function onActiveTrackChanged() { root.triggerBorder("track") }
    }
    Connections {
        target: RecorderStatus
        function onIsRecordingChanged() { root.triggerBorder("recording") }
    }
    Connections {
        target: CompositorService
        function onActiveWorkspaceIndexChanged() { root.triggerBorder("workspace") }
    }

    Variants {
        model: root.enabled ? Quickshell.screens : []

        PanelWindow {
            id: spotWindow
            required property var modelData
            screen: modelData

            visible: root.enabled
            color: "transparent"

            implicitWidth: root.isVertical ? root.heightPx : root.widthPx
            implicitHeight: root.isVertical ? root.widthPx : root.heightPx

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:anospot"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: root.position === "top" || root.isVertical
                bottom: root.position === "bottom" || root.isVertical
                left: root.position === "left" || !root.isVertical
                right: root.position === "right" || !root.isVertical
            }

            margins {
                top: root.position === "top" ? 6 : 0
                bottom: root.position === "bottom" ? 6 : 0
                left: root.position === "left" ? 6 : 0
                right: root.position === "right" ? 6 : 0
            }

            // Animated gradient ring rendered behind the pill. When the
            // border-pulse opacity is zero this is invisible and free.
            // When it ramps up, the slightly-oversized conical-gradient
            // rectangle peeks out from behind the pill as a colored halo
            // whose hue rotates over the pulse cycle.
            Item {
                id: borderHalo
                anchors.centerIn: parent
                width: parent.width + 4
                height: parent.height + 4
                opacity: 0
                visible: opacity > 0
                z: -1

                property real angle: 0

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(width, height) / 2
                    layer.enabled: true
                    layer.effect: ConicalGradient {
                        angle: borderHalo.angle
                        gradient: Gradient {
                            GradientStop { position: 0.00; color: Appearance?.colors?.colPrimary    ?? "#a6e3a1" }
                            GradientStop { position: 0.33; color: Appearance?.colors?.colSecondary  ?? "#cba6f7" }
                            GradientStop { position: 0.66; color: Appearance?.colors?.colTertiary   ?? "#94e2d5" }
                            GradientStop { position: 1.00; color: Appearance?.colors?.colPrimary    ?? "#a6e3a1" }
                        }
                    }
                    color: "white"  // overwritten by the conical gradient layer effect
                }

                Connections {
                    target: root
                    function onBorderPulse() { borderAnim.restart() }
                }

                SequentialAnimation {
                    id: borderAnim
                    ParallelAnimation {
                        NumberAnimation { target: borderHalo; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                        RotationAnimation { target: borderHalo; property: "angle"; from: 0; to: 360
                                            duration: 200 + root.eventBorderHoldMs + 400; easing.type: Easing.Linear }
                    }
                    PauseAnimation { duration: root.eventBorderHoldMs }
                    NumberAnimation { target: borderHalo; property: "opacity"; to: 0; duration: 400; easing.type: Easing.InCubic }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: Math.min(width, height) / 2
                color: Appearance?.colors?.colLayer0 ?? "#1e1e2e"
                // Glass-token-driven border + opacity so static themes
                // (aurora, angel, etc.) can dial the pill's translucency.
                // Material You and "neutral" static themes leave the
                // tokens at sensible defaults and look unchanged.
                border.width: Appearance?.glassTokens?.borderWidth ?? 1
                border.color: Appearance?.glassTokens?.borderColor
                            ?? Appearance?.colors?.colOutlineVariant
                            ?? "#444"
                opacity: Appearance?.glassTokens?.opacity ?? 0.96

                // Click dispatcher — catches left/right/middle on the pill background.
                // Widget MouseAreas (e.g. AnoSpotMpris wheel handler) sit above this
                // and intercept their own events; unclaimed clicks fall through here.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => root._dispatchClick(mouse.button)
                }

                // Drop target — files/URIs dragged from any Wayland source
                // get copied into the AnoSpotStash and the popout opens.
                Loader {
                    anchors.fill: parent
                    active: root.acceptDrops
                    sourceComponent: dropAreaComp
                }
                Component {
                    id: dropAreaComp
                    DropArea {
                        keys: ["text/uri-list"]
                        property bool dropHover: false

                        onEntered: drag => {
                            if (drag.hasUrls) {
                                dropHover = true;
                                drag.accept();
                            }
                        }
                        onExited: dropHover = false
                        onDropped: drop => {
                            if (drop.hasUrls) {
                                AnoSpotStash.addUrls(drop.urls);
                                GlobalStates.anoSpotStashOpen = true;
                                drop.accept();
                            }
                            dropHover = false;
                        }

                        // Drop hover indicator: tinted overlay on the pill.
                        Rectangle {
                            anchors.fill: parent
                            radius: Math.min(width, height) / 2
                            color: Appearance?.colors?.colPrimary ?? "#a6e3a1"
                            opacity: parent.dropHover ? 0.18 : 0
                            border.width: parent.dropHover ? 2 : 0
                            border.color: Appearance?.colors?.colPrimary ?? "#a6e3a1"
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                    }
                }

                // Drag handle — leading edge of the pill. Press, drag the
                // pointer toward any screen edge, release to snap. The pill
                // itself is layer-shell-anchored so it doesn't free-float;
                // we just compute the pointer's release-point edge and
                // rewrite Config.options.anoSpot.position.
                Rectangle {
                    id: dragHandle
                    visible: root.draggable
                    width: root.isVertical ? parent.width : 14
                    height: root.isVertical ? 14 : parent.height
                    color: "transparent"
                    anchors {
                        top: root.isVertical ? parent.top : undefined
                        left: root.isVertical ? undefined : parent.left
                        horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
                        verticalCenter: root.isVertical ? undefined : parent.verticalCenter
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "drag_indicator"
                        iconSize: 12
                        opacity: handleArea.containsMouse || handleArea.drag.active ? 0.85 : 0.5
                        rotation: root.isVertical ? 90 : 0
                        color: Appearance?.colors?.colOnLayer0Subtle ?? "#a6adc8"
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: handleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeAllCursor
                        acceptedButtons: Qt.LeftButton
                        // Drag tracking: we don't bind drag.target (the layer-shell
                        // window can't free-float); we just monitor pointer
                        // position and snap on release.
                        property real lastGlobalX: 0
                        property real lastGlobalY: 0
                        onPressed: mouse => {
                            const gp = mapToGlobal(mouse.x, mouse.y);
                            lastGlobalX = gp.x; lastGlobalY = gp.y;
                        }
                        onPositionChanged: mouse => {
                            if (!pressed) return;
                            const gp = mapToGlobal(mouse.x, mouse.y);
                            lastGlobalX = gp.x; lastGlobalY = gp.y;
                        }
                        onReleased: {
                            const screen = spotWindow.screen;
                            if (!screen) return;
                            const newEdge = root._nearestEdge(
                                lastGlobalX, lastGlobalY,
                                screen.width, screen.height
                            );
                            if (newEdge !== root.position)
                                Config.setNestedValue("anoSpot.position", newEdge);
                        }
                    }
                }

                // Horizontal layout for top/bottom; vertical for left/right
                Loader {
                    anchors.fill: parent
                    anchors.margins: 6
                    // Reserve space for the drag handle on the leading edge
                    anchors.leftMargin: !root.isVertical && root.draggable ? 18 : 6
                    anchors.topMargin: root.isVertical && root.draggable ? 18 : 6
                    sourceComponent: root.isVertical ? verticalLayout : horizontalLayout
                }

                Component {
                    id: horizontalLayout
                    RowLayout {
                        spacing: 10
                        AnoSpotWorkspace  { visible: root.showWorkspace }
                        AnoSpotMpris      { visible: root.showMpris && AnoSpotState.mpris !== null }
                        AnoSpotRecording  { visible: root.showRecording && AnoSpotState.recording.active }
                        AnoSpotNotification { Layout.fillWidth: true; visible: root.showNotification && AnoSpotState.latestNotification !== null }
                        AnoSpotClockWeather { visible: root.showClockWeather }
                        AnoSpotBattery    { /* visible binding lives in the widget */ }
                    }
                }

                Component {
                    id: verticalLayout
                    ColumnLayout {
                        spacing: 10
                        AnoSpotWorkspace  { visible: root.showWorkspace }
                        AnoSpotMpris      { visible: root.showMpris && AnoSpotState.mpris !== null }
                        AnoSpotRecording  { visible: root.showRecording && AnoSpotState.recording.active }
                        AnoSpotNotification { Layout.fillHeight: true; visible: root.showNotification && AnoSpotState.latestNotification !== null }
                        AnoSpotClockWeather { visible: root.showClockWeather }
                        AnoSpotBattery    { /* visible binding lives in the widget */ }
                    }
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Draggable recording OSD — a floating pill that appears whenever
 * RecorderStatus.isRecording flips true. Shows a pulsing red dot,
 * elapsed timer, stop button, and (when expanded) audio/mic mute
 * toggles. Snaps to the nearest screen edge on drag-release; flips
 * vertical when snapped to left/right.
 *
 * Adapted from inir/modules/recordingOsd/RecordingOsd.qml. Foreign
 * theming (Appearance.angel/inir/aurora, GlassBackground,
 * StyledRectangularShadow) collapsed to ano's Appearance.colors +
 * a plain Rectangle. Translation.tr() calls dropped.
 */
Scope {
    id: root

    property bool isVertical: false
    property bool collapsed: false

    function formatTime(totalSeconds: int): string {
        const hours = Math.floor(totalSeconds / 3600)
        const minutes = Math.floor((totalSeconds % 3600) / 60)
        const seconds = totalSeconds % 60
        const pad = (n) => n < 10 ? "0" + n : "" + n
        if (hours > 0) return pad(hours) + ":" + pad(minutes) + ":" + pad(seconds)
        return pad(minutes) + ":" + pad(seconds)
    }

    function stopRecording(): void {
        Quickshell.execDetached(["/usr/bin/pkill", "-SIGINT", "wf-recorder"])
    }

    Connections {
        target: RecorderStatus
        function onIsRecordingChanged(): void {
            if (RecorderStatus.isRecording) {
                root.collapsed = false
                root.isVertical = false
            }
        }
    }

    Loader {
        id: osdLoader
        active: RecorderStatus.isRecording

        sourceComponent: PanelWindow {
            id: osdWindow
            visible: osdLoader.active && !GlobalStates.screenLocked
            screen: GlobalStates.primaryScreen

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:recordingOsd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"

            mask: Region { item: pill }

            readonly property real edgeMargin: 8

            function snapToNearestEdge(): void {
                const margin = edgeMargin
                const pw = osdWindow.width
                const ph = osdWindow.height
                const pillW = pill.width
                const pillH = pill.height
                const cx = pill.x + pillW / 2
                const cy = pill.y + pillH / 2

                const distLeft = pill.x
                const distRight = pw - (pill.x + pillW)
                const distTop = pill.y
                const distBottom = ph - (pill.y + pillH)

                const minDist = Math.min(distLeft, distRight, distTop, distBottom)

                const wasVertical = root.isVertical
                const snapsToSide = (minDist === distLeft || minDist === distRight)
                root.isVertical = snapsToSide

                let targetX, targetY

                if (snapsToSide) {
                    targetX = (minDist === distLeft) ? margin : pw - pillW - margin
                    targetY = Math.max(margin, Math.min(ph - pillH - margin, pill.y))
                } else {
                    targetY = (minDist === distTop) ? margin : ph - pillH - margin
                    targetX = Math.max(margin, Math.min(pw - pillW - margin, pill.x))
                }

                if (root.isVertical !== wasVertical) {
                    Qt.callLater(() => {
                        const newPillW = pill.width
                        const newPillH = pill.height

                        let newX, newY
                        if (snapsToSide) {
                            newX = (minDist === distLeft) ? margin : pw - newPillW - margin
                            newY = Math.max(margin, Math.min(ph - newPillH - margin, cy - newPillH / 2))
                        } else {
                            newY = (minDist === distTop) ? margin : ph - newPillH - margin
                            newX = Math.max(margin, Math.min(pw - newPillW - margin, cx - newPillW / 2))
                        }

                        pill.animatePosition = true
                        pill.x = newX
                        pill.y = newY
                    })
                    return
                }

                pill.animatePosition = true
                pill.x = targetX
                pill.y = targetY
            }

            Item {
                id: pill
                property bool animatePosition: false
                property real contentPadding: 6
                property bool _positioned: false

                width: root.isVertical
                    ? verticalContent.implicitWidth + contentPadding * 2
                    : horizontalContent.implicitWidth + contentPadding * 2
                height: root.isVertical
                    ? verticalContent.implicitHeight + contentPadding * 2
                    : horizontalContent.implicitHeight + contentPadding * 2

                Connections {
                    target: osdWindow
                    function onWidthChanged(): void {
                        if (!pill._positioned && osdWindow.width > 0) {
                            pill.x = (osdWindow.width - pill.width) / 2
                            pill.y = osdWindow.edgeMargin
                            pill._positioned = true
                            Qt.callLater(() => { pill.initScale = 1.0 })
                        }
                    }
                }

                property real initScale: 0.9
                scale: initScale
                opacity: initScale < 0.95 ? 0 : 1
                transformOrigin: Item.Center

                // Drop shadow under the pill. Drawn first so the pill
                // background paints over it.
                DropShadow {
                    anchors.fill: pillBg
                    source: pillBg
                    horizontalOffset: 0
                    verticalOffset: 4
                    radius: 14
                    samples: 21
                    color: Qt.rgba(0, 0, 0, 0.45)
                    cached: true
                }

                // Background — translucent rounded rect themed from the
                // active palette + glass tokens. Themes that ship higher
                // glass.opacity (aurora, angel) make the pill more
                // see-through; opaque themes (most) leave it close to a
                // solid surface.
                Rectangle {
                    id: pillBg
                    anchors.fill: parent
                    radius: Math.min(width, height) / 2
                    color: Appearance?.colors?.colLayer2 ?? "#3a3845"
                    border.width: Appearance?.glassTokens?.borderWidth ?? 1
                    border.color: Appearance?.glassTokens?.borderColor
                                ?? Appearance?.colors?.colOutlineVariant
                                ?? "#444"
                    opacity: Appearance?.glassTokens?.opacity ?? 0.96
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on x {
                    enabled: pill.animatePosition
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                        onRunningChanged: if (!running) pill.animatePosition = false
                    }
                }
                Behavior on y {
                    enabled: pill.animatePosition
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on width {
                    enabled: pill.animatePosition
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on height {
                    enabled: pill.animatePosition
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                // Horizontal layout (default, top/bottom edge)
                RowLayout {
                    id: horizontalContent
                    visible: !root.isVertical
                    anchors.centerIn: parent
                    spacing: 2

                    OsdDragHandle { isVertical: false }

                    RecordingIndicator { isVertical: false }

                    OsdPillButton {
                        iconName: "stop"
                        filled: true
                        iconColor: Appearance?.colors?.colError ?? "#f38ba8"
                        onClicked: root.stopRecording()
                        tooltip: "Stop recording"
                    }

                    OsdSeparator { isVertical: false; visible: !root.collapsed }

                    OsdPillButton {
                        visible: !root.collapsed
                        iconName: (Audio.sink?.audio?.muted ?? false) ? "volume_off" : "volume_up"
                        dimmed: Audio.sink?.audio?.muted ?? false
                        onClicked: Audio.toggleMute()
                        tooltip: (Audio.sink?.audio?.muted ?? false) ? "Unmute audio" : "Mute audio"
                    }
                    OsdPillButton {
                        visible: !root.collapsed
                        iconName: (Audio.source?.audio?.muted ?? false) ? "mic_off" : "mic"
                        dimmed: Audio.source?.audio?.muted ?? false
                        onClicked: Audio.toggleMicMute()
                        tooltip: (Audio.source?.audio?.muted ?? false) ? "Unmute mic" : "Mute mic"
                    }

                    OsdPillButton {
                        iconName: root.collapsed ? "open_in_full" : "close_fullscreen"
                        onClicked: root.collapsed = !root.collapsed
                        tooltip: root.collapsed ? "Expand controls" : "Minimize"
                    }
                }

                // Vertical layout (left/right edge)
                ColumnLayout {
                    id: verticalContent
                    visible: root.isVertical
                    anchors.centerIn: parent
                    spacing: 2

                    OsdDragHandle { isVertical: true }

                    RecordingIndicator { isVertical: true }

                    OsdPillButton {
                        iconName: "stop"
                        filled: true
                        iconColor: Appearance?.colors?.colError ?? "#f38ba8"
                        onClicked: root.stopRecording()
                        tooltip: "Stop recording"
                    }

                    OsdSeparator { isVertical: true; visible: !root.collapsed }

                    OsdPillButton {
                        visible: !root.collapsed
                        iconName: (Audio.sink?.audio?.muted ?? false) ? "volume_off" : "volume_up"
                        dimmed: Audio.sink?.audio?.muted ?? false
                        onClicked: Audio.toggleMute()
                        tooltip: (Audio.sink?.audio?.muted ?? false) ? "Unmute audio" : "Mute audio"
                    }
                    OsdPillButton {
                        visible: !root.collapsed
                        iconName: (Audio.source?.audio?.muted ?? false) ? "mic_off" : "mic"
                        dimmed: Audio.source?.audio?.muted ?? false
                        onClicked: Audio.toggleMicMute()
                        tooltip: (Audio.source?.audio?.muted ?? false) ? "Unmute mic" : "Mute mic"
                    }

                    OsdPillButton {
                        iconName: root.collapsed ? "open_in_full" : "close_fullscreen"
                        onClicked: root.collapsed = !root.collapsed
                        tooltip: root.collapsed ? "Expand controls" : "Minimize"
                    }
                }
            }
        }
    }

    // Drag handle with hover feedback
    component OsdDragHandle: Item {
        id: dragHandle
        required property bool isVertical

        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        Layout.alignment: Qt.AlignCenter

        opacity: dragHover.hovered || dragHandler.active ? 0.8 : 0.4

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: dragHandler.active
                ? (Appearance?.colors?.colLayer2Active ?? "#444")
                : dragHover.hovered
                    ? (Appearance?.colors?.colLayer2Hover ?? "#3a3a3a")
                    : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "drag_indicator"
            iconSize: 14
            color: Appearance?.colors?.colOnLayer2 ?? "#cdd6f4"
        }

        HoverHandler {
            id: dragHover
            cursorShape: dragHandler.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        }

        DragHandler {
            id: dragHandler
            target: pill
            xAxis.minimum: 0
            xAxis.maximum: osdLoader.item ? osdLoader.item.width - pill.width : 0
            yAxis.minimum: 0
            yAxis.maximum: osdLoader.item ? osdLoader.item.height - pill.height : 0
            onActiveChanged: {
                if (active) pill.animatePosition = false
                else if (osdLoader.item) osdLoader.item.snapToNearestEdge()
            }
        }
    }

    component OsdSeparator: Rectangle {
        required property bool isVertical

        Layout.preferredWidth: isVertical ? 22 : 1
        Layout.preferredHeight: isVertical ? 1 : 22
        Layout.alignment: Qt.AlignCenter
        color: Appearance?.colors?.colOutlineVariant ?? "#44444466"
        opacity: 0.3
    }

    // Recording dot + timer
    component RecordingIndicator: Item {
        id: indicator
        required property bool isVertical

        readonly property string timeString: root.formatTime(RecorderStatus.elapsedSeconds)
        readonly property var timeParts: timeString.split(/([:])/)

        Layout.alignment: Qt.AlignCenter
        implicitWidth: isVertical ? verticalIndicator.implicitWidth : horizontalIndicator.implicitWidth
        implicitHeight: isVertical ? verticalIndicator.implicitHeight : horizontalIndicator.implicitHeight

        RowLayout {
            id: horizontalIndicator
            visible: !indicator.isVertical
            spacing: 4
            anchors.centerIn: parent

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 8; height: 8; radius: 4
                color: Appearance?.colors?.colError ?? "#f38ba8"
                SequentialAnimation on opacity {
                    running: osdLoader.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: hTimerMetrics.width
                implicitHeight: hTimerText.implicitHeight

                TextMetrics {
                    id: hTimerMetrics
                    text: RecorderStatus.elapsedSeconds >= 3600 ? "00:00:00" : "00:00"
                    font: hTimerText.font
                }

                Text {
                    id: hTimerText
                    anchors.centerIn: parent
                    text: indicator.timeString
                    font.family: Appearance?.font?.family?.monospace ?? "monospace"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Appearance?.colors?.colOnLayer2 ?? "#cdd6f4"
                }
            }
        }

        ColumnLayout {
            id: verticalIndicator
            visible: indicator.isVertical
            spacing: 1
            anchors.centerIn: parent

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 8; height: 8; radius: 4
                color: Appearance?.colors?.colError ?? "#f38ba8"
                SequentialAnimation on opacity {
                    running: osdLoader.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            Repeater {
                model: indicator.timeParts

                Text {
                    required property string modelData
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData === ":" ? "··" : modelData
                    font.family: Appearance?.font?.family?.monospace ?? "monospace"
                    font.pixelSize: modelData === ":" ? 10 : 12
                    font.weight: Font.Medium
                    color: Appearance?.colors?.colOnLayer2 ?? "#cdd6f4"
                    opacity: modelData === ":" ? 0.5 : 1.0
                }
            }
        }
    }

    // Icon button with hover reveal
    component OsdPillButton: RippleButton {
        id: btn
        required property string iconName
        property string tooltip: ""
        property bool dimmed: false
        property bool filled: false
        property color iconColor: Appearance?.colors?.colOnLayer2 ?? "#cdd6f4"

        Layout.preferredWidth: 30
        Layout.preferredHeight: 30
        Layout.alignment: Qt.AlignCenter
        buttonRadius: 15
        colBackground: "transparent"

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: btn.iconName
            iconSize: 18
            fill: btn.filled ? 1 : 0
            color: btn.iconColor
            opacity: btn.dimmed ? 0.4 : 1.0
        }

        StyledToolTip {
            text: btn.tooltip
            visible: btn.tooltip.length > 0 && btn.hovered
        }
    }

    IpcHandler {
        target: "recordingOsd"

        function toggle(): void {
            if (RecorderStatus.isRecording)
                root.stopRecording()
        }

        function show(): void {
            root.collapsed = false
        }

        function hide(): void {
            root.collapsed = true
        }
    }
}

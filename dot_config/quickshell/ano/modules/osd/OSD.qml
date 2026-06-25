import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * On-Screen Display — shows volume, brightness, mic, media, keyboard layout,
 * caps lock, and network indicators as a floating pill that auto-hides.
 *
 * Configurable position, timeout, and which indicators are enabled.
 */
Scope {
    id: root

    // Current OSD state
    property string currentIndicator: ""
    property real currentValue: 0
    property bool currentMuted: false
    property string currentLabel: ""

    // Config
    readonly property int timeout: Config.options?.osd?.timeout ?? 1500
    readonly property string position: Config.options?.osd?.position ?? "bottom"
    readonly property bool enableVolume: Config.options?.osd?.indicators?.volume ?? true
    readonly property bool enableBrightness: Config.options?.osd?.indicators?.brightness ?? true
    readonly property bool enableMic: Config.options?.osd?.indicators?.mic ?? true
    readonly property bool enableMedia: Config.options?.osd?.indicators?.media ?? true
    readonly property bool enableKeyboard: Config.options?.osd?.indicators?.keyboard ?? true
    readonly property bool enableNetwork: Config.options?.osd?.indicators?.network ?? true

    Timer {
        id: hideTimer
        interval: root.timeout
        onTriggered: root.currentIndicator = ""
    }

    function show(indicator, value, muted, label) {
        root.currentIndicator = indicator
        root.currentValue = value ?? 0
        root.currentMuted = muted ?? false
        root.currentLabel = label ?? ""
        hideTimer.restart()
    }

    // ═══ Volume ═══
    Connections {
        enabled: root.enableVolume
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() { root.show("volume", Audio.sink.audio.volume, Audio.sink.audio.muted) }
        function onMutedChanged() { root.show("volume", Audio.sink.audio.volume, Audio.sink.audio.muted) }
    }

    // ═══ Brightness ═══
    Connections {
        enabled: root.enableBrightness
        target: Brightness
        function onBrightnessChanged() {
            const focusedName = CompositorService.focusedMonitorName
            const monitor = Brightness.monitors.find(m => focusedName === m.screen.name)
            if (monitor) root.show("brightness", monitor.brightness, false)
        }
    }

    // ═══ Mic Mute ═══
    Connections {
        enabled: root.enableMic
        target: Audio.source?.audio ?? null
        function onMutedChanged() { root.show("mic", Audio.source.audio.volume, Audio.source.audio.muted) }
    }

    // ═══ Media Track Change ═══
    Connections {
        enabled: root.enableMedia
        target: MprisController
        function onTrackChanged() {
            if (!MprisController.activeTrack) return
            root.show("media", 0, false, `${MprisController.activeTrack.title ?? ""} — ${MprisController.activeTrack.artist ?? ""}`)
        }
    }

    // ═══ Keyboard Layout ═══
    Connections {
        enabled: root.enableKeyboard && KeyboardLayoutService.layoutCodes.length > 1
        target: KeyboardLayoutService
        function onCurrentLayoutNameChanged() {
            if (KeyboardLayoutService.currentLayoutName.length > 0)
                root.show("keyboard", 0, false, KeyboardLayoutService.currentLayoutName)
        }
    }

    // ═══ Network State ═══
    Connections {
        enabled: root.enableNetwork
        target: Network
        function onWifiStatusChanged() {
            if (Network.wifiStatus === "connected" && Network.networkName)
                root.show("network", Network.networkStrength / 100, false, Network.networkName)
            else if (Network.wifiStatus === "disconnected")
                root.show("network", 0, false, "WiFi disconnected")
        }
    }

    // ═══ Per-screen instances ═══
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: osdWindow
            required property var modelData
            screen: modelData

            visible: root.currentIndicator.length > 0
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:osd"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: root.position === "top"
                bottom: root.position !== "top"
                left: true; right: true
            }
            implicitHeight: 140
            margins {
                top: root.position === "top" ? 40 : 0
                bottom: root.position !== "top" ? 40 : 0
            }

            mask: Region { item: osdPill }

            // OSD pill
            Rectangle {
                id: osdPill
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: root.position !== "top" ? parent.bottom : undefined
                anchors.top: root.position === "top" ? parent.top : undefined

                // Width depends on whether we have a label or a progress bar
                property bool isProgressType: ["volume", "brightness", "mic"].includes(root.currentIndicator)
                property bool isLabelType: ["media", "keyboard", "network"].includes(root.currentIndicator)

                width: isLabelType ? Math.min(labelRow.implicitWidth + 40, 420) : 280
                height: 56
                radius: 28
                color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
                border.width: 1
                border.color: Appearance?.colors.colLayer0Border ?? "#44444488"

                opacity: root.currentIndicator.length > 0 ? 1 : 0
                scale: root.currentIndicator.length > 0 ? 1 : 0.8

                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                // Progress mode (volume/brightness/mic)
                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                    spacing: 12
                    visible: osdPill.isProgressType

                    MaterialSymbol {
                        text: {
                            if (root.currentMuted) {
                                if (root.currentIndicator === "volume") return "volume_off"
                                if (root.currentIndicator === "mic") return "mic_off"
                            }
                            switch (root.currentIndicator) {
                                case "volume":
                                    if (root.currentValue > 0.66) return "volume_up"
                                    if (root.currentValue > 0.33) return "volume_down"
                                    if (root.currentValue > 0) return "volume_mute"
                                    return "volume_off"
                                case "brightness":
                                    if (root.currentValue > 0.66) return "brightness_high"
                                    if (root.currentValue > 0.33) return "brightness_medium"
                                    return "brightness_low"
                                case "mic": return root.currentMuted ? "mic_off" : "mic"
                                default: return "info"
                            }
                        }
                        iconSize: 24; fill: 1
                        color: root.currentMuted
                            ? Appearance?.m3colors.m3error ?? "#BA1A1A"
                            : Appearance?.colors.colPrimary ?? "#65558F"
                    }

                    StyledProgressBar {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        valueBarHeight: 6
                        value: root.currentMuted ? 0 : root.currentValue
                        highlightColor: root.currentMuted
                            ? Appearance?.m3colors.m3error ?? "#BA1A1A"
                            : Appearance?.colors.colPrimary ?? "#65558F"
                    }

                    StyledText {
                        text: root.currentMuted ? "Muted" : `${Math.round(root.currentValue * 100)}%`
                        font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                        font.family: Appearance?.font.family.numbers ?? "monospace"
                        font.weight: Font.DemiBold
                        color: root.currentMuted
                            ? Appearance?.m3colors.m3error ?? "#BA1A1A"
                            : Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                        Layout.preferredWidth: 50
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Label mode (media/keyboard/network)
                RowLayout {
                    id: labelRow
                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                    spacing: 12
                    visible: osdPill.isLabelType

                    MaterialSymbol {
                        text: {
                            switch (root.currentIndicator) {
                                case "media": return MprisController.isPlaying ? "music_note" : "pause"
                                case "keyboard": return "keyboard"
                                case "network": return Network.materialSymbol
                                default: return "info"
                            }
                        }
                        iconSize: 24; fill: 1
                        color: Appearance?.colors.colPrimary ?? "#65558F"
                    }

                    StyledText {
                        text: root.currentLabel
                        font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                        font.weight: Font.DemiBold
                        color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.maximumWidth: 320
                    }
                }
            }
        }
    }
}

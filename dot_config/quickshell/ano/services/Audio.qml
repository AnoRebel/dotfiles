pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * Audio service wrapping PipeWire default sink/source.
 * Provides volume control, mute toggles, device listing, and volume protection.
 */
Singleton {
    id: root

    // State
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00
    property real value: sink?.audio.volume ?? 0

    // Device lists
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter(node => root.correctType(node, isSink) && node.isStream)
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => root.correctType(node, isSink) && !node.isStream)
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    // Friendly names. Null-guarded — nodes can transiently be null
    // during reconnection.
    function friendlyDeviceName(node) {
        if (!node) return "Unknown"
        return node.nickname || node.description || "Unknown"
    }
    function appNodeDisplayName(node) {
        if (!node) return ""
        return (node.properties && node.properties["application.name"]) || node.description || node.name || ""
    }

    // Signals
    signal sinkProtectionTriggered(string reason)

    // Controls
    function toggleMute() {
        if (sink) sink.audio.muted = !sink.audio.muted
    }

    function toggleMicMute() {
        if (source) source.audio.muted = !source.audio.muted
    }

    function incrementVolume() {
        if (!sink) return
        const step = value < 0.1 ? 0.01 : 0.02
        sink.audio.volume = Math.min(1, sink.audio.volume + step)
    }

    function decrementVolume() {
        if (!sink) return
        const step = value < 0.1 ? 0.01 : 0.02
        sink.audio.volume = Math.max(0, sink.audio.volume - step)
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node
    }

    // Track objects
    PwObjectTracker {
        objects: [sink, source]
    }

    // Volume protection
    Connections {
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!Config.options.audio.protection.enable) return
            const newVolume = sink.audio.volume
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false
                lastVolume = 0
                return
            }
            if (!lastReady) {
                lastVolume = newVolume
                lastReady = true
                return
            }
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100
            const maxAllowed = Config.options.audio.protection.maxAllowed / 100
            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume
                root.sinkProtectionTriggered("Sudden volume jump blocked")
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered("Exceeded max allowed volume")
                sink.audio.volume = Math.min(lastVolume, maxAllowed)
            }
            lastVolume = sink.audio.volume
        }
    }

    // System sound playback
    function playSystemSound(soundName) {
        const theme = Config.options.sounds.theme
        const ogaPath = `/usr/share/sounds/${theme}/stereo/${soundName}.oga`
        const oggPath = `/usr/share/sounds/${theme}/stereo/${soundName}.ogg`
        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", ogaPath])
        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", oggPath])
    }

    // IPC
    IpcHandler {
        target: "audio"
        function toggleMute(): void { root.toggleMute() }
        function toggleMicMute(): void { root.toggleMicMute() }
        function increment(): void { root.incrementVolume() }
        function decrement(): void { root.decrementVolume() }
    }

    GlobalShortcut {
        name: "volumeUp"
        description: "Increase volume"
        onPressed: root.incrementVolume()
    }
    GlobalShortcut {
        name: "volumeDown"
        description: "Decrease volume"
        onPressed: root.decrementVolume()
    }
    GlobalShortcut {
        name: "volumeMute"
        description: "Toggle mute"
        onPressed: root.toggleMute()
    }
}

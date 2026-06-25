pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Audio spectrum service using cava. Reference-counted — only runs
 * when at least one visualizer component is registered.
 * Feeds stdin config to cava, parses raw ASCII output into values array.
 * Double-buffered to avoid GC pressure. Idle detection stops GPU updates
 * when no audio is playing.
 *
 * Ported from noctalia-shell SpectrumService with enhancements.
 */
Singleton {
    id: root

    // Register/unregister components that need audio data
    property var registeredComponents: ({})
    readonly property int registeredCount: Object.keys(registeredComponents).length
    property bool shouldRun: registeredCount > 0

    function registerComponent(componentId) {
        root.registeredComponents[componentId] = true
        root.registeredComponents = Object.assign({}, root.registeredComponents)
    }

    function unregisterComponent(componentId) {
        delete root.registeredComponents[componentId]
        root.registeredComponents = Object.assign({}, root.registeredComponents)
    }

    function isRegistered(componentId) {
        return root.registeredComponents[componentId] === true
    }

    // Output
    property var values: []
    property int barsCount: Config.options?.audio?.spectrum?.bars ?? 32
    property int frameRate: Config.options?.audio?.spectrum?.frameRate ?? 60

    // Idle detection
    property bool isIdle: true
    property int idleFrameCount: 0
    readonly property int idleThreshold: 30

    // Crash tracking
    property int _crashCount: 0
    readonly property int _maxCrashes: 5

    // Double buffer to avoid per-frame GC
    property var _buf0: new Array(barsCount).fill(0)
    property var _buf1: new Array(barsCount).fill(0)
    property bool _bufToggle: false

    // Cava config sent via stdin
    property var config: ({
        "general": {
            "bars": barsCount,
            "framerate": frameRate,
            "autosens": 1,
            "sensitivity": 100,
            "lower_cutoff_freq": 50,
            "higher_cutoff_freq": 12000
        },
        "smoothing": {
            "monstercat": 1,
            "noise_reduction": 77
        },
        "output": {
            "method": "raw",
            "data_format": "ascii",
            "ascii_max_range": 100,
            "bit_format": "8bit",
            "channels": "mono",
            "mono_option": "average"
        }
    })

    onShouldRunChanged: {
        if (shouldRun && !cavaProcess.running) cavaProcess.running = true
        else if (!shouldRun && cavaProcess.running) cavaProcess.running = false
    }

    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: {
            if (root.shouldRun && !cavaProcess.running) cavaProcess.running = true
        }
    }

    Process {
        id: cavaProcess
        stdinEnabled: true
        command: ["cava", "-p", "/dev/stdin"]

        onExited: {
            stdinEnabled = true
            root.values = Array(root.barsCount).fill(0)
            if (root.shouldRun) {
                root._crashCount++
                if (root._crashCount <= root._maxCrashes) restartTimer.start()
            } else {
                root._crashCount = 0
            }
        }

        onStarted: {
            // Write config to cava stdin
            for (const section in root.config) {
                const obj = root.config[section]
                if (typeof obj !== "object") { write(`${section}=${obj}\n`); continue }
                write(`[${section}]\n`)
                for (const key in obj) write(`${key}=${obj[key]}\n`)
            }
            stdinEnabled = false
            root.values = Array(root.barsCount).fill(0)
            root._crashCount = 0
        }

        stdout: SplitParser {
            onRead: data => {
                const buffer = root._bufToggle ? root._buf0 : root._buf1
                let idx = 0, num = 0, allZero = true

                for (let i = 0, len = data.length - 1; i < len; i++) {
                    const c = data.charCodeAt(i)
                    if (c === 59) { // semicolon
                        const val = num * 0.01
                        buffer[idx++] = val
                        if (val >= 0.01) allZero = false
                        num = 0
                    } else if (c >= 48 && c <= 57) { // digit
                        num = num * 10 + (c - 48)
                    }
                }
                if (num > 0 || idx < root.barsCount) {
                    const val = num * 0.01
                    buffer[idx++] = val
                    if (val >= 0.01) allZero = false
                }

                if (allZero) {
                    root.idleFrameCount++
                    if (root.idleFrameCount >= root.idleThreshold) {
                        if (!root.isIdle) {
                            root.isIdle = true
                            root.values = Array(root.barsCount).fill(0)
                        }
                        return
                    }
                } else {
                    root.idleFrameCount = 0
                    if (root.isIdle) root.isIdle = false
                }

                if (!root.isIdle) {
                    root._bufToggle = !root._bufToggle
                    root.values = buffer
                }
            }
        }
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.services
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

/**
 * Brightness service. Supports brightnessctl (backlight) and ddcutil (DDC/CI for external monitors).
 * Compositor-agnostic — uses CompositorService for focused monitor detection.
 */
Singleton {
    id: root
    signal brightnessChanged()

    property var ddcMonitors: []
    readonly property list<BrightnessMonitor> monitors: Quickshell.screens.map(screen => monitorComp.createObject(root, { screen }))

    function getMonitorForScreen(screen): var {
        return monitors.find(m => m.screen === screen)
    }

    function increaseBrightness(): void {
        const focusedName = CompositorService.focusedMonitorName
        const monitor = monitors.find(m => focusedName === m.screen.name)
        if (monitor) monitor.setBrightness(monitor.brightness + 0.05)
    }

    function decreaseBrightness(): void {
        const focusedName = CompositorService.focusedMonitorName
        const monitor = monitors.find(m => focusedName === m.screen.name)
        if (monitor) monitor.setBrightness(monitor.brightness - 0.05)
    }

    reloadableId: "brightness"

    onMonitorsChanged: {
        ddcMonitors = []
        ddcProc.running = true
    }

    function initializeMonitor(i): void {
        if (i >= monitors.length) return
        monitors[i].initialize()
    }

    function ddcDetectFinished(): void {
        initializeMonitor(0)
    }

    Process {
        id: ddcProc
        command: ["ddcutil", "detect", "--brief"]
        stdout: SplitParser {
            splitMarker: "\n\n"
            onRead: data => {
                if (data.startsWith("Display ")) {
                    const lines = data.split("\n").map(l => l.trim())
                    const connLine = lines.find(l => l.startsWith("DRM connector:"))
                    const busLine = lines.find(l => l.startsWith("I2C bus:"))
                    if (connLine && busLine) {
                        root.ddcMonitors.push({
                            name: connLine.split("-").slice(1).join('-'),
                            busNum: busLine.split("/dev/i2c-")[1]
                        })
                    }
                }
            }
        }
        onExited: root.ddcDetectFinished()
    }

    Process {
        id: setProc
    }

    component BrightnessMonitor: QtObject {
        id: monitor
        required property var screen
        property bool isDdc
        property string busNum
        property int rawMaxBrightness: 100
        property real brightness
        property bool ready: false
        property bool animateChanges: !monitor.isDdc

        // Single onBrightnessChanged handler — fans out to both the
        // root-level signal (for UI consumers) and the debounced
        // setTimer (which actually pushes the value to the device).
        onBrightnessChanged: {
            if (!monitor.ready) return
            root.brightnessChanged()
            setTimer.restart()
        }

        function initialize() {
            monitor.ready = false
            const match = root.ddcMonitors.find(m => m.name === screen.name && !root.monitors.slice(0, root.monitors.indexOf(this)).some(mon => mon.busNum === m.busNum))
            isDdc = !!match
            busNum = match?.busNum ?? ""
            const device = Config.options.light.device
            const deviceFlag = device ? `-d '${device}'` : ""
            initProc.command = isDdc
                ? ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"]
                : ["sh", "-c", `echo "a b c $(brightnessctl ${deviceFlag} g) $(brightnessctl ${deviceFlag} m)"`]
            initProc.running = true
        }

        readonly property Process initProc: Process {
            stdout: SplitParser {
                onRead: data => {
                    const parts = data.split(" ")
                    monitor.rawMaxBrightness = parseInt(parts[4] || "100")
                    monitor.brightness = parseInt(parts[3] || "0") / monitor.rawMaxBrightness
                    monitor.ready = true
                }
            }
            onExited: (exitCode, exitStatus) => {
                initializeMonitor(root.monitors.indexOf(monitor) + 1)
            }
        }

        property var setTimer: Timer {
            interval: monitor.isDdc ? 300 : 0
            onTriggered: syncBrightness()
        }

        function syncBrightness() {
            const brightnessValue = Math.max(brightness, 0)
            if (isDdc) {
                const rawValueRounded = Math.max(Math.floor(brightnessValue * monitor.rawMaxBrightness), 1)
                setProc.exec(["ddcutil", "-b", busNum, "setvcp", "10", rawValueRounded])
            } else {
                const valuePercentNumber = Math.floor(brightnessValue * 100)
                let valuePercent = `${valuePercentNumber}%`
                if (valuePercentNumber === 0) valuePercent = "1"
                const device = Config.options.light.device
                const cmd = ["brightnessctl"]
                if (device) {
                    cmd.push("-d", device)
                } else {
                    cmd.push("--class", "backlight")
                }
                cmd.push("s", valuePercent, "--quiet")
                setProc.exec(cmd)
            }
        }

        function setBrightness(value): void {
            monitor.brightness = Math.max(0, Math.min(1, value))
        }
    }

    Component {
        id: monitorComp
        BrightnessMonitor {}
    }

    // IPC
    IpcHandler {
        target: "brightness"
        function increment(): void { root.increaseBrightness() }
        function decrement(): void { root.decreaseBrightness() }
    }

    GlobalShortcut {
        name: "brightnessIncrease"
        description: "Increase brightness"
        onPressed: root.increaseBrightness()
    }
    GlobalShortcut {
        name: "brightnessDecrease"
        description: "Decrease brightness"
        onPressed: root.decreaseBrightness()
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common
import qs.services

/**
 * Keyboard layout service. Works on both Hyprland and Niri.
 * Exposes active XKB layout name and code for indicators.
 * On Hyprland: listens to activelayout events.
 * On Niri: polls from NiriService keyboard layout tracking.
 */
Singleton {
    id: root
    property list<string> layoutCodes: []
    property var cachedLayoutCodes: ({})
    property string currentLayoutName: ""
    property string currentLayoutCode: ""
    property string baseLayoutFilePath: "/usr/share/X11/xkb/rules/base.lst"
    property bool needsLayoutRefresh: false

    onCurrentLayoutNameChanged: root.updateLayoutCode()

    function updateLayoutCode() {
        if (cachedLayoutCodes.hasOwnProperty(currentLayoutName)) {
            root.currentLayoutCode = cachedLayoutCodes[currentLayoutName]
        } else {
            getLayoutProc.running = true
        }
    }

    Process {
        id: getLayoutProc
        command: ["cat", root.baseLayoutFilePath]
        stdout: StdioCollector {
            id: layoutCollector
            onStreamFinished: {
                const lines = layoutCollector.text.split("\n")
                const targetDescription = root.currentLayoutName
                lines.find(line => {
                    if (!line.trim() || line.trim().startsWith('!')) return false

                    const matchLayout = line.match(/^\s*(\S+)\s+(.+)$/)
                    if (matchLayout && matchLayout[2] === targetDescription) {
                        root.cachedLayoutCodes[matchLayout[2]] = matchLayout[1]
                        root.currentLayoutCode = matchLayout[1]
                        return true
                    }

                    const matchVariant = line.match(/^\s*(\S+)\s+(\S+)\s+(.+)$/)
                    if (matchVariant && matchVariant[3] === targetDescription) {
                        const complexLayout = matchVariant[2] + matchVariant[1]
                        root.cachedLayoutCodes[matchVariant[3]] = complexLayout
                        root.currentLayoutCode = complexLayout
                        return true
                    }
                    return false
                })
            }
        }
    }

    // Hyprland: fetch layout info from hyprctl devices
    Process {
        id: fetchLayoutsProc
        running: CompositorService.compositor === "hyprland"
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            id: devicesCollector
            onStreamFinished: {
                const parsedOutput = JSON.parse(devicesCollector.text)
                const hyprlandKeyboard = parsedOutput["keyboards"].find(kb => kb.main === true)
                if (hyprlandKeyboard) {
                    root.layoutCodes = hyprlandKeyboard["layout"].split(",")
                    root.currentLayoutName = hyprlandKeyboard["active_keymap"]
                }
            }
        }
    }

    // Hyprland: listen for layout changes
    Connections {
        enabled: CompositorService.compositor === "hyprland"
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                if (root.needsLayoutRefresh) {
                    root.needsLayoutRefresh = false
                    fetchLayoutsProc.running = true
                }
                if (root.layoutCodes.length <= 1) return
                const dataString = event.data
                root.currentLayoutName = dataString.substring(dataString.indexOf(",") + 1)
                Config.options.osk.layout = root.currentLayoutName.split(" (")[0]
            } else if (event.name === "configreloaded") {
                root.needsLayoutRefresh = true
            }
        }
    }

    // Niri: subscribe to the NiriService.layoutChanged(string) signal.
    // Previous version referenced a non-existent keyboardLayoutChanged.
    Connections {
        enabled: CompositorService.compositor === "niri"
        target: NiriService
        function onLayoutChanged(layout) {
            root.currentLayoutName = layout
        }
    }

    // Initialize for Niri
    Component.onCompleted: {
        if (CompositorService.compositor === "niri" && NiriService.keyboardLayout) {
            root.currentLayoutName = NiriService.keyboardLayout
        }
    }
}

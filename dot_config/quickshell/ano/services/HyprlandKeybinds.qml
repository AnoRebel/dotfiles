pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Hyprland keybind parser service. Reads keybind config files using
 * the get_keybinds.py script for the cheatsheet module.
 * Only active on Hyprland.
 */
Singleton {
    id: root
    property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/hyprland/get_keybinds.py`)
    property string defaultKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/Ano/hyprland/keybinds.conf`)
    property string userKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/Ano/custom/keybinds.conf`)
    property var defaultKeybinds: { "children": [] }
    property var userKeybinds: { "children": [] }
    property var keybinds: ({
        children: [
            ...(defaultKeybinds.children ?? []),
            ...(userKeybinds.children ?? []),
        ]
    })

    Connections {
        enabled: CompositorService.compositor === "hyprland"
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                getDefaultKeybinds.running = true
                getUserKeybinds.running = true
            }
        }
    }

    Process {
        id: getDefaultKeybinds
        running: CompositorService.compositor === "hyprland"
        command: [root.keybindParserPath, "--path", root.defaultKeybindConfigPath]
        stdout: SplitParser {
            onRead: data => {
                try { root.defaultKeybinds = JSON.parse(data) }
                catch (e) { console.error("[HyprlandKeybinds] Error parsing defaults:", e) }
            }
        }
    }

    Process {
        id: getUserKeybinds
        running: CompositorService.compositor === "hyprland"
        command: [root.keybindParserPath, "--path", root.userKeybindConfigPath]
        stdout: SplitParser {
            onRead: data => {
                try { root.userKeybinds = JSON.parse(data) }
                catch (e) { console.error("[HyprlandKeybinds] Error parsing user keybinds:", e) }
            }
        }
    }
}

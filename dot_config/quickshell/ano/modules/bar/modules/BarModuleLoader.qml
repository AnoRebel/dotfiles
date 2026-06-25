pragma Singleton
import QtQuick

/**
 * Maps module name strings to QML components.
 * This is used by BarContent to dynamically load modules based on config.
 */
QtObject {
    id: root

    // Canonical list of valid module IDs the bar can render. The Settings
    // bar editor uses this to render "available chip" rows and to validate
    // that user-edited config doesn't carry typos. Order is the suggested
    // default ordering for new bars.
    readonly property var availableModuleIds: [
        "sidebarButton",
        "activeWindow",
        "workspaces",
        "clock",
        "weather",
        "battery",
        "network",
        "bluetooth",
        "tray",
        "media",
        "resources",
        "keyboard",
        "notifications",
        "idle",
        "privacy",
        "gamemode"
    ]

    // Human-readable labels for the UI. Falls back to the raw ID when
    // missing so a future module added to availableModuleIds without
    // a label still renders a chip.
    readonly property var moduleLabels: ({
        "clock": "Clock",
        "workspaces": "Workspaces",
        "battery": "Battery",
        "network": "Network",
        "bluetooth": "Bluetooth",
        "tray": "System tray",
        "media": "Media",
        "resources": "Resources",
        "activeWindow": "Active window",
        "sidebarButton": "Sidebar button",
        "weather": "Weather",
        "keyboard": "Keyboard layout",
        "notifications": "Notifications",
        "idle": "Idle inhibit",
        "privacy": "Privacy",
        "gamemode": "Game mode"
    })

    function isKnownModule(name) {
        return availableModuleIds.indexOf(name) !== -1 || name === "keyboardLayout"
    }

    function labelFor(name) {
        // Normalise the keyboardLayout alias for display
        const id = (name === "keyboardLayout") ? "keyboard" : name
        return moduleLabels[id] || id
    }

    function getModule(name) {
        switch (name) {
            case "clock": return clockModule
            case "workspaces": return workspacesModule
            case "battery": return batteryModule
            case "network": return networkModule
            case "bluetooth": return bluetoothModule
            case "tray": return trayModule
            case "media": return mediaModule
            case "resources": return resourcesModule
            case "activeWindow": return activeWindowModule
            case "sidebarButton": return sidebarButtonModule
            case "weather": return weatherModule
            case "keyboard": return keyboardModule
            case "keyboardLayout": return keyboardModule  // alias — same module, both IDs accepted
            case "notifications": return notificationsModule
            case "idle": return idleModule
            case "privacy": return privacyModule
            case "gamemode": return gameModeModule
            default:
                console.warn(`[BarModuleLoader] Unknown module: ${name}`)
                return null
        }
    }

    property Component clockModule: Component { ClockModule {} }
    property Component workspacesModule: Component { WorkspacesModule {} }
    property Component batteryModule: Component { BatteryModule {} }
    property Component networkModule: Component { NetworkModule {} }
    property Component bluetoothModule: Component { BluetoothModule {} }
    property Component trayModule: Component { TrayModule {} }
    property Component mediaModule: Component { MediaModule {} }
    property Component resourcesModule: Component { ResourcesModule {} }
    property Component activeWindowModule: Component { ActiveWindowModule {} }
    property Component sidebarButtonModule: Component { SidebarButtonModule {} }
    property Component weatherModule: Component { WeatherModule {} }
    property Component keyboardModule: Component { KeyboardModule {} }
    property Component notificationsModule: Component { NotificationsModule {} }
    property Component idleModule: Component { IdleModule {} }
    property Component privacyModule: Component { PrivacyModule {} }
    property Component gameModeModule: Component { GameModeModule {} }
}

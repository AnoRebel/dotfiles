import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * Sidebar configuration — elaborate with widget enable/disable,
 * behavior tuning, and preview indicators.
 */
ColumnLayout {
    spacing: 16

    SettingsPageHeader {
        title: "Sidebars"
        subtitle: "Behavior, widget toggles, sliders"
        configRoots: ["sidebar"]
    }

    // ═══ Sidebar Behavior ═══
    SettingsCard {
        icon: "speed"
        title: "Sidebar Behavior"
        subtitle: "Animation, loading, and dismissal settings"
        configKeys: ["sidebar.instantOpen", "sidebar.keepLeftSidebarLoaded", "sidebar.keepRightSidebarLoaded"]

        ConfigSwitch {
            label: "Instant open (skip animation)"
            sublabel: "Sidebars appear immediately without slide-in transition"
            checked: Config.options?.sidebar?.instantOpen ?? false
            onCheckedChanged: Config.setNestedValue("sidebar.instantOpen", checked)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ConfigSwitch {
                Layout.fillWidth: true
                label: "Keep left sidebar loaded"
                sublabel: "Faster re-open at the cost of ~20MB memory"
                checked: Config.options?.sidebar?.keepLeftSidebarLoaded ?? true
                onCheckedChanged: Config.setNestedValue("sidebar.keepLeftSidebarLoaded", checked)
            }
            RestartRequiredBadge {}
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ConfigSwitch {
                Layout.fillWidth: true
                label: "Keep right sidebar loaded"
                sublabel: "Faster re-open at the cost of ~15MB memory"
                checked: Config.options?.sidebar?.keepRightSidebarLoaded ?? true
                onCheckedChanged: Config.setNestedValue("sidebar.keepRightSidebarLoaded", checked)
            }
            RestartRequiredBadge {}
        }
    }

    // ═══ Left Sidebar ═══
    SettingsCard {
        icon: "view_sidebar"
        title: "Left Sidebar"
        subtitle: "AI Chat and Notifications panel"
        configKeys: ["sidebar.left"]

        NoticeBox {
            text: "The left sidebar contains two tabs: AI Chat and Notifications with a compact media player. AI model configuration is in the Services page."
            iconName: "info"
        }
    }

    // ═══ Right Sidebar Widgets ═══
    SettingsCard {
        id: rightWidgetsCard
        icon: "widgets"
        title: "Right Sidebar Widgets"
        subtitle: "Choose which modules appear in the right sidebar"
        configKeys: ["sidebar.right"]

        readonly property var _enabled: Config.options?.sidebar?.right?.enabledWidgets ?? [
            "systemButtons", "quickSliders", "quickToggles", "media", "notifications", "calendar", "systemInfo"
        ]

        NoticeBox {
            visible: rightWidgetsCard._enabled.length === 0
            iconName: "warning"
            text: "Right sidebar is empty — re-enable at least one widget below or it won't render anything."
        }

        // Widget toggles
        Repeater {
            model: [
                { key: "systemButtons", label: "System Buttons", sublabel: "Uptime, reload, settings, power", icon: "power_settings_new" },
                { key: "quickSliders", label: "Quick Sliders", sublabel: "Volume, brightness, microphone", icon: "tune" },
                { key: "quickToggles", label: "Quick Toggles", sublabel: "WiFi, Bluetooth, DND, Idle inhibit", icon: "toggle_on" },
                { key: "media", label: "Media Player", sublabel: "Compact media controls with vinyl art", icon: "music_note" },
                { key: "notifications", label: "Notifications", sublabel: "Recent notification list", icon: "notifications" },
                { key: "calendar", label: "Calendar", sublabel: "Month calendar grid", icon: "calendar_month" },
                { key: "systemInfo", label: "System Info", sublabel: "CPU/RAM/battery gauges + network speed", icon: "monitor_heart" },
            ]

            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 12

                MaterialSymbol {
                    text: modelData.icon; iconSize: 20
                    color: Appearance?.colors.colPrimary ?? "#65558F"
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    StyledText { text: modelData.label; font.pixelSize: Appearance?.font.pixelSize.small ?? 14 }
                    StyledText { text: modelData.sublabel; font.pixelSize: Appearance?.font.pixelSize.smallest ?? 11; opacity: 0.4 }
                }
                StyledSwitch {
                    checked: (Config.options?.sidebar?.right?.enabledWidgets ?? [
                        "systemButtons", "quickSliders", "quickToggles", "media", "notifications", "calendar", "systemInfo"
                    ]).includes(modelData.key)
                    // onToggled (user-driven only) — bind-time mutations
                    // never fire it, so the array can't be corrupted by
                    // initial-bind cascades like ModulesConfig had.
                    onToggled: {
                        const widgets = Config.options?.sidebar?.right?.enabledWidgets ?? [
                            "systemButtons", "quickSliders", "quickToggles", "media", "notifications", "calendar", "systemInfo"
                        ]
                        if (checked && !widgets.includes(modelData.key)) {
                            Config.setNestedValue("sidebar.right.enabledWidgets", [...widgets, modelData.key])
                        } else if (!checked && widgets.includes(modelData.key)) {
                            Config.setNestedValue("sidebar.right.enabledWidgets", widgets.filter(w => w !== modelData.key))
                        }
                    }
                }
            }
        }
    }

    // ═══ Quick Sliders ═══
    SettingsCard {
        icon: "tune"
        title: "Quick Sliders"
        configKeys: ["sidebar.quickSliders"]
        // Sub-toggles only matter when the parent "Quick Sliders" widget
        // is enabled. Disable them visually rather than hide so the page
        // doesn't reflow when the parent toggle flips.
        readonly property bool _parentEnabled: rightWidgetsCard._enabled.includes("quickSliders")
        subtitle: _parentEnabled
            ? "Configure which sliders appear in the right sidebar"
            : "Enable the Quick Sliders widget above to use these"
        enabled: _parentEnabled

        ConfigSwitch {
            label: "Show brightness slider"
            checked: Config.options?.sidebar?.quickSliders?.showBrightness ?? true
            onCheckedChanged: Config.setNestedValue("sidebar.quickSliders.showBrightness", checked)
        }

        ConfigSwitch {
            label: "Show volume slider"
            checked: Config.options?.sidebar?.quickSliders?.showVolume ?? true
            onCheckedChanged: Config.setNestedValue("sidebar.quickSliders.showVolume", checked)
        }

        ConfigSwitch {
            label: "Show microphone slider"
            sublabel: "Additional slider for microphone input volume"
            checked: Config.options?.sidebar?.quickSliders?.showMic ?? false
            onCheckedChanged: Config.setNestedValue("sidebar.quickSliders.showMic", checked)
        }
    }
}

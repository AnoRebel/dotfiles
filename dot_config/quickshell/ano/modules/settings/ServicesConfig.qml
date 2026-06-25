import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import "."

/**
 * Services settings — elaborate AI model configuration, weather service,
 * resource monitor, brightness device, and clipboard config.
 */
ColumnLayout {
    spacing: 16

    SettingsPageHeader {
        title: "Services"
        subtitle: "AI, GameMode, PowerProfiles, Network, VPN, NightLight, Lyrics, Calendar, Resources, Brightness, Weather"
        configRoots: [
            "ai", "gameMode", "powerProfiles", "network", "vpn",
            "nightLight", "lyrics", "calendar", "resources", "light",
            "shell", "weather"
        ]
    }

    // ═══ AI Chat ═══
    SettingsCard {
        icon: "neurology"
        title: "AI Chat"
        subtitle: "Model configuration, API keys, system prompt, and temperature"
        configKeys: ["ai"]

        // Model status indicator
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: modelStatusRow.implicitHeight + 16
            radius: Appearance?.rounding.small ?? 8
            color: Appearance?.colors.colLayer2 ?? "#2B2930"

            RowLayout {
                id: modelStatusRow
                anchors { fill: parent; margins: 8 }
                spacing: 12

                MaterialSymbol {
                    text: Ai.currentModelHasApiKey ? "check_circle" : "error"
                    iconSize: 24; fill: 1
                    color: Ai.currentModelHasApiKey ? "#81C784" : Appearance?.m3colors.m3error ?? "#BA1A1A"
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 1
                    StyledText {
                        text: Ai.getModel()?.name ?? "No model selected"
                        font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        text: Ai.currentModelHasApiKey ? "API key configured" : "API key missing — use /key in chat"
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        color: Ai.currentModelHasApiKey ? "#81C784" : Appearance?.m3colors.m3error ?? "#BA1A1A"
                    }
                }
                ColumnLayout {
                    spacing: 1
                    StyledText { text: "Tokens"; font.pixelSize: 10; opacity: 0.4; Layout.alignment: Qt.AlignHCenter }
                    StyledText {
                        text: Ai.tokenCount.total > 0 ? `${Ai.tokenCount.total}` : "—"
                        font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                        font.family: Appearance?.font.family.numbers ?? "monospace"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        ConfigRow {
            label: "Default model ID"
            sublabel: "One of: " + Ai.modelList.join(", ")
            StyledTextInput {
                text: Config.options?.ai?.defaultModel ?? ""
                onEditingFinished: Config.setNestedValue("ai.defaultModel", text)
                Layout.preferredWidth: 200
                font.family: Appearance?.font.family.mono ?? "monospace"
            }
        }

        // Available models list
        ColumnLayout {
            spacing: 4
            StyledText { text: "Available models"; font.weight: Font.DemiBold; font.pixelSize: Appearance?.font.pixelSize.small ?? 14 }

            Repeater {
                model: Ai.modelList

                Rectangle {
                    required property string modelData
                    Layout.fillWidth: true
                    implicitHeight: modelRow.implicitHeight + 12
                    radius: 8
                    color: Ai.currentModelId === modelData
                        ? Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.15)
                        : "transparent"
                    border.width: Ai.currentModelId === modelData ? 1 : 0
                    border.color: Appearance?.colors.colPrimary ?? "#65558F"

                    RowLayout {
                        id: modelRow
                        anchors { fill: parent; margins: 6 }
                        spacing: 8
                        MaterialSymbol {
                            text: "neurology"; iconSize: 18
                            color: Ai.currentModelId === modelData ? Appearance?.colors.colPrimary ?? "#65558F" : Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            StyledText {
                                text: Ai.models[modelData]?.name ?? modelData
                                font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                                font.weight: Font.DemiBold
                            }
                            StyledText {
                                readonly property bool _hasKey: (Ai.apiKeys[Ai.models[modelData]?.key_id]?.length ?? 0) > 0
                                // Append textual marker when key is missing —
                                // colour-only indication is not enough.
                                text: {
                                    const base = `${Ai.models[modelData]?.api_format ?? "?"} • ${Ai.models[modelData]?.description ?? ""}`
                                    return _hasKey ? base : `${base} · Missing key`
                                }
                                font.pixelSize: Appearance?.font.pixelSize.smallest ?? 11
                                opacity: 0.5; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                        // API key status
                        MaterialSymbol {
                            text: Ai.apiKeys[Ai.models[modelData]?.key_id]?.length > 0 ? "key" : "key_off"
                            iconSize: 16
                            color: Ai.apiKeys[Ai.models[modelData]?.key_id]?.length > 0 ? "#81C784" : Appearance?.colors.colSubtext ?? "#888"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { Ai.setModel(modelData) }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.2 }

        ConfigSlider {
            label: "Temperature"
            sublabel: "Creativity/randomness: 0 = deterministic, 2 = very creative"
            from: 0; to: 2; stepSize: 0.1
            value: Config.options?.ai?.temperature ?? 0.5
            onValueChanged: Config.setNestedValue("ai.temperature", value)
            valueText: `${value.toFixed(1)}`
        }

        ColumnLayout {
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                StyledText { text: "System prompt"; font.weight: Font.DemiBold; font.pixelSize: Appearance?.font.pixelSize.small ?? 14; Layout.fillWidth: true }
                StyledText {
                    text: `${promptArea.text.length} chars`
                    font.pixelSize: Appearance?.font.pixelSize.smallest ?? 11
                    opacity: 0.55
                }
            }
            StyledTextArea {
                id: promptArea
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                text: Config.options?.ai?.systemPrompt ?? "You are a helpful assistant integrated into a Linux desktop shell called Ano."
                onEditingFinished: Config.setNestedValue("ai.systemPrompt", text)
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
            }
        }

        NoticeBox {
            text: "API keys are managed via the /key command in the AI chat sidebar and stored securely in api_keys.json. Supported providers: OpenAI, Google Gemini, Anthropic Claude."
            iconName: "security"
        }
    }

    // ═══ Resources Monitor ═══
    SettingsCard {
        icon: "monitor_heart"
        title: "Resources Monitor"
        subtitle: "CPU, RAM, network polling frequency and history"
        configKeys: ["resources"]

        // Live mini-dashboard
        RowLayout {
            Layout.fillWidth: true; spacing: 16
            Repeater {
                model: [
                    { label: "CPU", value: ResourceUsage.cpuUsage, text: `${Math.round(ResourceUsage.cpuUsage * 100)}%` },
                    { label: "RAM", value: ResourceUsage.memoryUsedPercentage, text: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed) },
                ]
                ColumnLayout {
                    required property var modelData
                    spacing: 4; Layout.fillWidth: true
                    CircularProgress { implicitSize: 36; lineWidth: 3; value: modelData.value; Layout.alignment: Qt.AlignHCenter }
                    StyledText { text: modelData.text; font.pixelSize: 11; font.family: Appearance?.font.family.mono; Layout.alignment: Qt.AlignHCenter }
                    StyledText { text: modelData.label; font.pixelSize: 10; opacity: 0.4; Layout.alignment: Qt.AlignHCenter }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.2 }

        ConfigSlider {
            label: "Update interval"
            sublabel: "How often /proc is polled for CPU/RAM/network data"
            from: 500; to: 10000; stepSize: 500
            value: Config.options?.resources?.updateInterval ?? 3000
            onValueChanged: Config.setNestedValue("resources.updateInterval", Math.round(value))
            valueText: Format.formatDuration(value)
        }

        ConfigSlider {
            label: "History length"
            sublabel: "Number of data points stored for graph display"
            from: 10; to: 180; stepSize: 10
            value: Config.options?.resources?.historyLength ?? 60
            onValueChanged: Config.setNestedValue("resources.historyLength", Math.round(value))
            valueText: `${Math.round(value)} pts`
        }
    }

    // ═══ Brightness Device ═══
    SettingsCard {
        icon: "brightness_6"
        title: "Brightness"
        subtitle: "Backlight device override"
        configKeys: ["light"]

        ConfigRow {
            label: "Device name"
            sublabel: "Leave empty for auto-detect. Use 'brightnessctl -l' to list devices."
            StyledTextInput {
                text: Config.options?.light?.device ?? ""
                onEditingFinished: Config.setNestedValue("light.device", text)
                Layout.preferredWidth: 200
                font.family: Appearance?.font.family.mono ?? "monospace"
            }
        }
    }

    // ═══ GameMode ═══
    SettingsCard {
        icon: "videogame_asset"
        title: "GameMode"
        subtitle: "Detects when gamemoded is active so the bar can show a 'gaming' indicator. Read-only — activation is handled by your existing ~/.config/hypr/scripts/gamemode helper or by libgamemode-aware games."
        configKeys: ["gameMode"]

        ConfigSwitch {
            id: gmEnable
            label: "Enable detection"
            checked: Config.options?.gameMode?.enable ?? false
            onCheckedChanged: Config.setNestedValue("gameMode.enable", checked)
        }

        ConfigSlider {
            label: "Poll interval"
            sublabel: "How often `gamemoded -s` is checked"
            from: 500; to: 10000; stepSize: 500
            enabled: gmEnable.checked
            value: Config.options?.gameMode?.pollIntervalMs ?? 2000
            onValueChanged: Config.setNestedValue("gameMode.pollIntervalMs", Math.round(value))
            valueText: Format.formatDuration(value)
        }

        ConfigRow {
            label: "Status"
            sublabel: gmEnable.checked
                ? (GameMode.active ? `Active · ${GameMode.clientCount} client(s)` : "Inactive")
                : "Detection disabled"
            StyledText {
                text: gmEnable.checked && GameMode.active ? "●" : "○"
                color: gmEnable.checked && GameMode.active
                    ? (Appearance?.colors.colPrimary ?? "#a6e3a1")
                    : Qt.rgba(1, 1, 1, 0.3)
                font.pixelSize: 18
            }
        }
    }

    // ═══ Power Profiles ═══
    SettingsCard {
        icon: "battery_saver"
        title: "Power profiles"
        subtitle: "Restores the last-active power-profiles-daemon profile on shell start. Requires `power-profiles-daemon`."
        configKeys: ["powerProfiles"]

        ConfigSwitch {
            label: "Restore on start"
            sublabel: "When off, power-profiles-daemon decides at boot"
            checked: Config.options?.powerProfiles?.restoreOnStart ?? true
            onCheckedChanged: Config.setNestedValue("powerProfiles.restoreOnStart", checked)
        }

        ConfigRow {
            label: "Active profile"
            sublabel: "Persists across reboots when restore-on-start is on"

            RowLayout {
                spacing: 4

                Repeater {
                    model: ({
                        // Filter performance out when the daemon doesn't expose it
                        list: PowerProfiles.hasPerformanceProfile
                            ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                            : [PowerProfile.PowerSaver, PowerProfile.Balanced]
                    }).list

                    RippleButton {
                        required property int modelData
                        readonly property string label: modelData === PowerProfile.PowerSaver
                            ? "Power saver"
                            : modelData === PowerProfile.Balanced
                                ? "Balanced"
                                : "Performance"
                        readonly property string symbol: modelData === PowerProfile.PowerSaver
                            ? "battery_saver"
                            : modelData === PowerProfile.Balanced
                                ? "balance"
                                : "rocket_launch"
                        implicitHeight: 28
                        buttonRadius: 8
                        toggled: PowerProfiles.profile === modelData
                        colBackgroundToggled: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
                        contentItem: RowLayout {
                            spacing: 4
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            MaterialSymbol { text: symbol; iconSize: 14 }
                            StyledText { text: label; font.pixelSize: 12 }
                        }
                        onClicked: PowerProfiles.profile = modelData
                    }
                }
            }
        }
    }

    // ═══ Night Light ═══
    SettingsCard {
        icon: "nightlight"
        title: "Night light"
        subtitle: "Warm-shifts the display via wlsunset. Works on any wlroots compositor (Hyprland, Niri, sway)."
        configKeys: ["nightLight"]

        ConfigSwitch {
            id: nlEnable
            label: "Enable"
            checked: Config.options?.nightLight?.enable ?? false
            onCheckedChanged: Config.setNestedValue("nightLight.enable", checked)
        }

        ConfigRow {
            label: "Mode"
            sublabel: "Manual holds a fixed temperature; schedule transitions at sunrise/sunset"
            enabled: nlEnable.checked
            RowLayout {
                spacing: 4
                Repeater {
                    model: ["manual", "schedule"]
                    RippleButton {
                        required property string modelData
                        implicitHeight: 28
                        buttonRadius: 8
                        toggled: (Config.options?.nightLight?.mode ?? "manual") === modelData
                        colBackgroundToggled: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
                        contentItem: StyledText {
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            font.pixelSize: 12
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                        }
                        onClicked: Config.setNestedValue("nightLight.mode", modelData)
                    }
                }
            }
        }

        ConfigSlider {
            label: "Night temperature"
            sublabel: "Lower = warmer / more orange"
            from: 2500; to: 6500; stepSize: 100
            enabled: nlEnable.checked
            value: Config.options?.nightLight?.nightTemp ?? 4000
            onValueChanged: Config.setNestedValue("nightLight.nightTemp", Math.round(value))
            valueText: `${Math.round(value)}K`
        }

        ConfigSlider {
            label: "Day temperature"
            sublabel: "Used in schedule mode at noon"
            from: 4000; to: 6500; stepSize: 100
            enabled: nlEnable.checked && (Config.options?.nightLight?.mode ?? "manual") === "schedule"
            value: Config.options?.nightLight?.dayTemp ?? 6500
            onValueChanged: Config.setNestedValue("nightLight.dayTemp", Math.round(value))
            valueText: `${Math.round(value)}K`
        }

        ConfigSlider {
            label: "Latitude"
            from: -90; to: 90; stepSize: 0.5
            enabled: nlEnable.checked && (Config.options?.nightLight?.mode ?? "manual") === "schedule"
            value: Config.options?.nightLight?.latitude ?? 0
            onValueChanged: Config.setNestedValue("nightLight.latitude", value)
            valueText: value.toFixed(1)
        }

        ConfigSlider {
            label: "Longitude"
            from: -180; to: 180; stepSize: 0.5
            enabled: nlEnable.checked && (Config.options?.nightLight?.mode ?? "manual") === "schedule"
            value: Config.options?.nightLight?.longitude ?? 0
            onValueChanged: Config.setNestedValue("nightLight.longitude", value)
            valueText: value.toFixed(1)
        }
    }

    // ═══ Network Usage ═══
    SettingsCard {
        icon: "monitoring"
        title: "Network usage tracking"
        subtitle: "Polls /proc/net/dev for per-interface bandwidth. Powers sparkline widgets when consumed by a UI surface."
        configKeys: ["network"]

        ConfigSwitch {
            id: nuEnable
            label: "Enable"
            checked: Config.options?.network?.usage?.enable ?? false
            onCheckedChanged: Config.setNestedValue("network.usage.enable", checked)
        }

        ConfigSlider {
            label: "Poll interval"
            from: 250; to: 5000; stepSize: 250
            enabled: nuEnable.checked
            value: Config.options?.network?.usage?.intervalMs ?? 1000
            onValueChanged: Config.setNestedValue("network.usage.intervalMs", Math.round(value))
            valueText: Format.formatDuration(value)
        }

        ConfigSlider {
            label: "History length"
            sublabel: "Number of samples kept for sparkline display"
            from: 10; to: 120; stepSize: 5
            enabled: nuEnable.checked
            value: Config.options?.network?.usage?.historyLength ?? 30
            onValueChanged: Config.setNestedValue("network.usage.historyLength", Math.round(value))
            valueText: `${Math.round(value)} pts`
        }
    }

    // ═══ VPN ═══
    SettingsCard {
        icon: "vpn_key"
        title: "VPN"
        subtitle: "Connection status + control for tailscale, netbird, warp, wireguard, or a custom CLI. The active provider is the first entry below with `enabled: true`."
        configKeys: ["vpn"]

        ConfigSwitch {
            id: vpnEnable
            label: "Enable VPN service"
            sublabel: "When off, no provider CLI is queried regardless of `providers` content"
            checked: Config.options?.vpn?.enable ?? true
            onCheckedChanged: Config.setNestedValue("vpn.enable", checked)
        }

        ConfigSwitch {
            label: "Notify on state change"
            sublabel: "Reserved — surfaces can subscribe to statusChanged for their own toasts"
            enabled: vpnEnable.checked
            checked: Config.options?.vpn?.notifyOnChange ?? true
            onCheckedChanged: Config.setNestedValue("vpn.notifyOnChange", checked)
        }

        ConfigRow {
            label: "Active provider"
            sublabel: vpnEnable.checked && VPN.enabled
                ? `${VPN.providerName} · state: ${VPN.status.state}`
                : "(no provider enabled)"
            StyledText {
                text: VPN.connected ? "●" : "○"
                color: VPN.connected
                    ? (Appearance?.colors.colPrimary ?? "#a6e3a1")
                    : Qt.rgba(1, 1, 1, 0.3)
                font.pixelSize: 18
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: vpnHelp.implicitHeight + 16
            radius: Appearance?.rounding.small ?? 8
            color: Appearance?.colors.colLayer2 ?? "#3a3845"
            border.width: 1
            border.color: Appearance?.colors.colOutlineVariant ?? "#44444466"
            ColumnLayout {
                id: vpnHelp
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                StyledText {
                    Layout.fillWidth: true
                    text: "VPN providers must be configured in config.json — supported builtins: tailscale, netbird, warp, wireguard. Custom providers use { name, enabled, connectCmd, disconnectCmd, interface, displayName }."
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    opacity: 0.75
                }
                RippleButton {
                    implicitHeight: 28
                    buttonRadius: Appearance?.rounding.small ?? 6
                    contentItem: RowLayout {
                        spacing: 6
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        MaterialSymbol { text: "edit"; iconSize: 14 }
                        StyledText { text: "Open config.json"; font.pixelSize: 11 }
                    }
                    onClicked: Quickshell.execDetached(["xdg-open", Directories.userConfigPath])
                }
            }
        }
    }

    // ═══ Calendar (external sync) ═══
    SettingsCard {
        icon: "event"
        title: "Calendar sync"
        subtitle: "Subscribe to ICS/iCal feeds (Google Calendar, work calendars, public schedules). Events appear wherever the calendar surface is rendered."
        configKeys: ["calendar"]

        ConfigSwitch {
            id: calEnable
            label: "Enable"
            checked: Config.options?.calendar?.externalSync?.enable ?? false
            onCheckedChanged: Config.setNestedValue("calendar.externalSync.enable", checked)
        }

        ConfigSlider {
            label: "Refresh interval"
            from: 5; to: 240; stepSize: 5
            enabled: calEnable.checked
            value: Config.options?.calendar?.externalSync?.refreshMinutes ?? 15
            onValueChanged: Config.setNestedValue("calendar.externalSync.refreshMinutes", Math.round(value))
            valueText: `${Math.round(value)} min`
        }

        ConfigRow {
            label: "Sources"
            sublabel: {
                const n = (Config.options?.calendar?.externalSync?.sources ?? []).length;
                return n === 0
                    ? "No feeds configured. Add iCal/CalDAV URLs to calendar.externalSync.sources in config.json."
                    : `${n} feed${n === 1 ? "" : "s"} configured · ${CalendarSync.events.length} events loaded`;
            }
            RowLayout {
                spacing: 8
                StyledText {
                    text: CalendarSync.fetching ? "syncing…" : (CalendarSync.ready ? "ready" : "idle")
                    font.pixelSize: 11
                    opacity: 0.6
                    font.family: Appearance?.font.family.mono ?? "monospace"
                }
                RippleButton {
                    implicitHeight: 28
                    buttonRadius: Appearance?.rounding.small ?? 6
                    contentItem: RowLayout {
                        spacing: 6
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        MaterialSymbol { text: "edit"; iconSize: 14 }
                        StyledText { text: "Open config.json"; font.pixelSize: 11 }
                    }
                    onClicked: Quickshell.execDetached(["xdg-open", Directories.userConfigPath])
                }
            }
        }
    }

    // ═══ Lyrics ═══
    SettingsCard {
        icon: "lyrics"
        title: "Lyrics"
        subtitle: "Synchronized lyrics for the active media player. Reads local .lrc files, falls back to LRCLIB and NetEase online sources."
        configKeys: ["lyrics"]

        ConfigSwitch {
            id: lyEnable
            label: "Enable"
            checked: Config.options?.lyrics?.enable ?? false
            onCheckedChanged: Config.setNestedValue("lyrics.enable", checked)
        }

        ConfigSwitch {
            label: "Visible by default"
            sublabel: "When off, surfaces start collapsed and the user has to toggle"
            enabled: lyEnable.checked
            checked: Config.options?.lyrics?.visible ?? true
            onCheckedChanged: Config.setNestedValue("lyrics.visible", checked)
        }

        // Backend picker (Auto / Local / LRCLIB / NetEase)
        ConfigRow {
            label: "Backend"
            sublabel: {
                const b = Config.options?.lyrics?.backend ?? "Auto";
                if (b === "Local")   return "Local files only — no network calls";
                if (b === "LRCLIB")  return "Online via lrclib.net (open public corpus)";
                if (b === "NetEase") return "Online via music.163.com (Chinese-music coverage)";
                return "Auto: local file → LRCLIB → NetEase";
            }
            enabled: lyEnable.checked

            ChoiceRow {
                compact: false
                itemSpacing: 4
                model: [
                    { value: "Auto", label: "Auto", icon: "auto_awesome" },
                    { value: "Local", label: "Local", icon: "folder" },
                    { value: "LRCLIB", label: "LRCLIB", icon: "cloud" },
                    { value: "NetEase", label: "NetEase", icon: "language" }
                ]
                current: Config.options?.lyrics?.backend ?? "Auto"
                onChose: value => Config.setNestedValue("lyrics.backend", value)
            }
        }

        ConfigRow {
            label: "Lyrics directory"
            sublabel: "Path for local .lrc files. Supports `~` expansion."
            enabled: lyEnable.checked
            StyledTextInput {
                text: Config.options?.lyrics?.dir ?? "~/.config/anoshell/lyrics"
                onEditingFinished: Config.setNestedValue("lyrics.dir", text.trim())
                Layout.preferredWidth: 220
                font.family: Appearance?.font.family.mono ?? "monospace"
            }
        }
    }

    // ═══ Shell ═══
    SettingsCard {
        icon: "terminal"
        title: "Shell"
        subtitle: "Which shell ano scripts run under. Auto detects from $SHELL; override here when you want bash scripts to run under a specific interpreter."
        configKeys: ["shell"]

        ConfigRow {
            label: "Preferred shell"
            sublabel: `Detected from $SHELL: ${ShellExec.detected}. Active: ${ShellExec.current}.`

            RowLayout {
                spacing: 4
                Repeater {
                    model: ["", "bash", "zsh", "fish", "nushell"]
                    RippleButton {
                        required property string modelData
                        implicitHeight: 26
                        buttonRadius: 6
                        toggled: (Config.options?.shell?.preferred ?? "") === modelData
                        colBackgroundToggled: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
                        contentItem: StyledText {
                            text: modelData === "" ? "Auto" : modelData
                            font.pixelSize: 11
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                        }
                        onClicked: Config.setNestedValue("shell.preferred", modelData)
                    }
                }
            }
        }
    }
}

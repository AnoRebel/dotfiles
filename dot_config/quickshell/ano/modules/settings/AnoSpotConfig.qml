import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import "."

/**
 * AnoSpot settings page — toggle, position selector (4-way), per-widget toggles,
 * and a non-blocking warning when bar.edge collides with anoSpot.position.
 */
ColumnLayout {
    id: root
    spacing: 16

    SettingsPageHeader {
        title: "AnoSpot"
        subtitle: "Position, widgets, click bindings, event border, drag/drop"
        configRoots: ["anoSpot"]
    }

    readonly property bool enabled: Config.options?.anoSpot?.enable ?? false
    readonly property string currentPosition: Config.options?.anoSpot?.position ?? "top"

    // Iterate over every configured bar — multi-monitor / multi-bar
    // setups would otherwise miss collisions on bars beyond the first.
    readonly property var collidingBars: {
        if (!enabled) return []
        const bars = Config.options?.bars ?? []
        const out = []
        for (let i = 0; i < bars.length; ++i) {
            if ((bars[i]?.edge ?? "top") === currentPosition) {
                out.push(bars[i]?.id || `bar ${i}`)
            }
        }
        return out
    }
    readonly property bool collides: collidingBars.length > 0

    // ═══ Enable + collision warning ═══
    SettingsCard {
        icon: "view_compact_alt"
        title: "AnoSpot"
        subtitle: "Dynamic-island-style overlay for now playing, notifications, recording, clock"
        configKeys: ["anoSpot.enable"]

        ConfigSwitch {
            label: "Enable AnoSpot"
            sublabel: "Compositor-agnostic. Works on Hyprland and Niri."
            checked: root.enabled
            onCheckedChanged: Config.setNestedValue("anoSpot.enable", checked)
        }

        Rectangle {
            visible: root.collides
            Layout.fillWidth: true
            implicitHeight: warningRow.implicitHeight + 16
            radius: Appearance?.rounding.small ?? 8
            color: Appearance?.colors.colSecondaryContainer ?? "#5d4037"
            border.width: 1
            border.color: Appearance?.colors.colSecondary ?? "#f9e2af"

            RowLayout {
                id: warningRow
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10
                MaterialSymbol {
                    text: "warning"
                    iconSize: 18
                    color: Appearance?.colors.colSecondary ?? "#f9e2af"
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: {
                        const list = root.collidingBars.join(", ")
                        return `Heads-up: AnoSpot position (${root.currentPosition}) matches the edge of: ${list}. They may visually overlap.`
                    }
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
                    color: Appearance?.colors.colOnSecondaryContainer ?? "#fef9e7"
                }
            }
        }
    }

    // ═══ Position ═══
    SettingsCard {
        icon: "open_in_full"
        title: "Position"
        subtitle: "Which screen edge the overlay anchors to"
        configKeys: ["anoSpot.position", "anoSpot.draggable"]

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 160

            Rectangle {
                anchors.centerIn: parent
                width: 200; height: 130
                radius: 8
                color: Appearance?.colors.colLayer2 ?? "#2B2930"
                border.width: 1
                border.color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"

                StyledText {
                    anchors.centerIn: parent
                    text: "Desktop"
                    font.pixelSize: 11
                    opacity: 0.3
                }

                Repeater {
                    model: [
                        { pos: "top",    x: 70, y: 6,   w: 60, h: 12 },
                        { pos: "bottom", x: 70, y: 112, w: 60, h: 12 },
                        { pos: "left",   x: 6,  y: 50,  w: 12, h: 30 },
                        { pos: "right",  x: 182, y: 50, w: 12, h: 30 }
                    ]

                    Rectangle {
                        required property var modelData
                        x: modelData.x; y: modelData.y
                        width: modelData.w; height: modelData.h
                        radius: Math.min(width, height) / 2
                        color: root.currentPosition === modelData.pos
                            ? Appearance?.colors.colPrimary ?? "#65558F"
                            : "transparent"
                        border.width: 1
                        border.color: root.currentPosition === modelData.pos
                            ? Appearance?.colors.colPrimary ?? "#65558F"
                            : Appearance?.colors.colOutlineVariant ?? "#44444488"
                        opacity: root.currentPosition === modelData.pos ? 1 : 0.3

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.setNestedValue("anoSpot.position", modelData.pos)
                        }
                    }
                }
            }
        }

        ConfigSwitch {
            label: "Allow drag to reposition"
            sublabel: "Show a drag handle on the leading edge; releasing snaps to the nearest screen edge"
            checked: Config.options?.anoSpot?.draggable ?? true
            onCheckedChanged: Config.setNestedValue("anoSpot.draggable", checked)
        }
    }

    // ═══ Widgets ═══
    SettingsCard {
        icon: "widgets"
        title: "Widgets"
        subtitle: "Which slots to render"
        configKeys: ["anoSpot.showMpris", "anoSpot.showNotification", "anoSpot.showRecording", "anoSpot.showClockWeather", "anoSpot.showWorkspace", "anoSpot.showBattery", "anoSpot.showLyrics"]

        ConfigSwitch {
            label: "Now playing (Mpris)"
            checked: Config.options?.anoSpot?.showMpris ?? true
            onCheckedChanged: Config.setNestedValue("anoSpot.showMpris", checked)
        }
        ConfigSwitch {
            label: "Latest notification"
            checked: Config.options?.anoSpot?.showNotification ?? true
            onCheckedChanged: Config.setNestedValue("anoSpot.showNotification", checked)
        }
        ConfigSwitch {
            label: "Recording indicator"
            checked: Config.options?.anoSpot?.showRecording ?? true
            onCheckedChanged: Config.setNestedValue("anoSpot.showRecording", checked)
        }
        ConfigSwitch {
            label: "Clock & weather"
            checked: Config.options?.anoSpot?.showClockWeather ?? true
            onCheckedChanged: Config.setNestedValue("anoSpot.showClockWeather", checked)
        }
        ConfigSwitch {
            label: "Workspace"
            sublabel: "Active workspace number/name (click → overview)"
            checked: Config.options?.anoSpot?.showWorkspace ?? true
            onCheckedChanged: Config.setNestedValue("anoSpot.showWorkspace", checked)
        }
        ConfigSwitch {
            label: "Battery"
            sublabel: "Hidden automatically on desktops without a battery"
            checked: Config.options?.anoSpot?.showBattery ?? true
            onCheckedChanged: Config.setNestedValue("anoSpot.showBattery", checked)
        }
    }

    // ═══ Drag and drop ═══
    SettingsCard {
        icon: "place_item"
        title: "Drag and drop"
        subtitle: "Stage files dropped on AnoSpot for triage and actions"
        configKeys: ["anoSpot.acceptDrops", "anoSpot.stashDir"]

        ConfigSwitch {
            id: dropEnable
            label: "Accept drops"
            sublabel: "When off, drags pass through AnoSpot to whatever is below"
            checked: Config.options?.anoSpot?.acceptDrops ?? true
            onCheckedChanged: Config.setNestedValue("anoSpot.acceptDrops", checked)
        }

        ConfigRow {
            label: "Stash directory"
            sublabel: "Empty = auto ($XDG_RUNTIME_DIR/anoSpot, falls back to /tmp/anoSpot-<UID>)"
            enabled: dropEnable.checked

            ConfigTextInput {
                Layout.fillWidth: true
                Layout.preferredWidth: 240
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                placeholderText: "(auto)"
                text: Config.options?.anoSpot?.stashDir ?? ""
                // Validation: an absolute path or empty for auto-resolution.
                // Catches the common typo of accidental leading whitespace
                // or an unwritable relative path before drops start failing.
                validator: (s) => {
                    const t = (s || "").trim()
                    if (t.length === 0) return null
                    if (!t.startsWith("/") && !t.startsWith("~")) return "Use an absolute or ~ path"
                    return null
                }
                onEditingFinished: Config.setNestedValue("anoSpot.stashDir", text.trim())
            }
        }
    }

    // ═══ Custom drop actions ═══
    SettingsCard {
        icon: "construction"
        title: "Custom drop actions"
        subtitle: "User-defined commands shown as buttons in the stash popout"
        configKeys: ["anoSpot.dropTargets"]

        // ─── API help / placeholder docs ─────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: helpCol.implicitHeight + 16
            radius: Appearance?.rounding.small ?? 8
            color: Appearance?.colors.colLayer2 ?? "#3a3845"
            border.width: 1
            border.color: Appearance?.colors.colOutlineVariant ?? "#44444466"

            ColumnLayout {
                id: helpCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                StyledText {
                    Layout.fillWidth: true
                    text: "Each rule becomes a button in the popout footer. Placeholders are substituted in the command:"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    opacity: 0.8
                    color: Appearance?.colors.colOnLayer0 ?? "#cdd6f4"
                }
                StyledText {
                    Layout.fillWidth: true
                    text: "  {path}   first item's full path        {paths}  newline-joined paths\n" +
                          "  {name}   first item's basename         {names}  newline-joined basenames\n" +
                          "  {dir}    first item's parent dir       {ext}    first item's extension"
                    font.pixelSize: 10
                    font.family: Appearance?.font.family.monospace ?? "monospace"
                    wrapMode: Text.NoWrap
                    color: Appearance?.colors.colOnLayer0 ?? "#cdd6f4"
                    opacity: 0.7
                }
                StyledText {
                    Layout.fillWidth: true
                    text: "Action: 'exec' = argv-split (safe; no shell). 'shell' = bash -c (pipes work; quote your paths). " +
                          "Toggle 'Per item' to invoke the command once per staged file instead of once with all paths."
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    opacity: 0.8
                    color: Appearance?.colors.colOnLayer0 ?? "#cdd6f4"
                }
            }
        }

        // ─── Existing rules ──────────────────────────────────────────────
        Repeater {
            model: Config.options?.anoSpot?.dropTargets ?? []

            Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: ruleCol.implicitHeight + 16
                radius: Appearance?.rounding.small ?? 8
                color: Appearance?.colors.colLayer1 ?? "#2b2930"
                border.width: 1
                border.color: Appearance?.colors.colOutlineVariant ?? "#44444466"

                ColumnLayout {
                    id: ruleCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    RowLayout {
                        spacing: 6
                        StyledText {
                            text: "Name"
                            font.pixelSize: 11; opacity: 0.7
                            Layout.preferredWidth: 64
                        }
                        StyledTextInput {
                            Layout.fillWidth: true
                            text: modelData.name ?? ""
                            onEditingFinished: root._updateRule(index, "name", text)
                        }
                        StyledText {
                            text: "Icon"
                            font.pixelSize: 11; opacity: 0.7
                        }
                        StyledTextInput {
                            Layout.preferredWidth: 110
                            text: modelData.icon ?? "play_arrow"
                            onEditingFinished: root._updateRule(index, "icon", text)
                        }
                        RippleButton {
                            implicitHeight: 26
                            buttonRadius: 6
                            contentItem: RowLayout {
                                spacing: 4
                                MaterialSymbol {
                                    text: "delete"; iconSize: 12
                                    color: Appearance?.colors.colError ?? "#f38ba8"
                                }
                            }
                            onClicked: root._removeRule(index)
                        }
                    }

                    RowLayout {
                        spacing: 6
                        StyledText {
                            text: "Action"
                            font.pixelSize: 11; opacity: 0.7
                            Layout.preferredWidth: 64
                        }
                        // exec/shell selector — ChoiceRow keeps the click
                        // semantics consistent with every other binary
                        // choice on the page (no more "click to flip").
                        ChoiceRow {
                            compact: false
                            itemSpacing: 4
                            model: [
                                { value: "exec", label: "exec", icon: "terminal" },
                                { value: "shell", label: "shell", icon: "code" }
                            ]
                            current: modelData.action ?? "exec"
                            onChose: value => root._updateRule(index, "action", value)
                        }
                        ConfigSwitch {
                            label: "Per item"
                            Layout.fillWidth: true
                            checked: modelData.perItem ?? false
                            onCheckedChanged: root._updateRule(index, "perItem", checked)
                        }
                    }

                    RowLayout {
                        spacing: 6
                        StyledText {
                            text: "Command"
                            font.pixelSize: 11; opacity: 0.7
                            Layout.preferredWidth: 64
                        }
                        StyledTextInput {
                            Layout.fillWidth: true
                            text: modelData.command ?? ""
                            font.family: Appearance?.font.family.monospace ?? "monospace"
                            onEditingFinished: root._updateRule(index, "command", text)
                        }
                    }
                }
            }
        }

        // ─── Add new rule ────────────────────────────────────────────────
        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 32
            buttonRadius: 8
            contentItem: RowLayout {
                spacing: 6
                MaterialSymbol { text: "add"; iconSize: 14 }
                StyledText {
                    text: "Add custom action"
                    font.pixelSize: 12
                }
            }
            onClicked: root._addRule()
        }
    }

    // ─── Helpers (live at the page root so cards can call them) ─────────
    function _addRule() {
        const cur = (Config.options?.anoSpot?.dropTargets ?? []).slice();
        cur.push({
            name: "New action",
            icon: "play_arrow",
            action: "exec",
            command: "",
            perItem: false
        });
        Config.setNestedValue("anoSpot.dropTargets", cur);
    }
    function _removeRule(idx) {
        const cur = (Config.options?.anoSpot?.dropTargets ?? []).slice();
        if (idx < 0 || idx >= cur.length) return;
        cur.splice(idx, 1);
        Config.setNestedValue("anoSpot.dropTargets", cur);
    }
    function _updateRule(idx, key, value) {
        const cur = (Config.options?.anoSpot?.dropTargets ?? []).slice();
        if (idx < 0 || idx >= cur.length) return;
        const rule = Object.assign({}, cur[idx]);
        rule[key] = value;
        cur[idx] = rule;
        Config.setNestedValue("anoSpot.dropTargets", cur);
    }

    // ═══ Event border animation ═══
    SettingsCard {
        icon: "auto_awesome"
        title: "Event border animation"
        subtitle: "Pulsing gradient halo when configured events occur"
        configKeys: ["anoSpot.eventBorder"]

        ConfigSwitch {
            id: borderEnable
            label: "Enable"
            checked: Config.options?.anoSpot?.eventBorder?.enable ?? true
            onCheckedChanged: Config.setNestedValue("anoSpot.eventBorder.enable", checked)
        }

        ConfigSlider {
            label: "Hold duration"
            sublabel: "How long the halo stays visible before fading out"
            from: 500; to: 5000; stepSize: 100
            value: Config.options?.anoSpot?.eventBorder?.holdMs ?? 1500
            valueText: Format.formatDuration(value)
            enabled: borderEnable.checked
            onValueChanged: Config.setNestedValue("anoSpot.eventBorder.holdMs", Math.round(value))
        }

        // ─── Per-event-type triggers ─────────────────────────────────────
        // Each switch toggles presence of its event-type string in the
        // anoSpot.eventBorder.events array.
        function _hasEvent(name) {
            const events = Config.options?.anoSpot?.eventBorder?.events ?? [];
            return events.indexOf(name) >= 0;
        }
        function _setEvent(name, on) {
            const current = (Config.options?.anoSpot?.eventBorder?.events ?? []).slice();
            const idx = current.indexOf(name);
            if (on && idx < 0) current.push(name);
            else if (!on && idx >= 0) current.splice(idx, 1);
            Config.setNestedValue("anoSpot.eventBorder.events", current);
        }

        ConfigSwitch {
            label: "On notification"
            checked: parent._hasEvent("notification")
            enabled: borderEnable.checked
            onCheckedChanged: parent._setEvent("notification", checked)
        }
        ConfigSwitch {
            label: "On track change"
            checked: parent._hasEvent("track")
            enabled: borderEnable.checked
            onCheckedChanged: parent._setEvent("track", checked)
        }
        ConfigSwitch {
            label: "On recording start/stop"
            checked: parent._hasEvent("recording")
            enabled: borderEnable.checked
            onCheckedChanged: parent._setEvent("recording", checked)
        }
        ConfigSwitch {
            label: "On workspace change"
            sublabel: "Fires often if you switch workspaces frequently"
            checked: parent._hasEvent("workspace")
            enabled: borderEnable.checked
            onCheckedChanged: parent._setEvent("workspace", checked)
        }
    }
}

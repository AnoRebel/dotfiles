import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.bar.modules
import qs.services
import "."

/**
 * Bar configuration — elaborate settings with visual bar preview,
 * edge selector with diagram, module reorder, scroll actions, weather, tray.
 */
ColumnLayout {
    id: root
    spacing: 16

    // configRoots: this page owns `bar` (including bar.morphingPanels even
    // though ModulesConfig has a dotted entry for it — both pages can
    // reset the key, the user can pick whichever page they think of first).
    SettingsPageHeader {
        title: "Bar"
        subtitle: "Edge, layout, modules, click actions, weather, tray"
        configRoots: ["bar", "bars", "tray"]
    }

    readonly property string currentEdge: Config.options?.bars?.[0]?.edge ?? "top"
    readonly property var leftModules: Config.options?.bars?.[0]?.modules?.left ?? ["sidebarButton", "activeWindow"]
    readonly property var centerModules: Config.options?.bars?.[0]?.modules?.center ?? ["workspaces"]
    readonly property var rightModules: Config.options?.bars?.[0]?.modules?.right ?? ["clock", "battery", "network", "bluetooth", "tray", "sidebarButton"]

    // ═══ Bar Position & Style ═══
    SettingsCard {
        icon: "dock_to_bottom"
        title: "Position & Style"
        subtitle: "Bar edge, auto-hide, background, and margin"
        configKeys: ["bar.position", "bar.cornerStyle", "bar.autoHide", "bar.showBackground", "bars"]

        // Visual edge selector
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 160

            Rectangle {
                id: screenPreview
                anchors.centerIn: parent
                width: 200; height: 130
                radius: 8
                color: Appearance?.colors.colLayer2 ?? "#2B2930"
                border.width: 1; border.color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"

                // Desktop label
                StyledText {
                    anchors.centerIn: parent
                    text: "Desktop"
                    font.pixelSize: 11; opacity: 0.3
                }

                // Bar indicator for each edge
                Repeater {
                    model: [
                        { edge: "top", x: 20, y: 2, w: 160, h: 8 },
                        { edge: "bottom", x: 20, y: 120, w: 160, h: 8 },
                        { edge: "left", x: 2, y: 20, w: 8, h: 90 },
                        { edge: "right", x: 190, y: 20, w: 8, h: 90 }
                    ]

                    Rectangle {
                        required property var modelData
                        x: modelData.x; y: modelData.y
                        width: modelData.w; height: modelData.h
                        radius: 4
                        color: root.currentEdge === modelData.edge
                            ? Appearance?.colors.colPrimary ?? "#65558F"
                            : "transparent"
                        border.width: 1
                        border.color: root.currentEdge === modelData.edge
                            ? Appearance?.colors.colPrimary ?? "#65558F"
                            : Appearance?.colors.colOutlineVariant ?? "#44444488"
                        opacity: root.currentEdge === modelData.edge ? 1 : 0.3

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.setNestedValue("bars.0.edge", modelData.edge)
                        }
                    }
                }
            }

            // Edge label
            StyledText {
                anchors { bottom: screenPreview.top; horizontalCenter: screenPreview.horizontalCenter; bottomMargin: 4 }
                text: `Current: ${root.currentEdge}`
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                font.weight: Font.DemiBold
                color: Appearance?.colors.colPrimary ?? "#65558F"
            }
        }

        // Quick edge buttons
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Repeater {
                model: ["top", "bottom", "left", "right"]
                GroupButton {
                    required property string modelData
                    label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    iconName: modelData === "top" ? "vertical_align_top" : modelData === "bottom" ? "vertical_align_bottom" : modelData === "left" ? "align_horizontal_left" : "align_horizontal_right"
                    toggled: root.currentEdge === modelData
                    onClicked: Config.setNestedValue("bars.0.edge", modelData)
                    Layout.fillWidth: true
                }
            }
        }

        // Divider
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.2 }

        ConfigSwitch {
            label: "Auto hide"
            sublabel: "Bar slides away when not hovered, revealing more screen"
            checked: Config.options?.bar?.autoHide?.enable ?? false
            onCheckedChanged: Config.setNestedValue("bar.autoHide.enable", checked)
        }

        ConfigSwitch {
            label: "Show background"
            sublabel: "Transparent bar when disabled — modules float directly"
            checked: Config.options?.bar?.showBackground ?? true
            onCheckedChanged: Config.setNestedValue("bar.showBackground", checked)
        }

        ConfigRow {
            label: "Corner style"
            sublabel: "0 = floating (default), 1 = edge-to-edge with bezel padding"
            ButtonGroup {
                buttons: [
                    GroupButton { label: "Floating"; toggled: (Config.options?.bar?.cornerStyle ?? 0) === 0; onClicked: Config.setNestedValue("bar.cornerStyle", 0) },
                    GroupButton { label: "Edge-to-edge"; toggled: (Config.options?.bar?.cornerStyle ?? 0) === 1; onClicked: Config.setNestedValue("bar.cornerStyle", 1) }
                ]
            }
        }
    }

    // ═══ Bar Modules ═══
    SettingsCard {
        icon: "view_module"
        title: "Bar Modules"
        subtitle: "Drop modules into the left, center, and right sections. Reorder with the ◂ ▸ buttons."
        configKeys: ["bars"]

        // ── Left section ───────────────────────────────────────────────
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true
            StyledText { text: "Left section"; font.weight: Font.DemiBold; font.pixelSize: Appearance?.font.pixelSize.small ?? 14 }
            BarModuleSection {
                Layout.fillWidth: true
                section: "left"
                modules: root.leftModules
            }
        }

        // ── Center section ─────────────────────────────────────────────
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true
            StyledText { text: "Center section"; font.weight: Font.DemiBold; font.pixelSize: Appearance?.font.pixelSize.small ?? 14 }
            BarModuleSection {
                Layout.fillWidth: true
                section: "center"
                modules: root.centerModules
            }
        }

        // ── Right section ──────────────────────────────────────────────
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true
            StyledText { text: "Right section"; font.weight: Font.DemiBold; font.pixelSize: Appearance?.font.pixelSize.small ?? 14 }
            BarModuleSection {
                Layout.fillWidth: true
                section: "right"
                modules: root.rightModules
            }
        }

        NoticeBox {
            text: "Module changes apply to bar 0 (the primary bar). Multi-bar configs are edited via config.json. Bar reload required."
            iconName: "info"
        }
    }

    // Inline component for one bar section's chip editor. Shows active
    // chips with reorder/remove affordances, and an "Add" button revealing
    // the available-modules palette.
    component BarModuleSection: ColumnLayout {
        id: section
        property string section: ""           // "left" | "center" | "right"
        property var modules: []              // current active list
        property bool _addingMode: false      // true while the available palette is shown

        readonly property string _configPath: `bars.0.modules.${section}`
        readonly property var _allIds: BarModuleLoader.availableModuleIds ?? []
        // Available = catalogue minus what's already active
        readonly property var _availableIds: {
            const active = section.modules ?? []
            return section._allIds.filter(id => !active.includes(id))
        }

        function _writeModules(arr) {
            Config.setNestedValue(section._configPath, arr)
        }

        function _moveBy(idx, delta) {
            const arr = [...section.modules]
            const next = idx + delta
            if (next < 0 || next >= arr.length) return
            const tmp = arr[next]; arr[next] = arr[idx]; arr[idx] = tmp
            section._writeModules(arr)
        }

        function _remove(idx) {
            const arr = [...section.modules]
            arr.splice(idx, 1)
            section._writeModules(arr)
        }

        function _add(id) {
            const arr = [...section.modules, id]
            section._writeModules(arr)
            section._addingMode = false
        }

        spacing: 6

        // Active chip row + add button
        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: section.modules

                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    required property int index

                    readonly property string moduleId: chip.modelData
                    readonly property bool isKnown: BarModuleLoader.isKnownModule(chip.moduleId)
                    readonly property string displayLabel:
                        chip.isKnown
                            ? `${chip.index + 1}. ${BarModuleLoader.labelFor(chip.moduleId)}`
                            : `Unknown: ${chip.moduleId}`

                    implicitWidth: chipRow.implicitWidth + 14
                    implicitHeight: 30
                    radius: Appearance?.rounding.small ?? 8
                    color: chip.isKnown
                        ? (Appearance?.colors.colSecondaryContainer ?? "#E8DEF8")
                        : (Appearance?.m3colors.m3errorContainer ?? "#5C1A1A")
                    border.width: chip.isKnown ? 0 : 1
                    border.color: Appearance?.m3colors.m3error ?? "#F2B8B5"

                    RowLayout {
                        id: chipRow
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 8 }
                        spacing: 4

                        StyledText {
                            text: chip.displayLabel
                            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                            color: chip.isKnown
                                ? (Appearance?.m3colors.m3onSecondaryContainer ?? "#1D192B")
                                : (Appearance?.m3colors.m3onErrorContainer ?? "#F9DEDC")
                        }

                        // ◂ move-left / ▴ move-up
                        ToolbarButton {
                            iconName: "chevron_left"
                            iconSize: 16
                            visible: chip.index > 0
                            toolTipText: "Move earlier"
                            onClicked: section._moveBy(chip.index, -1)
                        }
                        // ▸ move-right / ▾ move-down
                        ToolbarButton {
                            iconName: "chevron_right"
                            iconSize: 16
                            visible: chip.index < (section.modules.length - 1)
                            toolTipText: "Move later"
                            onClicked: section._moveBy(chip.index, 1)
                        }
                        // ✕ remove
                        ToolbarButton {
                            iconName: "close"
                            iconSize: 16
                            toolTipText: "Remove"
                            onClicked: section._remove(chip.index)
                        }
                    }
                }
            }

            // Empty-state hint when the section has no modules
            Loader {
                active: (section.modules ?? []).length === 0
                visible: active
                sourceComponent: StyledText {
                    text: "No modules yet — click + to add"
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                    color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                    opacity: 0.7
                }
            }

            // + Add module button
            RippleButton {
                implicitHeight: 30
                buttonRadius: Appearance?.rounding.small ?? 8
                visible: section._availableIds.length > 0
                contentItem: RowLayout {
                    spacing: 4
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                    MaterialSymbol {
                        text: section._addingMode ? "expand_less" : "add"
                        iconSize: 14
                    }
                    StyledText {
                        text: section._addingMode ? "Hide" : "Add"
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                    }
                }
                onClicked: section._addingMode = !section._addingMode
            }
        }

        // Available palette — only visible while adding
        Loader {
            Layout.fillWidth: true
            active: section._addingMode && section._availableIds.length > 0
            visible: active
            sourceComponent: Rectangle {
                implicitHeight: paletteFlow.implicitHeight + 12
                radius: Appearance?.rounding.small ?? 8
                color: Appearance?.colors.colLayer2 ?? "#2B2930"
                border.width: 1
                border.color: Appearance?.colors.colOutlineVariant ?? "#49454F"

                Flow {
                    id: paletteFlow
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
                    spacing: 6

                    Repeater {
                        model: section._availableIds
                        delegate: Rectangle {
                            id: paletteChip
                            required property var modelData

                            implicitWidth: paletteLabel.implicitWidth + 22
                            implicitHeight: 28
                            radius: Appearance?.rounding.small ?? 8
                            color: paletteMA.containsMouse
                                ? (Appearance?.colors.colLayer1Hover ?? "#3C3947")
                                : (Appearance?.colors.colLayer1 ?? "#2B2930")
                            border.width: 1
                            border.color: Appearance?.colors.colOutlineVariant ?? "#49454F"

                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                MaterialSymbol {
                                    text: "add"
                                    iconSize: 12
                                    color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                                }
                                StyledText {
                                    id: paletteLabel
                                    text: BarModuleLoader.labelFor(paletteChip.modelData)
                                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                                    color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                                }
                            }

                            MouseArea {
                                id: paletteMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: section._add(paletteChip.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══ Layout & Sizing ═══
    SettingsCard {
        icon: "straighten"
        title: "Layout & Sizing"
        subtitle: "Bar height, corner radius, module spacing, padding, and decorations"
        configKeys: ["bar.layout"]

        // Live preview bar mockup
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.85; height: Config.options?.bar?.layout?.height ?? 42
                radius: Config.options?.bar?.layout?.radius ?? 12
                color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
                border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"

                RowLayout {
                    anchors { fill: parent; leftMargin: Config.options?.bar?.layout?.edgePadding ?? 8; rightMargin: Config.options?.bar?.layout?.edgePadding ?? 8 }

                    // Left mock modules
                    RowLayout {
                        spacing: Config.options?.bar?.layout?.leftSpacing ?? 8
                        Repeater { model: 2; Rectangle { width: 40; height: 14; radius: 7; color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"; opacity: 0.15 } }
                    }

                    Item { Layout.fillWidth: true }

                    // Center mock group
                    Rectangle {
                        implicitWidth: centerMockRow.implicitWidth + (Config.options?.bar?.layout?.centerGroupPadding ?? 5) * 2
                        implicitHeight: parent.height - 8
                        radius: Config.options?.bar?.layout?.centerGroupRadius ?? 8
                        color: (Config.options?.bar?.layout?.showCenterBackground ?? true) ? (Appearance?.colors.colLayer1 ?? "#E5E1EC") : "transparent"
                        RowLayout {
                            id: centerMockRow; anchors.centerIn: parent; spacing: Config.options?.bar?.layout?.centerSpacing ?? 4
                            Repeater { model: 6; Rectangle { width: 8; height: 8; radius: 4; color: Appearance?.colors.colPrimary ?? "#65558F"; opacity: index === 2 ? 1 : 0.3 } }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Right mock modules
                    RowLayout {
                        spacing: Config.options?.bar?.layout?.rightSpacing ?? 8
                        Repeater { model: 4; Rectangle { width: 30; height: 14; radius: 7; color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"; opacity: 0.15 } }
                    }

                    // Separators if enabled
                    Repeater {
                        model: (Config.options?.bar?.layout?.showSeparators ?? false) ? 2 : 0
                        Rectangle { width: 1; height: parent.height * 0.5; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.3 }
                    }
                }
            }

            StyledText {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                text: `${Config.options?.bar?.layout?.height ?? 42}px tall • ${Config.options?.bar?.layout?.radius ?? 12}px radius`
                font.pixelSize: 10; opacity: 0.4
            }
        }

        ConfigSlider {
            label: "Bar height"
            sublabel: "Total thickness of the bar in pixels"
            from: 28; to: 64; stepSize: 2
            value: Config.options?.bar?.layout?.height ?? 42
            onValueChanged: Config.setNestedValue("bar.layout.height", Math.round(value))
            valueText: `${Math.round(value)}px`
        }
        ConfigSlider {
            label: "Corner radius"
            sublabel: "Rounding of the bar background corners"
            from: 0; to: 28; stepSize: 1
            value: Config.options?.bar?.layout?.radius ?? 12
            onValueChanged: Config.setNestedValue("bar.layout.radius", Math.round(value))
            valueText: `${Math.round(value)}px`
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.15 }

        ConfigSlider {
            label: "Left section spacing"
            sublabel: "Gap between modules in the left section"
            from: 0; to: 24; stepSize: 1
            value: Config.options?.bar?.layout?.leftSpacing ?? 8
            onValueChanged: Config.setNestedValue("bar.layout.leftSpacing", Math.round(value))
            valueText: `${Math.round(value)}px`
        }
        ConfigSlider {
            label: "Center section spacing"
            sublabel: "Gap between modules in the center group"
            from: 0; to: 16; stepSize: 1
            value: Config.options?.bar?.layout?.centerSpacing ?? 4
            onValueChanged: Config.setNestedValue("bar.layout.centerSpacing", Math.round(value))
            valueText: `${Math.round(value)}px`
        }
        ConfigSlider {
            label: "Right section spacing"
            sublabel: "Gap between modules in the right section"
            from: 0; to: 24; stepSize: 1
            value: Config.options?.bar?.layout?.rightSpacing ?? 8
            onValueChanged: Config.setNestedValue("bar.layout.rightSpacing", Math.round(value))
            valueText: `${Math.round(value)}px`
        }
        ConfigSlider {
            label: "Edge padding"
            sublabel: "Distance from screen edge to first/last module"
            from: 0; to: 32; stepSize: 1
            value: Config.options?.bar?.layout?.edgePadding ?? 8
            onValueChanged: Config.setNestedValue("bar.layout.edgePadding", Math.round(value))
            valueText: `${Math.round(value)}px`
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.15 }

        ConfigSlider {
            label: "Center group padding"
            sublabel: "Inner padding of the center pill container"
            from: 0; to: 16; stepSize: 1
            value: Config.options?.bar?.layout?.centerGroupPadding ?? 5
            onValueChanged: Config.setNestedValue("bar.layout.centerGroupPadding", Math.round(value))
            valueText: `${Math.round(value)}px`
        }
        ConfigSlider {
            label: "Center group radius"
            sublabel: "Corner rounding of the center pill container"
            from: 0; to: 24; stepSize: 1
            value: Config.options?.bar?.layout?.centerGroupRadius ?? 8
            onValueChanged: Config.setNestedValue("bar.layout.centerGroupRadius", Math.round(value))
            valueText: `${Math.round(value)}px`
        }
        ConfigSwitch {
            label: "Show center group background"
            sublabel: "Visible pill background behind center modules (workspaces)"
            checked: Config.options?.bar?.layout?.showCenterBackground ?? true
            onCheckedChanged: Config.setNestedValue("bar.layout.showCenterBackground", checked)
        }
        ConfigSwitch {
            label: "Show section separators"
            sublabel: "Thin vertical lines between left, center, and right sections"
            checked: Config.options?.bar?.layout?.showSeparators ?? false
            onCheckedChanged: Config.setNestedValue("bar.layout.showSeparators", checked)
        }
    }

    // ═══ Click & Scroll Actions ═══
    SettingsCard {
        icon: "touch_app"
        title: "Click & Scroll Actions"
        subtitle: "What happens when you click or scroll on each bar section"
        configKeys: ["bar.actions"]

        readonly property var actionChoices: [
            { value: "sidebarLeft", label: "Left Sidebar", icon: "view_sidebar" },
            { value: "sidebarRight", label: "Right Sidebar", icon: "view_sidebar" },
            { value: "overview", label: "Overview", icon: "overview" },
            { value: "settings", label: "Settings", icon: "settings" },
            { value: "hud", label: "HUD", icon: "dashboard" },
            { value: "session", label: "Session", icon: "power_settings_new" },
            { value: "clipboard", label: "Clipboard", icon: "content_paste" },
            { value: "wallpaper", label: "Wallpaper", icon: "image" },
            { value: "cheatsheet", label: "Cheatsheet", icon: "keyboard" },
            { value: "none", label: "None", icon: "block" },
        ]
        readonly property var scrollChoices: [
            { value: "brightness", label: "Brightness", icon: "brightness_6" },
            { value: "volume", label: "Volume", icon: "volume_up" },
            { value: "workspace", label: "Workspace", icon: "grid_view" },
            { value: "none", label: "None", icon: "block" },
        ]

        // Helper to look up an action's display label for the header rows
        function _labelFor(actions, value) {
            for (const a of actions) if (a.value === value) return a.label
            return "(unknown)"
        }

        // Click actions
        StyledText { text: "Click actions"; font.weight: Font.DemiBold; font.pixelSize: Appearance?.font.pixelSize.small ?? 14; Layout.fillWidth: true }

        Repeater {
            model: [
                { section: "Left", key: "leftClick", default_: "sidebarLeft", desc: "Left section click" },
                { section: "Right", key: "rightClick", default_: "sidebarRight", desc: "Right section click" },
                { section: "Center", key: "centerClick", default_: "overview", desc: "Center section right-click" },
            ]

            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 4

                // Header row — section name + currently-selected action label.
                // Replaces the previous icon-only buttons with no visible label.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    StyledText {
                        text: parent.modelData.desc
                        font.pixelSize: Appearance?.font.pixelSize.small ?? 13
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: "→ " + _labelFor(actionChoices,
                            Config.options?.bar?.actions?.[parent.parent.modelData.key] ?? parent.parent.modelData.default_)
                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                        opacity: 0.7
                    }
                }

                ChoiceRow {
                    Layout.fillWidth: true
                    compact: true
                    itemSpacing: 4
                    model: actionChoices
                    current: Config.options?.bar?.actions?.[parent.modelData.key] ?? parent.modelData.default_
                    onChose: value => Config.setNestedValue(`bar.actions.${parent.modelData.key}`, value)
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.15 }

        // Scroll actions
        StyledText { text: "Scroll actions"; font.weight: Font.DemiBold; font.pixelSize: Appearance?.font.pixelSize.small ?? 14; Layout.fillWidth: true }

        ConfigRow {
            label: "Left section scroll"
            ChoiceRow {
                model: scrollChoices
                current: Config.options?.bar?.actions?.scrollLeft ?? "brightness"
                onChose: value => Config.setNestedValue("bar.actions.scrollLeft", value)
            }
        }
        ConfigRow {
            label: "Right section scroll"
            ChoiceRow {
                model: scrollChoices
                current: Config.options?.bar?.actions?.scrollRight ?? "volume"
                onChose: value => Config.setNestedValue("bar.actions.scrollRight", value)
            }
        }
        ConfigRow {
            label: "Center section scroll"
            ChoiceRow {
                model: scrollChoices
                current: Config.options?.bar?.actions?.scrollCenter ?? "workspace"
                onChose: value => Config.setNestedValue("bar.actions.scrollCenter", value)
            }
        }
    }

    // ═══ Workspaces ═══
    SettingsCard {
        icon: "grid_view"
        title: "Workspaces"
        subtitle: "Workspace indicator count and style"
        configKeys: ["bar.workspaces"]

        ConfigSlider {
            label: "Number of workspaces shown"
            sublabel: "How many workspace dots appear in the bar"
            from: 2; to: 20; stepSize: 1
            value: Config.options?.bar?.workspaces?.shown ?? 10
            onValueChanged: Config.setNestedValue("bar.workspaces.shown", Math.round(value))
            valueText: `${Math.round(value)}`
        }
    }

    // ═══ Weather ═══
    SettingsCard {
        icon: "thermostat"
        title: "Weather"
        subtitle: "Weather data in bar and sidebar"
        configKeys: ["bar.weather"]

        ConfigSwitch {
            label: "Show weather module in bar"
            checked: Config.options?.bar?.weather?.enable ?? false
            onCheckedChanged: Config.setNestedValue("bar.weather.enable", checked)
        }

        ConfigRow {
            label: "City name"
            sublabel: (Config.options?.bar?.weather?.enableGPS ?? false)
                ? "GPS positioning is on — manual city is ignored"
                : "Leave empty to disable, or specify a city for manual lookup"
            enabled: !(Config.options?.bar?.weather?.enableGPS ?? false)
            StyledTextInput {
                text: Config.options?.bar?.weather?.city ?? ""
                onEditingFinished: Config.setNestedValue("bar.weather.city", text)
                Layout.preferredWidth: 180
            }
        }

        ConfigSwitch {
            label: "Use Fahrenheit (USCS)"
            sublabel: "Imperial units (°F, mph, inches)"
            checked: Config.options?.bar?.weather?.useUSCS ?? false
            onCheckedChanged: Config.setNestedValue("bar.weather.useUSCS", checked)
        }

        ConfigSwitch {
            label: "Enable GPS positioning"
            sublabel: "Auto-detect location for weather"
            checked: Config.options?.bar?.weather?.enableGPS ?? false
            onCheckedChanged: Config.setNestedValue("bar.weather.enableGPS", checked)
        }

        ConfigSlider {
            label: "Fetch interval"
            sublabel: "How often weather data refreshes"
            from: 1; to: 60; stepSize: 1
            value: Config.options?.bar?.weather?.fetchInterval ?? 15
            onValueChanged: Config.setNestedValue("bar.weather.fetchInterval", Math.round(value))
            valueText: `${Math.round(value)} min`
        }
    }

    // ═══ System Tray ═══
    SettingsCard {
        icon: "more_horiz"
        title: "System Tray"
        subtitle: "Tray icon filtering and pin management"
        configKeys: ["tray"]

        ConfigSwitch {
            label: "Filter passive items"
            sublabel: "Hide tray items with 'passive' status (reduces clutter)"
            checked: Config.options?.tray?.filterPassive ?? false
            onCheckedChanged: Config.setNestedValue("tray.filterPassive", checked)
        }

        ConfigSwitch {
            label: "Invert pinned items"
            sublabel: "Swap which items are shown as pinned vs overflow"
            checked: Config.options?.tray?.invertPinnedItems ?? false
            onCheckedChanged: Config.setNestedValue("tray.invertPinnedItems", checked)
        }

        ConfigSwitch {
            label: "Show item ID in tooltip"
            sublabel: "Useful for identifying which items to pin"
            checked: Config.options?.tray?.showItemId ?? false
            onCheckedChanged: Config.setNestedValue("tray.showItemId", checked)
        }
    }
}

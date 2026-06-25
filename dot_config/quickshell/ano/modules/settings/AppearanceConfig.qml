import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import "."

/**
 * Appearance settings — elaborate with color preview, bezel visualization,
 * animation controls, and wallpaper rotation config.
 */
ColumnLayout {
    id: appearanceRoot
    spacing: 16

    SettingsPageHeader {
        title: "Appearance"
        subtitle: "Theme source, colors, bezel, animations, wallpaper rotation"
        configRoots: ["appearance", "background", "animations"]
    }

    // Track the originally-selected theme so hover-preview can revert
    // when the cursor leaves a card without the user clicking. Captured
    // once on entry into the picker, restored on cancel/exit.
    readonly property string committedSource: Config.options?.appearance?.theme?.source ?? "materialYou"
    readonly property string committedStatic: Config.options?.appearance?.theme?.name ?? ""

    // True while the user is hovering a non-selected theme card. Pinned
    // by mouse-enter, cleared on click (commits) or mouse-leave (reverts).
    property bool previewing: false
    property string previewingName: ""

    // Preview a theme without writing to the user delta. Sets
    // Appearance.previewTokens; both theme loaders defer to it for the
    // duration of the hover.
    function _previewTheme(name: string): void {
        const tokens = ThemeRegistry.themeContents ? ThemeRegistry.themeContents[name] : null
        if (!tokens) return
        Appearance.previewTokens = tokens
        previewing = true
        previewingName = name
    }

    // Clear the preview overlay. The active source (Material You or the
    // committed static theme) re-renders on the next tick.
    function _revertPreview(): void {
        if (!previewing) return
        Appearance.previewTokens = null
        previewing = false
        previewingName = ""
    }

    // Commit the previewed theme to the user delta. Clears previewTokens
    // synchronously *before* the disk write so there's no stale-overlay
    // tick.
    function _commitTheme(name: string): void {
        Appearance.previewTokens = null
        previewing = false
        previewingName = ""
        Config.setNestedValue("appearance.theme.source", "static")
        Config.setNestedValue("appearance.theme.name", name)
    }

    function _commitMaterialYou(): void {
        Appearance.previewTokens = null
        previewing = false
        previewingName = ""
        Config.setNestedValue("appearance.theme.source", "materialYou")
    }

    // ═══ Theme Source ═══
    SettingsCard {
        icon: "auto_awesome"
        title: "Theme source"
        subtitle: "Dynamic Material You (wallpaper-derived) or pick a static theme"
        configKeys: ["appearance.theme", "appearance.colors"]

        ConfigRow {
            label: "Source"
            sublabel: appearanceRoot.committedSource === "materialYou"
                ? "Dynamic — palette derived from the active wallpaper"
                : `Static — ${appearanceRoot.committedStatic || "(none selected)"}`

            RowLayout {
                spacing: 4
                Repeater {
                    model: ["materialYou", "static"]
                    RippleButton {
                        required property string modelData
                        implicitHeight: 28
                        buttonRadius: 8
                        toggled: appearanceRoot.committedSource === modelData
                        colBackgroundToggled: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
                        contentItem: StyledText {
                            text: modelData === "materialYou" ? "Material You" : "Static"
                            font.pixelSize: 12
                            anchors.leftMargin: 10; anchors.rightMargin: 10
                        }
                        onClicked: {
                            if (modelData === "materialYou") appearanceRoot._commitMaterialYou()
                            else if (appearanceRoot.committedStatic.length > 0)
                                appearanceRoot._commitTheme(appearanceRoot.committedStatic)
                            else
                                Config.setNestedValue("appearance.theme.source", "static")
                        }
                    }
                }
            }
        }

        // ─── Theme grid (visible only when source = static or while previewing) ───
        Item {
            Layout.fillWidth: true
            implicitHeight: visible ? grid.implicitHeight + 16 : 0
            visible: appearanceRoot.committedSource === "static" || appearanceRoot.previewing

            // Two-column grid of theme cards. Hover previews; click commits.
            GridLayout {
                id: grid
                anchors.fill: parent
                anchors.topMargin: 8
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: ThemeRegistry.themes

                    Rectangle {
                        required property var modelData
                        readonly property string themeName: modelData.name
                        readonly property bool isCommitted:
                            appearanceRoot.committedSource === "static"
                            && appearanceRoot.committedStatic === themeName
                        readonly property bool isPreviewing:
                            appearanceRoot.previewing
                            && appearanceRoot.previewingName === themeName

                        Layout.fillWidth: true
                        Layout.preferredHeight: cellCol.implicitHeight + 16
                        radius: Appearance?.rounding.small ?? 8
                        color: themeMa.containsMouse
                            ? (Appearance?.colors.colLayer2 ?? "#3a3845")
                            : (Appearance?.colors.colLayer1 ?? "#2b2930")
                        border.width: (isCommitted || isPreviewing) ? 2 : 1
                        border.color: isCommitted
                            ? (Appearance?.colors.colPrimary ?? "#a6e3a1")
                            : isPreviewing
                                ? (Appearance?.colors.colSecondary ?? "#cba6f7")
                                : (Appearance?.colors.colOutlineVariant ?? "#44444466")
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        ColumnLayout {
                            id: cellCol
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            // Header: name + dark/light + source badge
                            RowLayout {
                                spacing: 6
                                StyledText {
                                    text: modelData.displayName
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    visible: modelData.source === "user"
                                    radius: 4
                                    color: Appearance?.colors.colTertiaryContainer ?? "#5a4a3a"
                                    implicitWidth: userBadge.implicitWidth + 8
                                    implicitHeight: userBadge.implicitHeight + 4
                                    StyledText {
                                        id: userBadge
                                        anchors.centerIn: parent
                                        text: "user"
                                        font.pixelSize: 9
                                    }
                                }
                                MaterialSymbol {
                                    text: modelData.darkmode ? "dark_mode" : "light_mode"
                                    iconSize: 14
                                    color: modelData.darkmode
                                        ? Qt.rgba(1, 1, 1, 0.55)
                                        : Qt.rgba(1, 0.85, 0.4, 0.85)
                                }
                            }

                            // Swatch row — primary / surface / surface-container / outline
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Repeater {
                                    model: [
                                        modelData.primary,
                                        modelData.surface,
                                        modelData.surfaceContainer,
                                        modelData.outline
                                    ]
                                    Rectangle {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 16
                                        radius: 4
                                        color: modelData
                                        border.width: 1
                                        border.color: Qt.rgba(0, 0, 0, 0.25)
                                    }
                                }
                            }

                            // Description
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.description
                                font.pixelSize: 10
                                opacity: 0.6
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: themeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                if (!parent.isCommitted) appearanceRoot._previewTheme(parent.themeName)
                            }
                            onExited: {
                                if (appearanceRoot.previewing
                                    && appearanceRoot.previewingName === parent.themeName)
                                    appearanceRoot._revertPreview()
                            }
                            onClicked: appearanceRoot._commitTheme(parent.themeName)
                        }
                    }
                }
            }
        }

        NoticeBox {
            visible: appearanceRoot.committedSource === "static" && ThemeRegistry.count === 0
            text: "No themes found. Bundled themes live in assets/themes/. Drop additional .json files into ~/.config/anoshell/themes/ to add your own."
            iconName: "info"
        }

        NoticeBox {
            visible: appearanceRoot.previewing
            text: `Previewing "${appearanceRoot.previewingName}". Click a card to apply, or move the cursor away to revert.`
            iconName: "preview"
        }
    }

    // ═══ Theme Colors ═══
    SettingsCard {
        icon: "palette"
        title: "Theme Colors"
        subtitle: "Live color swatches from the active palette"
        configKeys: ["appearance.colors"]
        collapsible: true
        expanded: false

        // Live color swatch grid
        GridLayout {
            Layout.fillWidth: true
            columns: 6; columnSpacing: 6; rowSpacing: 6

            Repeater {
                model: [
                    { name: "Primary", color: Appearance?.colors.colPrimary ?? "#65558F" },
                    { name: "On Primary", color: Appearance?.m3colors.m3onPrimary ?? "white" },
                    { name: "Secondary", color: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8" },
                    { name: "Background", color: Appearance?.m3colors.m3background ?? "#1C1B1F" },
                    { name: "Surface", color: Appearance?.colors.colLayer0 ?? "#1C1B1F" },
                    { name: "Error", color: Appearance?.m3colors.m3error ?? "#BA1A1A" },
                    { name: "Layer 1", color: Appearance?.colors.colLayer1 ?? "#E5E1EC" },
                    { name: "Layer 2", color: Appearance?.colors.colLayer2 ?? "#2B2930" },
                    { name: "On Surface", color: Appearance?.m3colors.m3onBackground ?? "#E6E1E5" },
                    { name: "Outline", color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5" },
                    { name: "Tooltip", color: Appearance?.colors.colTooltip ?? "#3C4043" },
                    { name: "Shadow", color: Appearance?.colors.colShadow ?? "#000000" },
                ]

                ColumnLayout {
                    required property var modelData
                    spacing: 2

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 6
                        color: modelData.color
                        border.width: 1
                        border.color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            StyledToolTip { text: `${modelData.name}\n${modelData.color}` }
                        }
                    }
                    StyledText {
                        text: modelData.name
                        font.pixelSize: 9
                        opacity: 0.4
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                        Layout.maximumWidth: parent.width
                    }
                }
            }
        }

        NoticeBox {
            text: "Colors are auto-generated from your wallpaper using Material You. To override, edit the theme JSON or add custom colors in config.json."
            iconName: "auto_awesome"
        }
    }

    // ═══ Fonts ═══
    SettingsCard {
        icon: "font_download"
        title: "Fonts"
        subtitle: "Font families used across the shell"
        configKeys: ["appearance.fonts"]
        expanded: false

        ConfigRow {
            label: "Expressive font"
            sublabel: "Used for stylized headings and accents"
            StyledTextInput {
                text: Config.options?.appearance?.fonts?.expressive ?? "Google Sans Flex"
                onEditingFinished: Config.setNestedValue("appearance.fonts.expressive", text)
                Layout.preferredWidth: 200
            }
        }

        NoticeBox {
            text: "Other fonts (main, numbers, title, monospace, reading) can be changed in config.json under appearance.fonts."
            iconName: "info"
        }
    }

    // ═══ Extra Background Tint ═══
    SettingsCard {
        icon: "tonality"
        title: "Background Tint"
        subtitle: "Apply extra color tinting to layer backgrounds"
        configKeys: ["appearance.extraBackgroundTint"]

        ConfigSwitch {
            label: "Extra background tint"
            sublabel: "Adds a subtle color overlay to surfaces for a warmer feel"
            checked: Config.options?.appearance?.extraBackgroundTint ?? false
            onCheckedChanged: Config.setNestedValue("appearance.extraBackgroundTint", checked)
        }
    }

    // ═══ Global Margin (Bezel) ═══
    SettingsCard {
        icon: "fullscreen"
        title: "Global Margin (Bezel)"
        subtitle: "Gap between all shell elements and screen edges"
        configKeys: ["appearance.bezel"]

        // Visual bezel preview
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 100

            Rectangle {
                anchors.centerIn: parent
                width: 180; height: 80
                radius: 4
                color: "transparent"
                border.width: 1; border.color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"

                // Inner content area (shows effect of bezel)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Config.options?.appearance?.bezel ?? 0
                    radius: Appearance?.rounding.normal ?? 12
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
                    opacity: 0.6

                    StyledText {
                        anchors.centerIn: parent
                        text: `${Config.options?.appearance?.bezel ?? 0}px gap`
                        font.pixelSize: 11; opacity: 0.6
                    }
                }
            }
        }

        ConfigSlider {
            label: "Bezel size"
            sublabel: "Applied to bars, sidebars, and all overlay panels"
            from: 0; to: 24; stepSize: 1
            value: Config.options?.appearance?.bezel ?? 0
            onValueChanged: Config.setNestedValue("appearance.bezel", Math.round(value))
            valueText: `${Math.round(value)}px`
        }
    }

    // ═══ Animations ═══
    SettingsCard {
        icon: "animation"
        title: "Animations"
        subtitle: "Enable/disable and control animation speed"
        configKeys: ["animations"]

        ConfigSwitch {
            label: "Enable animations"
            sublabel: "Disable for better performance on low-end hardware"
            checked: Config.options?.animations?.enable ?? true
            onCheckedChanged: Config.setNestedValue("animations.enable", checked)
        }

        ConfigSlider {
            label: "Animation speed multiplier"
            sublabel: "1.0 = normal, 0.5 = faster, 2.0 = slower"
            from: 0.2; to: 3; stepSize: 0.1
            value: Config.options?.animations?.speed ?? 1
            onValueChanged: Config.setNestedValue("animations.speed", value)
            valueText: `${value.toFixed(1)}x`
        }
    }

    // ═══ Wallpaper Rotation ═══
    SettingsCard {
        icon: "image"
        title: "Wallpaper Rotation"
        subtitle: "Automatically cycle through wallpapers from a directory"
        configKeys: ["background.randomize", "background.wallpaperPath"]

        ConfigSwitch {
            label: "Enable random wallpaper rotation"
            sublabel: "Periodically change wallpaper from a directory"
            checked: Config.options?.background?.randomize?.enable ?? false
            onCheckedChanged: Config.setNestedValue("background.randomize.enable", checked)
        }

        ConfigRow {
            label: "Wallpaper directory"
            sublabel: "Path to folder containing wallpapers (supports ~)"
            StyledTextInput {
                text: Config.options?.background?.randomize?.directory ?? "~/Pictures/Wallpapers"
                onEditingFinished: Config.setNestedValue("background.randomize.directory", text)
                Layout.fillWidth: true
                font.family: Appearance?.font.family.mono ?? "monospace"
            }
        }

        ConfigSlider {
            label: "Rotation interval"
            sublabel: "Time between wallpaper changes"
            from: 30; to: 7200; stepSize: 30
            value: Config.options?.background?.randomize?.interval ?? 300
            onValueChanged: Config.setNestedValue("background.randomize.interval", Math.round(value))
            valueText: {
                const v = Math.round(value)
                if (v >= 3600) return `${(v / 3600).toFixed(1)}h`
                if (v >= 60) return `${Math.round(v / 60)}min`
                return `${v}s`
            }
        }
    }

    // ═══ Wallpaper Transitions ═══
    SettingsCard {
        icon: "swap_horiz"
        title: "Wallpaper Transitions"
        subtitle: "Animation when switching between wallpapers (from inir backdrop)"
        configKeys: ["background.transition"]

        ConfigSwitch {
            label: "Enable wallpaper transitions"
            sublabel: "Smooth crossfade or slide when changing wallpapers"
            checked: Config.options?.background?.transition?.enable ?? true
            onCheckedChanged: Config.setNestedValue("background.transition.enable", checked)
        }

        ConfigRow {
            label: "Transition type"
            sublabel: "Visual style of the wallpaper change"
            ButtonGroup {
                buttons: [
                    GroupButton { label: "Crossfade"; toggled: (Config.options?.background?.transition?.type ?? "crossfade") === "crossfade"; onClicked: Config.setNestedValue("background.transition.type", "crossfade") },
                    GroupButton { label: "Slide"; toggled: (Config.options?.background?.transition?.type ?? "crossfade") === "slideRight"; onClicked: Config.setNestedValue("background.transition.type", "slideRight") },
                    GroupButton { label: "Zoom"; toggled: (Config.options?.background?.transition?.type ?? "crossfade") === "zoom"; onClicked: Config.setNestedValue("background.transition.type", "zoom") },
                    GroupButton { label: "None"; toggled: (Config.options?.background?.transition?.type ?? "crossfade") === "none"; onClicked: Config.setNestedValue("background.transition.type", "none") }
                ]
            }
        }

        ConfigSlider {
            label: "Transition duration"
            sublabel: "How long the crossfade/slide animation takes"
            from: 200; to: 2000; stepSize: 100
            value: Config.options?.background?.transition?.duration ?? 800
            onValueChanged: Config.setNestedValue("background.transition.duration", Math.round(value))
            valueText: Format.formatDuration(value)
        }

        ConfigRow {
            label: "Slide direction"
            sublabel: "Only applies to slide transition type"
            ButtonGroup {
                buttons: [
                    GroupButton { label: "→"; toggled: (Config.options?.background?.transition?.direction ?? "right") === "right"; onClicked: Config.setNestedValue("background.transition.direction", "right") },
                    GroupButton { label: "←"; toggled: (Config.options?.background?.transition?.direction ?? "right") === "left"; onClicked: Config.setNestedValue("background.transition.direction", "left") },
                    GroupButton { label: "↓"; toggled: (Config.options?.background?.transition?.direction ?? "right") === "down"; onClicked: Config.setNestedValue("background.transition.direction", "down") },
                    GroupButton { label: "↑"; toggled: (Config.options?.background?.transition?.direction ?? "right") === "up"; onClicked: Config.setNestedValue("background.transition.direction", "up") }
                ]
            }
        }
    }
}

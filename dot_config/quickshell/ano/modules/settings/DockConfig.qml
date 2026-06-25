import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * Dock settings — elaborate with visual position preview, style selector
 * with live previews, pinned apps management, behavior controls, and sizing.
 */
ColumnLayout {
    id: root
    spacing: 16

    SettingsPageHeader {
        title: "Dock"
        subtitle: "Position, style, sizing, behavior, pinned apps"
        configRoots: ["dock"]
    }

    readonly property string currentPosition: Config.options?.dock?.position ?? "bottom"
    readonly property string currentStyle: Config.options?.dock?.style ?? "pill"
    readonly property bool dockEnabled: Config.options?.dock?.enable ?? true

    // ═══ Enable / Disable ═══
    SettingsCard {
        icon: "space_dashboard"
        title: "Dock"
        subtitle: "Application dock with pinned and running apps"
        configKeys: ["dock.enable"]
        collapsible: false

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialSymbol {
                text: root.dockEnabled ? "check_circle" : "cancel"
                iconSize: 24; fill: 1
                color: root.dockEnabled ? "#81C784" : Appearance?.m3colors.m3error ?? "#BA1A1A"
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 1
                StyledText {
                    text: root.dockEnabled ? "Dock is enabled" : "Dock is disabled"
                    font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                    font.weight: Font.DemiBold
                }
                StyledText {
                    text: root.dockEnabled
                        ? `${root.currentStyle} style • ${root.currentPosition} edge`
                        : "Enable the dock to see apps pinned to your desktop"
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                    opacity: 0.5
                }
            }
            StyledSwitch {
                checked: root.dockEnabled
                onCheckedChanged: Config.setNestedValue("dock.enable", checked)
            }
        }
    }

    // ═══ Position ═══
    SettingsCard {
        icon: "open_with"
        title: "Position"
        subtitle: "Which screen edge the dock appears on"
        configKeys: ["dock.position"]
        visible: root.dockEnabled

        // Visual position preview — screen diagram with dock indicator
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 170

            Rectangle {
                id: dockScreenPreview
                anchors.centerIn: parent
                width: 220; height: 140
                radius: 8
                color: Appearance?.colors.colLayer2 ?? "#2B2930"
                border.width: 1; border.color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"

                StyledText {
                    anchors.centerIn: parent
                    text: "Desktop"
                    font.pixelSize: 11; opacity: 0.2
                }

                // Dock indicator for each possible edge
                Repeater {
                    model: [
                        { edge: "top",    x: 55, y: 3,   w: 110, h: 12 },
                        { edge: "bottom", x: 55, y: 125, w: 110, h: 12 },
                        { edge: "left",   x: 3,  y: 30,  w: 12,  h: 80 },
                        { edge: "right",  x: 205, y: 30, w: 12,  h: 80 }
                    ]

                    Rectangle {
                        required property var modelData
                        x: modelData.x; y: modelData.y
                        width: modelData.w; height: modelData.h
                        radius: root.currentStyle === "pill" ? Math.min(width, height) / 2 : 4
                        color: root.currentPosition === modelData.edge
                            ? Appearance?.colors.colPrimary ?? "#65558F"
                            : "transparent"
                        border.width: 1.5
                        border.color: root.currentPosition === modelData.edge
                            ? Appearance?.colors.colPrimary ?? "#65558F"
                            : Qt.rgba(1, 1, 1, 0.1)
                        opacity: root.currentPosition === modelData.edge ? 1 : 0.25

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on radius { NumberAnimation { duration: 200 } }

                        // Fake "app icons" inside the dock indicator
                        Row {
                            anchors.centerIn: parent
                            spacing: modelData.w > modelData.h ? 3 : 1
                            visible: root.currentPosition === modelData.edge
                            Repeater {
                                model: 4
                                Rectangle {
                                    width: 4; height: 4; radius: 2
                                    color: Appearance?.m3colors.m3onPrimary ?? "white"
                                    opacity: 0.7
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.setNestedValue("dock.position", modelData.edge)
                        }
                    }
                }
            }

            StyledText {
                anchors { bottom: dockScreenPreview.top; horizontalCenter: dockScreenPreview.horizontalCenter; bottomMargin: 4 }
                text: `Position: ${root.currentPosition}`
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                font.weight: Font.DemiBold
                color: Appearance?.colors.colPrimary ?? "#65558F"
            }
        }

        // Quick position buttons
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Repeater {
                model: [
                    { id: "top", label: "Top", icon: "vertical_align_top" },
                    { id: "bottom", label: "Bottom", icon: "vertical_align_bottom" },
                    { id: "left", label: "Left", icon: "align_horizontal_left" },
                    { id: "right", label: "Right", icon: "align_horizontal_right" }
                ]
                GroupButton {
                    required property var modelData
                    label: modelData.label
                    iconName: modelData.icon
                    toggled: root.currentPosition === modelData.id
                    onClicked: Config.setNestedValue("dock.position", modelData.id)
                    Layout.fillWidth: true
                }
            }
        }
    }

    // ═══ Style ═══
    SettingsCard {
        icon: "style"
        title: "Style"
        subtitle: "Visual appearance of the dock"
        configKeys: ["dock.style"]
        visible: root.dockEnabled

        // Style selector with mini-previews
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: [
                    { id: "pill", name: "Pill", desc: "Rounded capsule like a floating bar", icon: "panorama_wide_angle" },
                    { id: "macos", name: "macOS", desc: "Square icons with rounded corners", icon: "grid_view" }
                ]

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 100
                    radius: Appearance?.rounding.normal ?? 12
                    color: root.currentStyle === modelData.id
                        ? Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.15)
                        : Appearance?.colors.colLayer2 ?? "#2B2930"
                    border.width: root.currentStyle === modelData.id ? 2 : 1
                    border.color: root.currentStyle === modelData.id
                        ? Appearance?.colors.colPrimary ?? "#65558F"
                        : Appearance?.colors.colOutlineVariant ?? "#44444488"

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    scale: styleMA.pressed ? 0.95 : (styleMA.containsMouse ? 1.02 : 1)
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 6

                        // Mini dock preview
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 80; height: 20
                            radius: modelData.id === "pill" ? 10 : 6
                            color: Qt.rgba((Appearance?.colors.colPrimary ?? "#65558F").r, (Appearance?.colors.colPrimary ?? "#65558F").g, (Appearance?.colors.colPrimary ?? "#65558F").b, 0.3)

                            Row {
                                anchors.centerIn: parent; spacing: modelData.id === "pill" ? 6 : 3
                                Repeater {
                                    model: 4
                                    Rectangle {
                                        width: 10; height: 10
                                        radius: modelData.id === "pill" ? 5 : 3
                                        color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                                        opacity: 0.5
                                    }
                                }
                            }
                        }

                        StyledText {
                            text: modelData.name
                            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                            font.weight: Font.DemiBold
                            color: root.currentStyle === modelData.id ? Appearance?.colors.colPrimary ?? "#65558F" : Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        StyledText {
                            text: modelData.desc
                            font.pixelSize: 10; opacity: 0.4
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 120
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }
                    }

                    MouseArea {
                        id: styleMA
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Config.setNestedValue("dock.style", modelData.id)
                    }
                }
            }
        }
    }

    // ═══ Sizing ═══
    SettingsCard {
        icon: "straighten"
        title: "Sizing"
        subtitle: "Dock height and icon dimensions"
        configKeys: ["dock.height", "dock.iconSize"]
        visible: root.dockEnabled

        // Live size preview
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: sizePreviewHeight
            Layout.alignment: Qt.AlignHCenter
            color: Appearance?.colors.colLayer2 ?? "#2B2930"
            radius: Appearance?.rounding.small ?? 8

            property real sizePreviewHeight: Math.max(60, (Config.options?.dock?.height ?? 56) + 16)

            Rectangle {
                anchors.centerIn: parent
                width: previewIcons.implicitWidth + 24
                height: Config.options?.dock?.height ?? 56
                radius: root.currentStyle === "pill" ? height / 2 : Appearance?.rounding.normal ?? 12
                color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
                border.width: 1; border.color: Appearance?.colors.colLayer0Border ?? "#44444488"

                Row {
                    id: previewIcons
                    anchors.centerIn: parent; spacing: 6
                    Repeater {
                        model: 5
                        Rectangle {
                            width: Config.options?.dock?.iconSize ?? 40
                            height: Config.options?.dock?.iconSize ?? 40
                            radius: root.currentStyle === "pill" ? width / 2 : Appearance?.rounding.small ?? 8
                            color: Appearance?.colors.colLayer1 ?? "#E5E1EC"

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: ["terminal", "folder", "language", "music_note", "settings"][index]
                                iconSize: parent.width * 0.55
                                opacity: 0.5
                            }
                        }
                    }
                }
            }
        }

        ConfigSlider {
            label: "Dock height"
            sublabel: "Total height of the dock container"
            from: 36; to: 96; stepSize: 2
            value: Config.options?.dock?.height ?? 56
            onValueChanged: Config.setNestedValue("dock.height", Math.round(value))
            valueText: `${Math.round(value)}px`
        }

        ConfigSlider {
            label: "Icon size"
            sublabel: "Size of individual app icons inside the dock"
            from: 24; to: 72; stepSize: 2
            value: Config.options?.dock?.iconSize ?? 40
            onValueChanged: Config.setNestedValue("dock.iconSize", Math.round(value))
            valueText: `${Math.round(value)}px`
        }
    }

    // ═══ Behavior ═══
    SettingsCard {
        icon: "tune"
        title: "Behavior"
        subtitle: "Auto-hide, hover reveal, and desktop-only visibility"
        configKeys: ["dock.pinnedOnStartup", "dock.hoverToReveal", "dock.showOnDesktop"]
        visible: root.dockEnabled

        ConfigSwitch {
            label: "Start pinned"
            sublabel: "Dock is always visible when shell starts (no auto-hide initially)"
            checked: Config.options?.dock?.pinnedOnStartup ?? false
            onCheckedChanged: Config.setNestedValue("dock.pinnedOnStartup", checked)
        }

        ConfigSwitch {
            label: "Hover to reveal"
            sublabel: "Show dock when mouse enters the dock edge area"
            checked: Config.options?.dock?.hoverToReveal ?? true
            onCheckedChanged: Config.setNestedValue("dock.hoverToReveal", checked)
        }

        ConfigSwitch {
            label: "Show on empty desktop"
            sublabel: "Always show dock when no window is focused (like macOS)"
            checked: Config.options?.dock?.showOnDesktop ?? true
            onCheckedChanged: Config.setNestedValue("dock.showOnDesktop", checked)
        }
    }

    // ═══ Pinned Apps ═══
    SettingsCard {
        icon: "push_pin"
        title: "Pinned Apps"
        subtitle: "Apps that always appear in the dock, even when not running"
        configKeys: ["dock.pinnedApps"]

        // Current pinned apps list
        ColumnLayout {
            Layout.fillWidth: true; spacing: 6

            Repeater {
                model: Config.options?.dock?.pinnedApps ?? ["kitty", "nemo", "zen-browser", "brave-browser"]

                Rectangle {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: Appearance?.rounding.small ?? 8
                    color: pinnedAppMA.containsMouse ? Appearance?.colors.colLayer1Hover ?? "#E5DFED" : (index % 2 === 0 ? Qt.rgba(1,1,1,0.02) : "transparent")

                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        spacing: 10

                        // Index badge
                        Rectangle {
                            width: 22; height: 22; radius: 11
                            color: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
                            StyledText {
                                anchors.centerIn: parent
                                text: `${index + 1}`
                                font.pixelSize: 11; font.weight: Font.DemiBold
                                color: Appearance?.m3colors.m3onSecondaryContainer ?? "#1D1B20"
                            }
                        }

                        // App icon
                        IconImage {
                            implicitWidth: 24; implicitHeight: 24
                            source: `image://icon/${modelData}`
                        }

                        // App ID
                        StyledText {
                            text: modelData
                            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                            font.family: Appearance?.font.family.mono ?? "monospace"
                            Layout.fillWidth: true
                        }

                        // Remove button
                        ToolbarButton {
                            iconName: "close"; iconSize: 16
                            toolTipText: "Remove from dock"
                            onClicked: {
                                const apps = [...(Config.options?.dock?.pinnedApps ?? [])]
                                apps.splice(index, 1)
                                Config.setNestedValue("dock.pinnedApps", apps)
                            }
                        }
                    }

                    MouseArea {
                        id: pinnedAppMA
                        anchors.fill: parent; hoverEnabled: true; z: -1
                        acceptedButtons: Qt.NoButton
                    }
                }
            }

            // Empty state
            StyledText {
                visible: (Config.options?.dock?.pinnedApps ?? []).length === 0
                text: "No pinned apps. Add some below."
                font.pixelSize: 13; opacity: 0.4
                Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"; opacity: 0.2 }

        // Add new pinned app
        RowLayout {
            Layout.fillWidth: true; spacing: 8

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 36; radius: 8
                color: Appearance?.colors.colLayer2 ?? "#2B2930"
                StyledTextInput {
                    id: addAppInput
                    anchors { fill: parent; margins: 8 }
                    font.family: Appearance?.font.family.mono ?? "monospace"
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
                    verticalAlignment: TextInput.AlignVCenter
                    StyledText {
                        anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                        text: "App ID (e.g., firefox, code, spotify)"; opacity: 0.3; font.pixelSize: 13
                        visible: !addAppInput.text || addAppInput.text.length === 0
                    }
                    Keys.onReturnPressed: addButton.addApp()
                }
            }

            RippleButtonWithIcon {
                id: addButton
                iconName: "add"
                buttonText: "Add"
                buttonRadius: Appearance?.rounding.small ?? 8
                enabled: addAppInput.text?.length > 0

                function addApp() {
                    const appId = addAppInput.text.trim()
                    if (appId.length === 0) return
                    const apps = [...(Config.options?.dock?.pinnedApps ?? [])]
                    if (!apps.includes(appId)) {
                        apps.push(appId)
                        Config.setNestedValue("dock.pinnedApps", apps)
                    }
                    addAppInput.text = ""
                }

                onClicked: addApp()
            }
        }

        NoticeBox {
            text: "Enter the desktop app ID (usually the .desktop filename without extension). Common examples: kitty, firefox, code, spotify, nautilus, nemo, brave-browser, zen-browser, discord, steam."
            iconName: "help"
        }
    }

    // ═══ Screen Filter ═══
    SettingsCard {
        icon: "monitor"
        title: "Screen Filter"
        subtitle: "Restrict dock to specific monitors"
        configKeys: ["dock.screenList"]
        expanded: false

        ConfigRow {
            label: "Screen whitelist"
            sublabel: "Comma-separated monitor names (empty = all screens)"
            StyledTextInput {
                text: (Config.options?.dock?.screenList ?? []).join(", ")
                font.family: Appearance?.font.family.mono ?? "monospace"
                font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                Layout.fillWidth: true
                onEditingFinished: {
                    const names = text.split(",").map(s => s.trim()).filter(s => s.length > 0)
                    Config.setNestedValue("dock.screenList", names)
                }
            }
        }

        NoticeBox {
            text: "Leave empty to show the dock on all screens. Use monitor names like DP-1, HDMI-A-1, eDP-1. Check your monitor names with 'hyprctl monitors' or 'niri msg outputs'."
            iconName: "info"
        }
    }
}

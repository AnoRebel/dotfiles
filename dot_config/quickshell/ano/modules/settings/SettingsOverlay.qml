import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.settings
import "."
/**
 * Settings overlay — floating panel over the shell.
 * Navigation rail on the left, content pages on the right.
 */
Scope {
    id: root
    property int currentPage: 0

    // Pages — name + icon for the rail, plus the configRoots each page
    // owns (top-level config keys + dotted-path overrides). The roots are
    // forwarded to SettingsRegistry so the Ctrl+K palette can resolve a
    // typed key to the correct page.
    readonly property var pages: [
        { name: "General",    icon: "tune",            configRoots: ["audio", "battery", "time", "notifications", "interactions", "sounds.battery"] },
        { name: "Modules",    icon: "extension",       configRoots: ["enabledPanels", "panelFamily", "familyTransitionAnimation", "osd", "screenCorners", "altSwitcher", "apps", "focusTime", "taskView", "media", "compositor", "hacks", "displayManager", "display.primaryMonitor", "sounds.theme", "bar.morphingPanels"] },
        { name: "Bar",        icon: "dock_to_bottom",  configRoots: ["bar", "bars", "tray"] },
        { name: "Dock",       icon: "space_dashboard", configRoots: ["dock"] },
        { name: "Sidebars",   icon: "view_sidebar",    configRoots: ["sidebar"] },
        { name: "AnoSpot",    icon: "view_compact_alt",configRoots: ["anoSpot"] },
        { name: "Appearance", icon: "palette",         configRoots: ["appearance", "background", "animations"] },
        { name: "Overview",   icon: "overview",        configRoots: ["overview"] },
        { name: "Services",   icon: "cloud",           configRoots: ["ai", "gameMode", "powerProfiles", "network", "vpn", "nightLight", "lyrics", "calendar", "resources", "light", "shell", "weather"] },
        { name: "About",      icon: "info",            configRoots: ["user"] },
    ]

    Component.onCompleted: SettingsRegistry.registerPages(root.pages)

    PanelWindow {
        id: settingsPanel
        visible: GlobalStates.settingsOpen

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }

        // Scrim
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: GlobalStates.settingsOpen ? 0.4 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MouseArea { anchors.fill: parent; onClicked: GlobalStates.settingsOpen = false }
        }

        // Settings card
        Rectangle {
            id: settingsCard
            anchors.centerIn: parent
            width: Math.min(900, parent.width * 0.85)
            height: Math.min(700, parent.height * 0.85)
            radius: Appearance?.rounding.windowRounding ?? 20
            color: Appearance?.m3colors.m3background ?? "#1C1B1F"
            border.width: 1
            border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
            clip: true

            opacity: GlobalStates.settingsOpen ? 1 : 0
            scale: GlobalStates.settingsOpen ? 1 : 0.92
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Navigation rail
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 200
                    color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
                    radius: settingsCard.radius

                    ColumnLayout {
                        anchors { fill: parent; margins: 10 }
                        spacing: 4

                        StyledText {
                            text: "Settings"
                            font.pixelSize: Appearance?.font.pixelSize.huger ?? 22
                            font.weight: Font.Bold
                            Layout.bottomMargin: 10
                        }

                        Repeater {
                            model: root.pages

                            RippleButton {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 40
                                buttonRadius: Appearance?.rounding.small ?? 8
                                toggled: root.currentPage === index
                                colBackgroundToggled: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"

                                contentItem: RowLayout {
                                    anchors { leftMargin: 12; rightMargin: 12 }
                                    spacing: 8
                                    MaterialSymbol {
                                        text: modelData.icon; iconSize: 20
                                        fill: root.currentPage === index ? 1 : 0
                                        color: root.currentPage === index ? Appearance?.m3colors.m3onSecondaryContainer : Appearance?.m3colors.m3onBackground
                                    }
                                    StyledText {
                                        text: modelData.name
                                        font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                                        Layout.fillWidth: true
                                    }
                                }

                                onClicked: root.currentPage = index
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Reload button
                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            buttonRadius: Appearance?.rounding.small ?? 8
                            contentItem: RowLayout {
                                spacing: 6
                                MaterialSymbol { text: "restart_alt"; iconSize: 18 }
                                StyledText { text: "Reload Shell"; font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13 }
                            }
                            onClicked: Quickshell.reload(true)
                        }
                    }
                }

                // Content area
                StyledFlickable {
                    id: pageFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: contentColumn.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: contentColumn
                        width: parent.width
                        anchors.margins: 20

                        Loader {
                            id: pageLoader
                            Layout.fillWidth: true
                            Layout.margins: 20
                            sourceComponent: {
                                switch (root.currentPage) {
                                    case 0: return generalPage
                                    case 1: return modulesPage
                                    case 2: return barPage
                                    case 3: return dockPage
                                    case 4: return sidebarsPage
                                    case 5: return anoSpotPage
                                    case 6: return appearancePage
                                    case 7: return overviewPage
                                    case 8: return servicesPage
                                    case 9: return aboutPage
                                    default: return generalPage
                                }
                            }
                        }
                    }
                }
            }

            // ── Ctrl+K command palette ──────────────────────────────
            // Anchored over the settings card so the scrim covers the
            // whole panel without bleeding outside it.
            SettingsCommandPalette {
                anchors.fill: parent
                currentPage: root.currentPage
                pageCount: root.pages.length
                flickable: pageFlickable
                activePageItem: pageLoader.item
                onPageRequested: idx => root.currentPage = idx
            }
        }

        // Shared keyboard navigation: Up/Down/Tab through pages, Ctrl+1..9
        // jump-to-page, Esc closes. Lives behind the visible card so it
        // doesn't intercept clicks but still receives focus when the panel
        // is open (WlrKeyboardFocus.Exclusive grants the panel the focus
        // chain).
        SettingsKeyHandler {
            anchors.fill: parent
            focus: settingsPanel.visible
            currentPage: root.currentPage
            pageCount: root.pages.length
            onPageRequested: idx => root.currentPage = idx
            onCloseRequested: GlobalStates.settingsOpen = false
        }
    }

    // ═══════════════════════════════════════
    // Page components
    // ═══════════════════════════════════════

    Component {
        id: generalPage
        GeneralConfig {}
    }
    Component {
        id: modulesPage
        ModulesConfig {}
    }
    Component {
        id: barPage
        BarConfig {}
    }
    Component {
        id: dockPage
        DockConfig {}
    }
    Component {
        id: sidebarsPage
        SidebarsConfig {}
    }
    Component {
        id: anoSpotPage
        AnoSpotConfig {}
    }
    Component {
        id: appearancePage
        AppearanceConfig {}
    }
    Component {
        id: overviewPage
        OverviewConfig {}
    }
    Component {
        id: servicesPage
        ServicesConfig {}
    }
    Component {
        id: aboutPage
        AboutPage {}
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { GlobalStates.settingsOpen = !GlobalStates.settingsOpen }
        function open(): void { GlobalStates.settingsOpen = true }
        function close(): void { GlobalStates.settingsOpen = false }
    }
}

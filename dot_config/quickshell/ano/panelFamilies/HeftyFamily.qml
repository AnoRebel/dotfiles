import QtQuick
import Quickshell
import qs.modules.common
import qs.services

/**
 * Hefty Family — Full experience with morphing bar panels.
 * Bars use polygon ShapeCanvas backgrounds that morph into popout detail panels.
 * This is the hefty-hype-inspired mode.
 *
 * Automatically enables bar.morphingPanels when this family is active.
 * All panels from Ano family are included plus TopLayerPanel for morphing.
 */
Scope {
    id: family

    // Enable morphing on activation
    Component.onCompleted: Config.setNestedValue("bar.morphingPanels", true)

    // ─── Core Panels ─────────────────────────────────────────────────────
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/bar/BarManager.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/overview/AnoView.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/notificationPopup/NotificationPopup.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/osd/OSD.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/session/SessionScreen.qml" } }

    // ─── Sidebars ────────────────────────────────────────────────────────
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/sidebarLeft/SidebarLeft.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/sidebarRight/SidebarRight.qml" } }

    // ─── Overlays ────────────────────────────────────────────────────────
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/wallpaperSelector/WallpaperSelector.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/cheatsheet/Cheatsheet.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/settings/SettingsOverlay.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/clipboard/ClipboardManager.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/altSwitcher/AltSwitcher.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/search/Search.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/taskView/TaskView.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/mediaControls/MediaControls.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/controlPanel/ControlPanel.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/weather/WeatherPanel.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/hud/HUD.qml" } }

    // ─── Hefty-specific: Morphing layer ──────────────────────────────────
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/common/widgets/TopLayerPanel.qml" } }

    // ─── Conditional ─────────────────────────────────────────────────────
    LazyLoader { active: Config.ready && (Config.options?.dock?.enable ?? true); component: Loader { source: "root:modules/dock/Dock.qml" } }
    LazyLoader { active: Config.ready && (Config.options?.screenCorners?.enable ?? false); component: Loader { source: "root:modules/screenCorners/ScreenCorners.qml" } }
    LazyLoader { active: Config.ready && (Config.options?.anoSpot?.enable ?? false); component: Loader { source: "root:modules/anoSpot/AnoSpot.qml" } }
    LazyLoader { active: Config.ready && (Config.options?.anoSpot?.enable ?? false); component: Loader { source: "root:modules/anoSpot/AnoSpotStashPopout.qml" } }
    LazyLoader { active: Config.ready && (Config.options?.anoSpot?.enable ?? false); component: Loader { source: "root:modules/anoSpot/AnoSpotWorkspacePreview.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/calendar/CalendarPanel.qml" } }
    LazyLoader { active: Config.ready && (CompositorService.compositor === "niri"); component: Loader { source: "root:modules/lock/LockScreen.qml" } }

    // ─── Transition ──────────────────────────────────────────────────────
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/common/FamilyTransitionOverlay.qml" } }
}

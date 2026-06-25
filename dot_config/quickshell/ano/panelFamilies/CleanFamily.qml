import QtQuick
import Quickshell
import qs.modules.common
import qs.services

/**
 * Clean Family — Focused middle ground.
 * Bar + sidebars + essentials. No dock, no hot corners, no HUD.
 * For distraction-free work.
 */
Scope {
    id: family

    // Disable morphing on activation
    Component.onCompleted: Config.setNestedValue("bar.morphingPanels", false)

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
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/settings/SettingsOverlay.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/clipboard/ClipboardManager.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/search/Search.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/altSwitcher/AltSwitcher.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/cheatsheet/Cheatsheet.qml" } }

    // ─── Conditional ─────────────────────────────────────────────────────
    LazyLoader { active: Config.ready && (Config.options?.anoSpot?.enable ?? false); component: Loader { source: "root:modules/anoSpot/AnoSpot.qml" } }
    LazyLoader { active: Config.ready && (Config.options?.anoSpot?.enable ?? false); component: Loader { source: "root:modules/anoSpot/AnoSpotStashPopout.qml" } }
    LazyLoader { active: Config.ready && (Config.options?.anoSpot?.enable ?? false); component: Loader { source: "root:modules/anoSpot/AnoSpotWorkspacePreview.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/calendar/CalendarPanel.qml" } }
    LazyLoader { active: Config.ready && (CompositorService.compositor === "niri"); component: Loader { source: "root:modules/lock/LockScreen.qml" } }

    // ─── Transition ──────────────────────────────────────────────────────
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/common/FamilyTransitionOverlay.qml" } }
}

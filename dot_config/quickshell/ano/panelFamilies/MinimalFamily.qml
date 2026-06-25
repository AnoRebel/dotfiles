import QtQuick
import Quickshell
import qs.modules.common
import qs.services

/**
 * Minimal Family — Lightweight shell.
 * Bar + essential overlays only. No dock, no sidebars, no HUD, no hot corners.
 * For users who want a minimal setup or use external tools for sidebars/launchers.
 */
Scope {
    id: family

    // ─── Core Panels ─────────────────────────────────────────────────────
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/bar/BarManager.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/overview/AnoView.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/notificationPopup/NotificationPopup.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/osd/OSD.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/session/SessionScreen.qml" } }

    // ─── Essential Overlays ──────────────────────────────────────────────
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/settings/SettingsOverlay.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/search/Search.qml" } }
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/altSwitcher/AltSwitcher.qml" } }

    // ─── Conditional ─────────────────────────────────────────────────────
    LazyLoader { active: Config.ready && (CompositorService.compositor === "niri"); component: Loader { source: "root:modules/lock/LockScreen.qml" } }

    // ─── Transition ──────────────────────────────────────────────────────
    LazyLoader { active: Config.ready; component: Loader { source: "root:modules/common/FamilyTransitionOverlay.qml" } }
}

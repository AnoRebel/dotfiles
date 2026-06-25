pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.modules.common

/**
 * Persists the active power-profiles-daemon profile across reboots.
 *
 * On Config.ready, restores Config.options.powerProfiles.preferredProfile
 * via PowerProfiles.profile. On any subsequent profile change (from any
 * source — control panel, powerprofilesctl, GNOME settings), writes the
 * new value back to the same config key so it survives a restart.
 *
 * Service is dormant if power-profiles-daemon isn't installed (the QS
 * UPower service silently no-ops; PowerProfiles.profile reads stay at
 * their default and writes are ignored).
 *
 * Ported from inir/services/PowerProfilePersistence.qml verbatim except
 * for ano's import paths.
 */
Singleton {
    id: root

    property bool _initialized: false

    function _profileToString(profile): string {
        switch (profile) {
            case PowerProfile.PowerSaver: return "power-saver"
            case PowerProfile.Balanced: return "balanced"
            case PowerProfile.Performance: return "performance"
        }
        return ""
    }

    function _stringToProfile(value: string): int {
        switch (String(value ?? "").trim()) {
            case "power-saver": return PowerProfile.PowerSaver
            case "balanced": return PowerProfile.Balanced
            case "performance": return PowerProfile.Performance
        }
        return -1
    }

    function _applyPreferredProfile(): void {
        if (!Config.ready || root._initialized)
            return

        root._initialized = true

        const restore = Config.options?.powerProfiles?.restoreOnStart ?? true
        const preferred = Config.options?.powerProfiles?.preferredProfile ?? ""

        if (!restore)
            return

        const desired = root._stringToProfile(preferred)
        if (desired < 0)
            return

        if (!PowerProfiles.hasPerformanceProfile && desired === PowerProfile.Performance)
            return

        if (PowerProfiles.profile !== desired) {
            PowerProfiles.profile = desired
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                Qt.callLater(() => root._applyPreferredProfile())
            }
        }
    }

    Connections {
        target: PowerProfiles
        function onProfileChanged() {
            const s = root._profileToString(PowerProfiles.profile)
            if (s.length === 0)
                return
            Config.setNestedValue("powerProfiles.preferredProfile", s)
        }
    }
}

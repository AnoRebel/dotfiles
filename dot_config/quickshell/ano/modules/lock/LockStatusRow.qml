import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "."

/**
 * Status row shown above the password input on the lock screen.
 * Battery percentage (if a battery is present), Wi-Fi state, and a
 * compact clock. Visible only when Config.options.lock.statusRow.enable
 * is true (default false).
 */
RowLayout {
    id: row
    spacing: 14

    visible: Config.options?.lock?.statusRow?.enable ?? false

    // Battery
    RowLayout {
        spacing: 4
        visible: Battery.available

        readonly property int pct: Math.round((Battery.percentage ?? 0) * 100)

        MaterialSymbol {
            text: {
                if (Battery.isCharging) return "battery_charging_full"
                if (parent.pct >= 95) return "battery_full"
                if (parent.pct >= 70) return "battery_5_bar"
                if (parent.pct >= 40) return "battery_3_bar"
                if (parent.pct >= 15) return "battery_2_bar"
                return "battery_alert"
            }
            iconSize: 16
            color: Battery.isCritical ? "#f38ba8" : Battery.isLow ? "#f9e2af" : "white"
        }
        StyledText {
            text: `${parent.pct}%`
            font.pixelSize: 12
            color: "white"
            opacity: 0.85
        }
    }

    // Wi-Fi
    RowLayout {
        spacing: 4
        visible: !!Network && Network.networkName !== undefined
        MaterialSymbol {
            text: Network.wifiStatus === "connected" ? "wifi" : "wifi_off"
            iconSize: 16
            color: "white"
            opacity: Network.wifiStatus === "connected" ? 0.9 : 0.4
        }
        StyledText {
            text: Network.networkName || (Network.wifiStatus === "connected" ? "" : "offline")
            font.pixelSize: 12
            color: "white"
            opacity: 0.8
            visible: text.length > 0
        }
    }

    // Compact clock — supplements (doesn't replace) the big clock above
    StyledText {
        text: DateTime.time
        font.pixelSize: 12
        font.family: Appearance?.font.family.numbers ?? "monospace"
        color: "white"
        opacity: 0.85
    }
}

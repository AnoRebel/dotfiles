import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

RowLayout {
    id: batteryRow
    spacing: 4

    visible: Battery.available && (Config.options?.anoSpot?.showBattery ?? true)

    readonly property int pct: Math.round((Battery.percentage ?? 0) * 100)
    readonly property string symbol: {
        if (Battery.isCharging) return "battery_charging_full";
        if (pct >= 95) return "battery_full";
        if (pct >= 85) return "battery_6_bar";
        if (pct >= 70) return "battery_5_bar";
        if (pct >= 55) return "battery_4_bar";
        if (pct >= 40) return "battery_3_bar";
        if (pct >= 25) return "battery_2_bar";
        if (pct >= 10) return "battery_1_bar";
        return "battery_alert";
    }

    MaterialSymbol {
        text: batteryRow.symbol
        iconSize: 16
        color: {
            if (Battery.isCritical) return "#f38ba8";
            if (Battery.isLow) return "#f9e2af";
            return Appearance?.colors?.colOnLayer0 ?? "#cdd6f4";
        }
    }

    StyledText {
        text: `${batteryRow.pct}%`
        font.pixelSize: 12
        color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
    }
}

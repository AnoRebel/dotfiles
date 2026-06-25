import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

RowLayout {
    spacing: 6

    StyledText {
        text: AnoSpotState.clockWeather.time
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
    }

    StyledText {
        visible: text.length > 0
        text: {
            const t = AnoSpotState.clockWeather.weatherTemp;
            return t ? `· ${t}` : "";
        }
        font.pixelSize: 12
        color: Appearance?.colors?.colOnLayer0Subtle ?? "#a6adc8"
    }
}

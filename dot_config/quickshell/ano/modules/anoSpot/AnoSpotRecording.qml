import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

RowLayout {
    spacing: 4

    Rectangle {
        width: 8
        height: 8
        radius: 4
        color: "#f38ba8"
        SequentialAnimation on opacity {
            running: AnoSpotState.recording.active
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
            NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
        }
    }

    StyledText {
        text: {
            const s = AnoSpotState.recording.elapsedSeconds;
            const mm = String(Math.floor(s / 60)).padStart(2, '0');
            const ss = String(s % 60).padStart(2, '0');
            return `REC ${mm}:${ss}`;
        }
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
    }
}

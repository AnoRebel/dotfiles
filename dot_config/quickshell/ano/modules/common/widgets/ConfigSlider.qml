import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * A settings row with a label, value display, and a StyledSlider.
 */
ColumnLayout {
    id: root
    property string label: ""
    property string sublabel: ""
    property alias value: slider.value
    property alias from: slider.from
    property alias to: slider.to
    property alias stepSize: slider.stepSize
    property string valueText: `${Math.round(slider.value)}`

    spacing: 4
    Layout.fillWidth: true

    RowLayout {
        spacing: 12
        Layout.fillWidth: true
        StyledText {
            text: root.label
            font.pixelSize: Appearance?.font.pixelSize.small ?? 15
            Layout.fillWidth: true
        }
        StyledText {
            text: root.valueText
            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
            opacity: 0.7
        }
    }

    StyledSlider {
        id: slider
        Layout.fillWidth: true
    }

    StyledText {
        text: root.sublabel
        visible: root.sublabel.length > 0
        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
        opacity: 0.6
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
}

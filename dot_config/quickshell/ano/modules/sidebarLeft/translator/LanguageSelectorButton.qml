import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/**
 * Language selector pill button for the translator.
 */
RippleButton {
    id: root
    // `text` is FINAL on Button (RippleButton's ancestor). Use `label`
    // for the displayed string instead.
    property alias label: labelText.text

    implicitHeight: 32
    implicitWidth: label.implicitWidth + 24
    buttonRadius: 16
    colBackground: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
    colBackgroundHover: Appearance?.colors.colSecondaryContainerHover ?? "#DDD3EE"

    contentItem: StyledText {
        id: labelText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
        font.weight: Font.DemiBold
        color: Appearance?.m3colors.m3onSecondaryContainer ?? "#1D1B20"
    }
}

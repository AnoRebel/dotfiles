import qs.modules.common
import QtQuick
import QtQuick.Controls

TextArea {
    id: root
    renderType: Text.NativeRendering
    font {
        hintingPreference: Font.PreferDefaultHinting
        family: Appearance.font.family.main
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        variableAxes: Appearance.font.variableAxes.main
    }
    color: Appearance?.m3colors.m3onBackground ?? "black"
    selectionColor: Appearance?.colors.colPrimary ?? "#65558F"
    selectedTextColor: Appearance?.m3colors.m3onPrimary ?? "white"
    selectByMouse: true
    wrapMode: TextArea.Wrap

    background: Rectangle {
        radius: Appearance?.rounding.small ?? 4
        color: Appearance?.colors.colLayer1 ?? "#E5E1EC"
        border.color: root.activeFocus ? Appearance?.colors.colPrimary : "transparent"
        border.width: root.activeFocus ? 2 : 0
    }
}

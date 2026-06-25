import qs.modules.common
import QtQuick

TextInput {
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
}

import qs.modules.common
import qs.modules.common.widgets
import qs
import QtQuick

/**
 * A small pill button that toggles a sidebar.
 */
RippleButton {
    id: root
    implicitWidth: 36
    implicitHeight: 28
    buttonRadius: Appearance?.rounding.full ?? 9999
    colBackground: "transparent"
    colBackgroundHover: Appearance?.colors.colLayer1Hover ?? "#E5DFED"

    contentItem: MaterialSymbol {
        text: "more_vert"
        iconSize: Appearance?.font.pixelSize.normal ?? 18
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
    }
}

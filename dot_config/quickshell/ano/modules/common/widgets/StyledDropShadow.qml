import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common

/**
 * Styled drop shadow effect with theme-aware defaults.
 */
DropShadow {
    color: Appearance?.colors.colShadow ?? "#40000000"
    horizontalOffset: 0
    verticalOffset: 2
    radius: 8
    samples: 17
    cached: true
}

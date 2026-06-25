import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common

/**
 * Styled blur effect layer for background blur on panels/overlays.
 */
Item {
    id: root
    property alias source: blurEffect.source
    property alias radius: blurEffect.radius
    property real blurOpacity: 0.7
    property color overlayColor: Appearance?.colors.colLayer0 ?? "#1C1B1F"

    FastBlur {
        id: blurEffect
        anchors.fill: parent
        radius: 48
        cached: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(root.overlayColor.r, root.overlayColor.g, root.overlayColor.b, root.blurOpacity)
    }
}

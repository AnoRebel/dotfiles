import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

/**
 * Active window title bar module.
 */
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    Layout.fillWidth: true

    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property string windowTitle: activeToplevel?.title ?? ""
    readonly property string appId: activeToplevel?.appId ?? ""

    RowLayout {
        id: row
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: 6

        StyledText {
            text: root.windowTitle || root.appId || ""
            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
            color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.maximumWidth: 300
        }
    }
}

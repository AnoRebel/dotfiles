import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import qs.modules.bar.modules
import "."

/**
 * BarContent — Fully configurable bar content renderer.
 *
 * Every aspect is driven by config:
 *   - Which modules appear in left/center/right sections
 *   - Spacing between modules (per-section overridable)
 *   - Edge padding (distance from bar edges to first/last module)
 *   - Center group padding and corner radius
 *   - Click actions per section (what happens on left/right click)
 *   - Scroll actions per section (brightness/volume/workspace)
 *   - Separator visibility between sections
 *   - Module alignment within sections
 */
Item {
    id: root
    required property var barConfig
    required property bool isVertical
    required property string edge

    // ═══════════════════════════════════════════════════════════════════
    // Module lists (configurable per-bar or global fallback)
    // ═══════════════════════════════════════════════════════════════════
    readonly property var moduleConfig: barConfig?.modules ?? {
        "left": ["sidebarButton", "activeWindow"],
        "center": ["workspaces"],
        "right": ["clock", "battery", "network", "bluetooth", "tray", "sidebarButton"]
    }
    readonly property var leftModules: moduleConfig.left ?? []
    readonly property var centerModules: moduleConfig.center ?? []
    readonly property var rightModules: moduleConfig.right ?? []

    // ═══════════════════════════════════════════════════════════════════
    // Spacing & Padding (configurable at bar level → global fallback)
    // ═══════════════════════════════════════════════════════════════════
    readonly property real leftSpacing: barConfig?.leftSpacing ?? Config.options?.bar?.layout?.leftSpacing ?? 8
    readonly property real centerSpacing: barConfig?.centerSpacing ?? Config.options?.bar?.layout?.centerSpacing ?? 4
    readonly property real rightSpacing: barConfig?.rightSpacing ?? Config.options?.bar?.layout?.rightSpacing ?? 8
    readonly property real edgePadding: barConfig?.edgePadding ?? Config.options?.bar?.layout?.edgePadding ?? 8
    readonly property real centerGroupPadding: barConfig?.centerGroupPadding ?? Config.options?.bar?.layout?.centerGroupPadding ?? 5
    readonly property real centerGroupRadius: barConfig?.centerGroupRadius ?? Config.options?.bar?.layout?.centerGroupRadius ?? 8
    readonly property bool showCenterBackground: barConfig?.showCenterBackground ?? Config.options?.bar?.layout?.showCenterBackground ?? true
    readonly property bool showSeparators: barConfig?.showSeparators ?? Config.options?.bar?.layout?.showSeparators ?? false

    // ═══════════════════════════════════════════════════════════════════
    // Click Actions (configurable per section)
    // ═══════════════════════════════════════════════════════════════════
    readonly property string leftClickAction: barConfig?.leftClickAction ?? Config.options?.bar?.actions?.leftClick ?? "sidebarLeft"
    readonly property string rightClickAction: barConfig?.rightClickAction ?? Config.options?.bar?.actions?.rightClick ?? "sidebarRight"
    readonly property string centerClickAction: barConfig?.centerClickAction ?? Config.options?.bar?.actions?.centerClick ?? "overview"
    readonly property string scrollLeftAction: barConfig?.scrollLeftAction ?? Config.options?.bar?.actions?.scrollLeft ?? "brightness"
    readonly property string scrollRightAction: barConfig?.scrollRightAction ?? Config.options?.bar?.actions?.scrollRight ?? "volume"
    readonly property string scrollCenterAction: barConfig?.scrollCenterAction ?? Config.options?.bar?.actions?.scrollCenter ?? "workspace"

    function performClickAction(action) {
        switch (action) {
            case "sidebarLeft":  GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen; break
            case "sidebarRight": GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen; break
            case "overview":     GlobalStates.overviewOpen = !GlobalStates.overviewOpen; break
            case "settings":     GlobalStates.settingsOpen = !GlobalStates.settingsOpen; break
            case "hud":          GlobalStates.hudVisible = !GlobalStates.hudVisible; break
            case "session":      GlobalStates.sessionOpen = !GlobalStates.sessionOpen; break
            case "clipboard":    GlobalStates.clipboardOpen = !GlobalStates.clipboardOpen; break
            case "wallpaper":    GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen; break
            case "cheatsheet":   GlobalStates.cheatsheetOpen = !GlobalStates.cheatsheetOpen; break
            case "none": break
            default: break
        }
    }

    function performScrollAction(action, isUp) {
        switch (action) {
            case "brightness":
                const monitor = Brightness.getMonitorForScreen(root.QsWindow.window?.screen)
                if (monitor) monitor.setBrightness(monitor.brightness + (isUp ? 0.05 : -0.05))
                break
            case "volume":
                if (isUp) Audio.incrementVolume(); else Audio.decrementVolume()
                break
            case "workspace":
                if (CompositorService.compositor === "niri") {
                    if (isUp) NiriService.focusWorkspaceUp(); else NiriService.focusWorkspaceDown()
                } else if (CompositorService.compositor === "hyprland") {
                    Quickshell.execDetached(["hyprctl", "dispatch", isUp ? "workspace r-1" : "workspace r+1"])
                }
                break
            case "none": break
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // Separator component
    // ═══════════════════════════════════════════════════════════════════
    component BarSeparator: Rectangle {
        visible: root.showSeparators
        Layout.topMargin: isVertical ? 0 : Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: isVertical ? 0 : Appearance.sizes.baseBarHeight / 3
        Layout.leftMargin: isVertical ? Appearance.sizes.baseBarHeight / 3 : 0
        Layout.rightMargin: isVertical ? Appearance.sizes.baseBarHeight / 3 : 0
        Layout.fillHeight: !isVertical
        Layout.fillWidth: isVertical
        // The filled axis is driven by Layout.fill*; keep both implicits at a
        // concrete 1px (assigning undefined to implicitWidth/Height warns and
        // can zero the dimension in Quickshell 0.3.0).
        implicitWidth: 1
        implicitHeight: 1
        color: Appearance?.colors.colOutlineVariant ?? "#C4C7C5"
        opacity: 0.3
    }

    // ═══════════════════════════════════════════════════════════════════
    // LEFT SECTION
    // ═══════════════════════════════════════════════════════════════════
    MouseArea {
        id: leftSection
        anchors {
            top: parent.top
            left: parent.left
            bottom: isVertical ? undefined : parent.bottom
            right: isVertical ? parent.right : middleSection.left
        }
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onWheel: event => {
            const delta = event.angleDelta.y
            if (delta !== 0) performScrollAction(scrollLeftAction, delta > 0)
        }
        onClicked: event => {
            if (event.button === Qt.LeftButton) performClickAction(leftClickAction)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: isVertical ? 4 : root.edgePadding
            anchors.rightMargin: isVertical ? 4 : 4
            spacing: root.leftSpacing
            layoutDirection: Qt.LeftToRight

            Repeater {
                model: root.leftModules
                Loader {
                    required property string modelData
                    Layout.fillHeight: !isVertical
                    Layout.fillWidth: isVertical
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: BarModuleLoader.getModule(modelData)
                }
            }
            Item { Layout.fillWidth: true }
        }
    }

    // Optional separator
    BarSeparator {
        anchors {
            right: middleSection.left; rightMargin: 4
            top: parent.top; bottom: parent.bottom
        }
        visible: root.showSeparators && !isVertical && leftModules.length > 0 && centerModules.length > 0
    }

    // ═══════════════════════════════════════════════════════════════════
    // CENTER SECTION
    // ═══════════════════════════════════════════════════════════════════
    Item {
        id: middleSection
        // top+bottom already pin the vertical extent; adding verticalCenter
        // on top of them is an over-specified anchor conflict.
        anchors {
            top: isVertical ? leftSection.bottom : parent.top
            bottom: isVertical ? rightSection.top : parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        implicitWidth: isVertical ? parent.width : centerRow.implicitWidth
        implicitHeight: isVertical ? centerRow.implicitHeight : parent.height

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onWheel: event => {
                const delta = event.angleDelta.y
                if (delta !== 0) performScrollAction(scrollCenterAction, delta > 0)
            }
            onClicked: event => {
                if (event.button === Qt.RightButton) performClickAction(centerClickAction)
            }
        }

        RowLayout {
            id: centerRow
            anchors.centerIn: parent
            spacing: root.centerSpacing

            // Center group container
            BarGroup {
                id: centerGroup
                padding: root.centerGroupPadding
                visible: centerModules.length > 0
                vertical: root.isVertical

                showBackground: root.showCenterBackground
                backgroundColor: Appearance?.colors.colLayer1 ?? "#E5E1EC"
                backgroundRadius: root.centerGroupRadius

                Repeater {
                    model: root.centerModules
                    Loader {
                        required property string modelData
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                        sourceComponent: BarModuleLoader.getModule(modelData)
                    }
                }
            }
        }
    }

    // Optional separator
    BarSeparator {
        anchors {
            left: middleSection.right; leftMargin: 4
            top: parent.top; bottom: parent.bottom
        }
        visible: root.showSeparators && !isVertical && centerModules.length > 0 && rightModules.length > 0
    }

    // ═══════════════════════════════════════════════════════════════════
    // RIGHT SECTION
    // ═══════════════════════════════════════════════════════════════════
    MouseArea {
        id: rightSection
        anchors {
            top: isVertical ? undefined : parent.top
            bottom: parent.bottom
            left: isVertical ? parent.left : middleSection.right
            right: parent.right
        }
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onWheel: event => {
            const delta = event.angleDelta.y
            if (delta !== 0) performScrollAction(scrollRightAction, delta > 0)
        }
        onClicked: event => {
            if (event.button === Qt.LeftButton) performClickAction(rightClickAction)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: isVertical ? 4 : 4
            anchors.rightMargin: isVertical ? 4 : root.edgePadding
            spacing: root.rightSpacing
            layoutDirection: Qt.RightToLeft

            Repeater {
                model: root.rightModules
                Loader {
                    required property string modelData
                    Layout.fillHeight: !isVertical
                    Layout.fillWidth: isVertical
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: BarModuleLoader.getModule(modelData)
                }
            }
            Item { Layout.fillWidth: true }
        }
    }
}

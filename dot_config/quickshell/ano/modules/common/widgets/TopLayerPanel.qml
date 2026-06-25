import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets
import "root:modules/common/widgets/shapes/material-shapes.js" as MaterialShapes
import "root:modules/common/widgets/shapes/shapes/corner-rounding.js" as CornerRounding
import "root:modules/common/widgets/shapes/geometry/offset.js" as Offset
import qs.services

/**
 * TopLayerPanel — A single PanelWindow that hosts multiple MorphedPanel
 * children. The combined mask of all panels is used as the window mask,
 * allowing panels to seamlessly morph between each other (e.g., bar → overview).
 *
 * This is the Ano adaptation of hefty-hype's HTopLayerPanel.
 * When a bar widget opens a popout, it morphs the shared background shape
 * to encompass both the bar and the popout, creating a seamless visual.
 *
 * Configurable:
 *   - Config.options.bar.morphingPanels (true/false) — enables this system
 *   - When disabled, falls back to standard BarWindow + separate overlay panels
 *
 * Usage in shell.qml:
 *   LazyLoader {
 *       active: Config.options?.bar?.morphingPanels ?? false
 *       component: TopLayerPanel {}
 *   }
 */
Scope {
    id: root
    readonly property bool morphingEnabled: Config.options?.bar?.morphingPanels ?? false

    Variants {
        model: morphingEnabled ? Quickshell.screens : []

        PanelWindow {
            id: topPanel
            required property var modelData
            screen: modelData
            visible: !GlobalStates.screenLocked

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:topLayer"
            WlrLayershell.layer: WlrLayer.Top
            anchors { top: true; bottom: true; left: true; right: true }

            property int screenW: screen?.width ?? 1920
            property int screenH: screen?.height ?? 1080

            // Collect all child morphed panels
            property var morphedPanels: []

            // Combined mask from all panels
            mask: Region {
                regions: topPanel.morphedPanels.flatMap(p => p.maskItems.map(item => regionComp.createObject(this, { "item": item })))
            }

            Component { id: regionComp; Region {} }

            // The shared background canvas that morphs between shapes
            ShapeCanvas {
                id: backgroundCanvas
                anchors.fill: parent
                color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
                borderWidth: 1 / Math.min(topPanel.screenW, topPanel.screenH)
                borderColor: Appearance?.colors.colLayer0Border ?? "#44444488"
                polygonIsNormalized: false

                // Build combined polygon from all active morphed panels
                roundedPolygon: {
                    let polygon = null
                    for (const panel of topPanel.morphedPanels) {
                        if (panel.backgroundPolygon) {
                            if (!polygon) polygon = panel.backgroundPolygon
                            // Note: true polygon union would require complex boolean ops.
                            // For now, we use the largest panel's polygon when morphing.
                            // The visual effect is that the background shape morphs from
                            // bar → bar+popout → overview as panels change.
                        }
                    }
                    // Fallback to a bar-like rectangle if no panels are active
                    if (!polygon) {
                        const barHeight = Config.options?.bar?.layout?.height ?? 42
                        const barRadius = Config.options?.bar?.layout?.radius ?? 12
                        const bezel = Config.options?.appearance?.bezel ?? 0
                        polygon = MaterialShapes.customPolygon([
                            new MaterialShapes.PointNRound(new Offset.Offset(topPanel.screenW - bezel, bezel + barHeight), new CornerRounding.CornerRounding(barRadius / topPanel.screenW)),
                            new MaterialShapes.PointNRound(new Offset.Offset(bezel, bezel + barHeight), new CornerRounding.CornerRounding(barRadius / topPanel.screenW)),
                            new MaterialShapes.PointNRound(new Offset.Offset(bezel, bezel), new CornerRounding.CornerRounding(barRadius / topPanel.screenW)),
                            new MaterialShapes.PointNRound(new Offset.Offset(topPanel.screenW - bezel, bezel), new CornerRounding.CornerRounding(barRadius / topPanel.screenW)),
                        ], 1, new Offset.Offset(topPanel.screenW / 2, (bezel + barHeight) / 2))
                    }
                    return polygon
                }
            }

            // Reservation info (how much space the bar takes on each edge)
            property int reservedTop: morphedPanels.reduce((acc, p) => Math.max(acc, p.reservedTop), 0)
            property int reservedBottom: morphedPanels.reduce((acc, p) => Math.max(acc, p.reservedBottom), 0)
            property int reservedLeft: morphedPanels.reduce((acc, p) => Math.max(acc, p.reservedLeft), 0)
            property int reservedRight: morphedPanels.reduce((acc, p) => Math.max(acc, p.reservedRight), 0)
        }
    }
}

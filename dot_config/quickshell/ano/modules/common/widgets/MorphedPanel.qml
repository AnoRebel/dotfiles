import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import "root:modules/common/widgets/shapes/material-shapes.js" as MaterialShapes
import "root:modules/common/widgets/shapes/shapes/corner-rounding.js" as CornerRounding
import "root:modules/common/widgets/shapes/geometry/offset.js" as Offset
import qs.services

/**
 * MorphedPanel — a panel whose background shape is defined by a polygon
 * that can morph between different shapes (e.g., bar → overview → sidebar).
 *
 * This is the core of the hefty-hype morphing system, adapted for Ano.
 *
 * The panel renders as a PanelWindow with a ShapeCanvas background.
 * When the shape polygon changes, the ShapeCanvas automatically morphs
 * between the old and new shapes using cubic bezier interpolation.
 *
 * Properties:
 *   - backgroundPolygon: The target RoundedPolygon shape to morph to
 *   - shown: Whether the panel content is visible
 *   - reservedTop/Bottom/Left/Right: Space reserved by this panel on each edge
 *   - attachedMaskItems: Additional items that should be part of the click-through mask
 *
 * Usage:
 *   MorphedPanel {
 *       backgroundPolygon: MaterialShapes.customPolygon(points, reps, center)
 *       // ... child content positioned within the polygon bounds
 *   }
 */
Item {
    id: root

    // Fed by parent (typically TopLayerPanel)
    property int screenWidth: QsWindow?.window?.width ?? 1920
    property int screenHeight: QsWindow?.window?.height ?? 1080

    // Signals & loading
    signal requestFocus()
    signal dismissed()
    signal focusGrabDismissed()
    property bool load: true
    property bool shown: true

    // Reserved areas (how much space this panel occupies on each edge)
    property int reservedTop: 0
    property int reservedBottom: 0
    property int reservedLeft: 0
    property int reservedRight: 0

    // Main polygon shape
    property var backgroundPolygon

    // Mask system for click-through
    property list<Item> baseMaskItems: [root]
    property list<Item> attachedMaskItems: []
    property list<Item> maskItems: [...baseMaskItems, ...attachedMaskItems]

    function addAttachedMaskItem(item) {
        if (root.attachedMaskItems.includes(item)) return
        root.attachedMaskItems.push(item)
    }

    function removeAttachedMaskItem(item) {
        root.attachedMaskItems = root.attachedMaskItems.filter(i => i !== item)
    }
}

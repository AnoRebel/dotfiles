import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.shapes
import "root:modules/common/widgets/shapes/material-shapes.js" as MaterialShapes
import "root:modules/common/widgets/shapes/shapes/corner-rounding.js" as CornerRounding
import "root:modules/common/widgets/shapes/geometry/offset.js" as Offset
import qs.services

/**
 * BarModulePopout — Unified wrapper for bar module detail panels.
 * Automatically chooses between two rendering modes:
 *
 * 1. Standard mode (default): Uses StyledPopup (PopupWindow anchored to bar)
 * 2. Morph mode (when bar has morphingPanel: true): Uses BarWidgetPopout
 *    with ShapeCanvas polygon morphing
 *
 * Bar modules simply declare their popup content inside this component,
 * and the rendering mode is handled automatically based on bar config.
 *
 * Usage:
 *   // In a bar module:
 *   BarModulePopout {
 *       shown: root.hovered
 *       popupWidth: 260; popupHeight: 200
 *
 *       ColumnLayout {
 *           // ... popup content
 *       }
 *   }
 */
Item {
    id: root
    property bool shown: false
    property real popupWidth: 280
    property real popupHeight: 200

    default property alias content: contentContainer.data

    // Detect if this bar uses morphing panels
    readonly property bool useMorphing: {
        // Walk up to find the barConfig
        let parent = root.parent
        while (parent) {
            if (parent.hasOwnProperty("barConfig") && parent.barConfig?.morphingPanel)
                return true
            parent = parent.parent
        }
        return false
    }

    // Content container (children go here regardless of mode)
    Item {
        id: contentContainer
        visible: false // Hidden — content is reparented by the active mode
    }

    // ═══ Mode 1: Standard StyledPopup ════════════════════════════════════
    Loader {
        id: standardLoader
        active: !root.useMorphing
        anchors.fill: parent

        sourceComponent: StyledPopup {
            id: styledPopup
            shown: root.shown
            popupWidth: root.popupWidth
            popupHeight: root.popupHeight

            // Route the caller's content into StyledPopup's stable content
            // sink (contentParent). StyledPopup then moves it into its inner
            // card. Targeting a guessed children[0] previously dropped the
            // content into the hidden parking Item, so the popup was empty.
            Binding {
                target: contentContainer
                property: "parent"
                value: styledPopup.contentParent
                when: standardLoader.active && standardLoader.item
            }
        }
    }

    // ═══ Mode 2: Morphing BarWidgetPopout ═════════════════════════════════
    Loader {
        id: morphLoader
        active: root.useMorphing
        anchors.fill: parent

        sourceComponent: Item {
            id: morphContainer

            property bool showPopout: root.shown
            property bool wasShown: false

            // Dynamic morph duration (from ilyamiro):
            //   - Fast initial open: 250ms
            //   - Smooth morph between panels: 500ms
            //   - Fast close: 250ms
            property int morphDuration: !wasShown && showPopout ? 250  // fast open
                : wasShown && !showPopout ? 250                        // fast close
                : 500                                                  // smooth morph

            onShowPopoutChanged: {
                Qt.callLater(() => { morphContainer.wasShown = morphContainer.showPopout })
            }

            // Shape background
            ShapeCanvas {
                id: morphBg
                visible: morphContainer.showPopout
                z: 100

                x: -(root.popupWidth - (root.parent?.width ?? 50)) / 2
                y: (root.parent?.height ?? 40) + 8
                width: root.popupWidth
                height: root.popupHeight

                color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
                borderWidth: 0.002
                borderColor: Appearance?.colors.colLayer0Border ?? "#44444488"

                roundedPolygon: {
                    const r = (Appearance?.rounding?.normal ?? 12) / Math.max(root.popupWidth, root.popupHeight)
                    return MaterialShapes.customPolygon([
                        new MaterialShapes.PointNRound(new Offset.Offset(1, 1), new CornerRounding.CornerRounding(r)),
                        new MaterialShapes.PointNRound(new Offset.Offset(0, 1), new CornerRounding.CornerRounding(r)),
                        new MaterialShapes.PointNRound(new Offset.Offset(0, 0), new CornerRounding.CornerRounding(r)),
                        new MaterialShapes.PointNRound(new Offset.Offset(1, 0), new CornerRounding.CornerRounding(r)),
                    ], 1)
                }

                // Dynamic morph animation — speed adapts to context
                animation: NumberAnimation {
                    duration: morphContainer.morphDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.42, 1.67, 0.21, 0.90, 1, 1] // M3 Expressive fast spatial
                }

                opacity: morphContainer.showPopout ? 1 : 0
                scale: morphContainer.showPopout ? 1 : 0.85
                transformOrigin: Item.Top

                // Opacity fade matches morph speed (200ms fast, 300ms smooth)
                Behavior on opacity { NumberAnimation { duration: morphContainer.morphDuration === 500 ? 300 : 200; easing.type: Easing.InOutSine } }
                Behavior on scale { NumberAnimation { duration: morphContainer.morphDuration; easing.type: Easing.OutCubic } }

                // Content inside morph shape
                Item {
                    id: morphContentArea
                    anchors { fill: parent; margins: 12 }
                    visible: morphContainer.showPopout
                    opacity: morphContainer.showPopout ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }

            // Reparent content into morph area
            Binding {
                target: contentContainer
                property: "parent"
                value: morphContentArea
                when: morphLoader.active
            }
            Binding {
                target: contentContainer
                property: "visible"
                value: true
                when: morphLoader.active && morphContainer.showPopout
            }
        }
    }
}

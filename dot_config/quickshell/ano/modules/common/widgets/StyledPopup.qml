import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common

/**
 * Styled popup window anchored to a parent item. Used for bar module
 * hover popups (battery details, network list, etc.)
 * Provides consistent styling: rounded card, shadow, enter/exit animation.
 */
Item {
    id: root
    property bool shown: false
    property real popupWidth: 300
    property real popupHeight: 400
    property real popupMargin: 8
    property var anchorEdges: Edges.Top
    property var anchorGravity: Edges.Top

    // The popup body. Callers do `StyledPopup { Rectangle {...} }` and
    // the children land inside the inner contentContainer. The alias
    // can't target an id inside a Loader.sourceComponent (sourceComponent
    // contents aren't visible at compile time), so we use the default
    // property "data" of an inline Item that lives at root scope, and the
    // popup window picks it up as a child when it instantiates.
    default property alias content: contentHolder.data
    // Stable handle so callers that reparent an existing item (rather than
    // declaring children inline) have a deterministic target instead of
    // guessing a child index.
    property alias contentParent: contentHolder

    Item {
        id: contentHolder
        visible: false   // never rendered here, just a parking spot
    }

    // Keep the popup window alive for the lifetime of this component instead
    // of destroying it on every hide. A Loader tied to `shown` tore the
    // window (and the reparented content) down mid-animation, so the popup
    // flashed empty and vanished. Visibility is toggled on the window itself.
    Loader {
        id: popupLoader
        active: true
        anchors.fill: parent

        sourceComponent: PopupWindow {
            id: popupWin
            visible: root.shown
            color: "transparent"
            implicitWidth: root.popupWidth + root.popupMargin * 2
            implicitHeight: root.popupHeight + root.popupMargin * 2

            anchor {
                window: root.QsWindow.window
                item: root.parent
                edges: root.anchorEdges
                gravity: root.anchorGravity
            }

            mask: Region { item: cardBg }

            Item {
                anchors { fill: parent; margins: root.popupMargin }

                // Shadow
                Rectangle {
                    id: shadowRect
                    anchors.fill: parent; anchors.margins: -4
                    radius: cardBg.radius + 4
                    color: "#44000000"
                    z: -1
                }

                // Card
                Rectangle {
                    id: cardBg
                    anchors.fill: parent
                    radius: Appearance?.rounding.normal ?? 12
                    color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
                    border.width: 1
                    border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
                    clip: true

                    // Reparent the caller's content into here when the
                    // popup window is alive. Children of contentHolder
                    // (set via the default property) get moved in.
                    Item {
                        id: contentContainer
                        anchors { fill: parent; margins: 12 }

                        function pullContent() {
                            for (let i = contentHolder.data.length - 1; i >= 0; --i) {
                                const child = contentHolder.data[i];
                                // Only visual items (QQuickItem) expose a `parent`.
                                // Non-visual children (Connections, Timer, models)
                                // return undefined and are left in place.
                                if (child && child.parent !== undefined)
                                    child.parent = contentContainer;
                            }
                        }

                        // Reactive, not one-shot: callers may reparent content
                        // into contentHolder AFTER this window is built (e.g.
                        // BarModulePopout binds it post-load), so re-pull
                        // whenever contentHolder's children change.
                        Component.onCompleted: pullContent()
                        Connections {
                            target: contentHolder
                            function onChildrenChanged() { contentContainer.pullContent() }
                        }
                    }
                }

                // Entry animation
                opacity: root.shown ? 1 : 0
                scale: root.shown ? 1 : 0.92
                transformOrigin: Item.Bottom

                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }
    }
}

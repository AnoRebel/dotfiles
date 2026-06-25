pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common

/**
 * Base component for staggered entrance animations.
 * Has a `progress` property (0→1) that child components react to.
 * Used by ChoreographerGridLayout to orchestrate sequential reveals.
 * From end-4 hefty-hype.
 */
Item {
    id: root
    property real progress: 0
    default property Item child
    implicitWidth: child?.implicitWidth ?? 0
    implicitHeight: child?.implicitHeight ?? 0
    children: child ? [child] : []
    visible: progress > 0.01

    property var animation: Appearance?.animation.elementMoveSmall?.numberAnimation?.createObject(this) ?? NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    Behavior on progress { animation: root.animation }
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

/**
 * Staggered entrance animation container.
 * Children must be AbstractChoreographable (or FlyFadeEnterChoreographable).
 * When `shown` becomes true, children reveal one by one with `interval` delay.
 * When `shown` becomes false, all hide at once.
 *
 * From end-4 hefty-hype ChoreographerGridLayout.
 *
 * Usage:
 *   ChoreographerLayout {
 *       shown: someCondition
 *       totalDuration: 400
 *       FlyFadeEnterChoreographable { Rectangle { ... } }
 *       FlyFadeEnterChoreographable { Rectangle { ... } }
 *       FlyFadeEnterChoreographable { Rectangle { ... } }
 *   }
 */
ColumnLayout {
    id: root

    property real totalDuration: 250
    property real interval: count > 0 ? totalDuration / count : 50
    property bool vertical: true

    default property list<QtObject> choreographableChildren
    readonly property int count: choreographableChildren.length
    children: choreographableChildren

    property bool shown: false
    onShownChanged: {
        if (!shown) {
            // Hide all at once
            for (var i = 0; i < count; i++) {
                if (choreographableChildren[i].hasOwnProperty("progress"))
                    choreographableChildren[i].progress = 0
            }
        }
        choreographIndex = 0
    }

    property int choreographIndex: count

    Timer {
        id: choreographTimer
        interval: root.interval
        property bool step: root.shown && root.choreographIndex < root.count
        running: step
        repeat: step
        onTriggered: {
            const idx = root.choreographIndex
            if (idx < root.count && root.choreographableChildren[idx].hasOwnProperty("progress"))
                root.choreographableChildren[idx].progress = 1
            root.choreographIndex++
        }
    }
}

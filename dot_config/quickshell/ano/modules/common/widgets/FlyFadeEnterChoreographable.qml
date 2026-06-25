pragma ComponentBehavior: Bound
import QtQuick

/**
 * Staggered entrance animation: child slides in + fades.
 * Set `vertical` for up/down, `reverseDirection` to flip.
 * From end-4 hefty-hype.
 *
 * Usage:
 *   FlyFadeEnterChoreographable {
 *       progress: shown ? 1 : 0
 *       Rectangle { width: 100; height: 50; color: "red" }
 *   }
 */
AbstractChoreographable {
    id: root
    progress: 0
    property bool vertical: true
    property bool reverseDirection: false
    property real distance: 15
    readonly property real directionMultiplier: reverseDirection ? -1 : 1

    Component.onCompleted: syncProgress()
    onProgressChanged: syncProgress()

    function syncProgress() {
        if (!root.child) return
        const offset = distance * (1 - progress) * directionMultiplier
        root.child.opacity = progress
        if (vertical) root.child.y = offset
        else root.child.x = offset
    }
}

import qs.modules.common
import QtQuick

/**
 * Convenience NumberAnimation using the shell's standard animation curve.
 * Usage: Behavior on x { Anim {} }
 */
NumberAnimation {
    duration: Appearance?.animation.elementMoveFast.duration ?? 200
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance?.animation.elementMoveFast.bezierCurve ?? [0.2, 0, 0, 1, 1, 1]
}

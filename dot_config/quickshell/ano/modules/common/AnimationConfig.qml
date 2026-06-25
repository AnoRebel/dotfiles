pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common

// AnimationConfig: Centralized animation helper and extension point.
// Modules should use these factory functions to create animations that
// respect the global speed multiplier and can be overridden by plugins.
//
// Extension point: A C++ plugin could replace this singleton to provide
// custom animation backends (e.g., Lottie, springs, physics-based).
Singleton {
    id: root

    // Whether animations are globally enabled
    readonly property bool enabled: Config?.options.animations.enabled ?? true

    // Global speed multiplier (1.0 = normal, 0.5 = double speed, 2.0 = half speed)
    readonly property real speedMultiplier: enabled ? (Config?.options.animations.speedMultiplier ?? 1.0) : 0.001

    // Convenience: apply speed multiplier to a duration
    function scaledDuration(baseDuration) {
        return Math.max(1, baseDuration * speedMultiplier);
    }

    // Create a standard Behavior for number properties
    // Usage: Behavior on opacity { animation: AnimationConfig.fastNumberAnimation() }
    function fastNumberAnimation() {
        return Appearance.animation.elementMoveFast.numberAnimation;
    }

    function standardNumberAnimation() {
        return Appearance.animation.elementMove.numberAnimation;
    }

    function enterNumberAnimation() {
        return Appearance.animation.elementMoveEnter.numberAnimation;
    }

    function exitNumberAnimation() {
        return Appearance.animation.elementMoveExit.numberAnimation;
    }

    function resizeNumberAnimation() {
        return Appearance.animation.elementResize.numberAnimation;
    }

    function fastColorAnimation() {
        return Appearance.animation.elementMoveFast.colorAnimation;
    }
}

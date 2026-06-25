import QtQuick
import qs.modules.common

/**
 * WallpaperCrossfader — crossfade transition between wallpaper images.
 * When the source changes, the old image fades out while the new one fades in.
 *
 * Supports configurable transition types:
 *   - "crossfade" — simultaneous fade out/in (default)
 *   - "slideRight" / "slideLeft" — slide transition with fade
 *   - "slideUp" / "slideDown" — vertical slide transition
 *   - "zoom" — zoom in/out with fade
 *   - "none" — instant switch
 *
 * Ported from inir backdrop transitions.
 */
Item {
    id: root
    property url source: ""
    property size sourceSize: Qt.size(1920, 1080)
    property bool enableTransitions: Config.options?.background?.transition?.enable ?? true
    property int transitionBaseDuration: Config.options?.background?.transition?.duration ?? 800
    property string transitionType: Config.options?.background?.transition?.type ?? "crossfade"
    property string transitionDirection: Config.options?.background?.transition?.direction ?? "right"

    // Internal double-buffer
    property bool _showA: true
    property url _prevSource: ""

    onSourceChanged: {
        if (!enableTransitions || transitionType === "none" || source === _prevSource) {
            // Instant switch
            if (_showA) { imageA.source = root.source }
            else { imageB.source = root.source }
            _prevSource = source
            return
        }

        // Start transition: load new image into inactive buffer, then swap
        if (_showA) {
            imageB.source = root.source
            imageB.opacity = 0
            imageB.scale = transitionType === "zoom" ? 1.05 : 1
            imageB.x = transitionType === "slideRight" ? root.width : transitionType === "slideLeft" ? -root.width : 0
            imageB.y = transitionType === "slideDown" ? root.height : transitionType === "slideUp" ? -root.height : 0
        } else {
            imageA.source = root.source
            imageA.opacity = 0
            imageA.scale = transitionType === "zoom" ? 1.05 : 1
            imageA.x = transitionType === "slideRight" ? root.width : transitionType === "slideLeft" ? -root.width : 0
            imageA.y = transitionType === "slideDown" ? root.height : transitionType === "slideUp" ? -root.height : 0
        }

        _showA = !_showA
        _prevSource = source
    }

    // Image A
    Image {
        id: imageA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true
        sourceSize: root.sourceSize
        opacity: root._showA ? 1 : 0
        scale: 1; x: 0; y: 0

        Behavior on opacity {
            enabled: root.enableTransitions && root.transitionType !== "none"
            NumberAnimation { duration: root.transitionBaseDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on scale {
            enabled: root.enableTransitions && root.transitionType === "zoom"
            NumberAnimation { duration: root.transitionBaseDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on x {
            enabled: root.enableTransitions && (root.transitionType === "slideRight" || root.transitionType === "slideLeft")
            NumberAnimation { duration: root.transitionBaseDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on y {
            enabled: root.enableTransitions && (root.transitionType === "slideDown" || root.transitionType === "slideUp")
            NumberAnimation { duration: root.transitionBaseDuration; easing.type: Easing.InOutCubic }
        }
    }

    // Image B (double buffer)
    Image {
        id: imageB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true
        sourceSize: root.sourceSize
        opacity: root._showA ? 0 : 1
        scale: 1; x: 0; y: 0

        Behavior on opacity {
            enabled: root.enableTransitions && root.transitionType !== "none"
            NumberAnimation { duration: root.transitionBaseDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on scale {
            enabled: root.enableTransitions && root.transitionType === "zoom"
            NumberAnimation { duration: root.transitionBaseDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on x {
            enabled: root.enableTransitions && (root.transitionType === "slideRight" || root.transitionType === "slideLeft")
            NumberAnimation { duration: root.transitionBaseDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on y {
            enabled: root.enableTransitions && (root.transitionType === "slideDown" || root.transitionType === "slideUp")
            NumberAnimation { duration: root.transitionBaseDuration; easing.type: Easing.InOutCubic }
        }
    }
}

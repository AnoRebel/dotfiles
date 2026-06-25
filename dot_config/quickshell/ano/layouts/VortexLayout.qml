pragma Singleton
import Quickshell

Singleton {
    function doLayout(windowList, outerWidth, outerHeight) {
        var N = windowList.length; if (N === 0) return []
        var contentScale = 0.90, useW = outerWidth * contentScale, useH = outerHeight * contentScale
        var offX = (outerWidth - useW) / 2, offY = (outerHeight - useH) / 2
        var centerX = offX + useW / 2, centerY = offY + useH / 2
        var maxRadius = Math.min(useW, useH) / 2, goldenAngle = Math.PI * (3 - Math.sqrt(5))
        var minScale = 0.4, baseSizeFactor = 0.5
        var result = []

        for (var i = 0; i < N; i++) {
            var item = windowList[i], t = i / Math.max(1, N - 1); if (N === 1) t = 0
            var currentRadius = (maxRadius * 0.85) * Math.sqrt(t), currentAngle = i * goldenAngle
            var scale = 1.0 - (t * (1.0 - minScale)), tilt = Math.cos(currentAngle) * 8
            var cx = centerX + currentRadius * Math.cos(currentAngle), cy = centerY + currentRadius * Math.sin(currentAngle)
            var w0 = (item.width > 0) ? item.width : 100, h0 = (item.height > 0) ? item.height : 100
            var baseBoxSize = Math.min(useW, useH) * baseSizeFactor, aspect = w0 / h0
            var thumbW, thumbH
            if (aspect > 1) { thumbW = baseBoxSize * scale; thumbH = thumbW / aspect }
            else { thumbH = baseBoxSize * scale; thumbW = thumbH * aspect }
            result.push({ win: item.win, x: cx - thumbW / 2, y: cy - thumbH / 2, width: thumbW, height: thumbH, rotation: tilt, zIndex: N - i })
        }
        return result
    }
}

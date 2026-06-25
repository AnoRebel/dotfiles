pragma Singleton
import Quickshell

Singleton {
    function doLayout(windowList, outerWidth, outerHeight) {
        var N = windowList.length; if (N === 0) return []
        var gap = Math.max(10, outerWidth * 0.01)
        var useW = outerWidth * 0.9, useH = outerHeight * 0.9
        var offX = (outerWidth - useW) / 2, offY = (outerHeight - useH) / 2
        var cols = Math.ceil(Math.sqrt(N * 1.5)), rows = Math.ceil(N / cols)
        var cellW = (useW - (cols * gap)) / (cols + 0.5), cellH = (useH - (rows * gap)) / rows
        var contentH = rows * cellH + (rows - 1) * gap, startY = offY + (useH - contentH) / 2
        var result = []

        for (var i = 0; i < N; i++) {
            var item = windowList[i], r = Math.floor(i / cols), c = i % cols
            var staggerOffset = (r % 2 === 1) ? (cellW / 2) : 0
            var cellX = staggerOffset + c * (cellW + gap), cellY = r * (cellH + gap)
            var w0 = (item.width > 0) ? item.width : 100, h0 = (item.height > 0) ? item.height : 100
            var sc = Math.min(cellW / w0, cellH / h0)
            result.push({ win: item.win, x: offX + cellX + (cellW - w0 * sc) / 2, y: startY + cellY + (cellH - h0 * sc) / 2, width: w0 * sc, height: h0 * sc })
        }
        return result
    }
}

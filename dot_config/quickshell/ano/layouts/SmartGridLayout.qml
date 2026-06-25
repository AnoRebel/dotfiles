pragma Singleton
import Quickshell

Singleton {
    function doLayout(windowList, outerWidth, outerHeight) {
        var N = windowList.length
        if (N === 0 || outerWidth <= 0 || outerHeight <= 0) return []

        var gap = Math.min(outerWidth * 0.03, outerHeight * 0.03)
        var contentScale = 0.9
        var usableW = outerWidth * contentScale
        var usableH = outerHeight * contentScale
        var TARGET_ASPECT = 16.0 / 9.0
        var bestCols = 1, bestRows = 1, bestScale = 0

        for (var cols = 1; cols <= N; cols++) {
            var rows = Math.ceil(N / cols)
            var availW = usableW - gap * (cols - 1)
            var availH = usableH - gap * (rows - 1)
            if (availW <= 0 || availH <= 0) continue
            var cellW = availW / cols, cellH = availH / rows
            var currentScale = Math.min(cellW / TARGET_ASPECT, cellH / 1.0)
            if (currentScale > bestScale) { bestScale = currentScale; bestCols = cols; bestRows = rows }
        }

        var finalAvailW = usableW - gap * (bestCols - 1)
        var finalAvailH = usableH - gap * (bestRows - 1)
        var maxCellW = finalAvailW / bestCols, maxCellH = finalAvailH / bestRows
        var totalGridContentH = bestRows * maxCellH + (bestRows - 1) * gap
        var startOffsetY = (outerHeight - totalGridContentH) / 2
        var result = []

        for (var r = 0; r < bestRows; r++) {
            var rowItems = [], startIndex = r * bestCols
            var endIndex = Math.min(startIndex + bestCols, N)
            if (startIndex >= N) break
            var totalRowContentWidth = 0
            for (var i = startIndex; i < endIndex; i++) {
                var item = windowList[i]
                var w0 = (item.width > 0) ? item.width : 100, h0 = (item.height > 0) ? item.height : 100
                var scale = Math.min(maxCellW / w0, maxCellH / h0)
                rowItems.push({ originalItem: item, width: w0 * scale, height: h0 * scale })
                totalRowContentWidth += w0 * scale
            }
            if (rowItems.length > 1) totalRowContentWidth += (rowItems.length - 1) * gap
            var currentX = (outerWidth - totalRowContentWidth) / 2
            var cellAbsY = startOffsetY + r * (maxCellH + gap)
            for (var k = 0; k < rowItems.length; k++) {
                var rItem = rowItems[k]
                result.push({ win: rItem.originalItem.win, x: currentX, y: cellAbsY + (maxCellH - rItem.height) / 2, width: rItem.width, height: rItem.height })
                currentX += rItem.width + gap
            }
        }
        return result
    }
}

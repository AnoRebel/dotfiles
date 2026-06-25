pragma Singleton
import Quickshell

Singleton {
    function doLayout(windowList, outerWidth, outerHeight) {
        var N = windowList.length; if (N === 0) return []
        var rawGap = Math.min(outerWidth * 0.08, outerHeight * 0.08)
        var gap = Math.max(12, Math.min(32, rawGap))
        var contentScale = 0.90, useW = outerWidth * contentScale, useH = outerHeight * contentScale
        var bestCols = N

        for (var cols = 1; cols <= N; cols++) {
            var tryColWidth = (useW - (cols - 1) * gap) / cols, tryColHeights = new Array(cols).fill(0)
            for (var i = 0; i < N; i++) {
                var item = windowList[i], minH = Math.min.apply(null, tryColHeights), colIdx = tryColHeights.indexOf(minH)
                var w0 = (item.width > 0) ? item.width : 100, h0 = (item.height > 0) ? item.height : 100
                tryColHeights[colIdx] += (h0 * (tryColWidth / w0)) + gap
            }
            var currentMaxH = Math.max.apply(null, tryColHeights); if (currentMaxH > 0) currentMaxH -= gap
            if (currentMaxH <= useH) { bestCols = cols; break }
        }

        var rawColWidth = (useW - (bestCols - 1) * gap) / bestCols
        var clampHeights = new Array(bestCols).fill(0)
        for (var j = 0; j < N; j++) {
            var it = windowList[j], mH = Math.min.apply(null, clampHeights), cId = clampHeights.indexOf(mH)
            var wR = (it.width > 0) ? it.width : 100, hR = (it.height > 0) ? it.height : 100
            clampHeights[cId] += (hR * (rawColWidth / wR)) + gap
        }
        var tallestCol = Math.max.apply(null, clampHeights); if (tallestCol > 0) tallestCol -= gap
        var maxOverflowRatio = tallestCol > useH ? useH / tallestCol : 1.0
        var finalColWidth = rawColWidth * maxOverflowRatio
        var finalGridW = (finalColWidth * bestCols) + (gap * (bestCols - 1))
        var finalOffX = (outerWidth - finalGridW) / 2

        var colHeights = new Array(bestCols).fill(0), result = []
        for (var k = 0; k < N; k++) {
            var itemK = windowList[k], minH2 = Math.min.apply(null, colHeights), cIdx = colHeights.indexOf(minH2)
            var wO = (itemK.width > 0) ? itemK.width : 100, hO = (itemK.height > 0) ? itemK.height : 100
            var s = finalColWidth / wO, tH = hO * s
            result.push({ win: itemK.win, x: finalOffX + cIdx * (finalColWidth + gap), y: colHeights[cIdx], width: finalColWidth, height: tH })
            colHeights[cIdx] += tH + gap
        }
        var realGridH = Math.max.apply(null, colHeights); if (realGridH > 0) realGridH -= gap
        var finalOffY = (outerHeight - realGridH) / 2
        for (var m = 0; m < result.length; m++) result[m].y += finalOffY
        return result
    }
}

pragma Singleton
import Quickshell

Singleton {
    function doLayout(windowList, outerWidth, outerHeight, activeAddress) {
        if (windowList.length === 0) return []
        var rawGap = Math.min(outerWidth * 0.08, outerHeight * 0.08)
        var gap = Math.max(12, Math.min(32, rawGap))

        // Move active window to head
        if (activeAddress) {
            var activeIdx = windowList.findIndex(it => (it.lastIpcObject?.address ?? it.address) === activeAddress)
            if (activeIdx > 0) windowList = [windowList[activeIdx], ...windowList.filter((_, i) => i !== activeIdx)]
        }

        var contentScale = 0.90, useW = outerWidth * contentScale, useH = outerHeight * contentScale
        var offX = (outerWidth - useW) / 2, offY = (outerHeight - useH) / 2
        var result = []
        var heroRatio = 0.40, heroAreaW = useW * heroRatio, stackAreaW = useW - heroAreaW - gap
        var heroItem = windowList[0]
        var hScale = Math.min(heroAreaW / heroItem.width, useH / heroItem.height)
        result.push({ win: heroItem.win, x: offX + (heroAreaW - heroItem.width * hScale) / 2, y: offY + (useH - heroItem.height * hScale) / 2, width: heroItem.width * hScale, height: heroItem.height * hScale, isHero: true })

        var others = windowList.slice(1), N = others.length
        if (N > 0) {
            var stackStartX = offX + heroAreaW + gap
            var oneColH = (useH - (gap * (N - 1))) / N, useSingleCol = oneColH > (useH * 0.15)
            var bestCols = 1, bestRows = N
            if (!useSingleCol) {
                var bestScale = 0, TARGET_ASPECT = 16.0 / 9.0
                for (var cols = 2; cols <= N; cols++) {
                    var rows = Math.ceil(N / cols), availW = stackAreaW - (gap * (cols - 1)), availH = useH - (gap * (rows - 1))
                    if (availW <= 0 || availH <= 0) continue
                    var cs = Math.min((availW / cols) / TARGET_ASPECT, (availH / rows))
                    if (cs > bestScale) { bestScale = cs; bestCols = cols; bestRows = rows }
                }
            }
            var finalCellW = (stackAreaW - (gap * (bestCols - 1))) / bestCols, finalCellH = (useH - (gap * (bestRows - 1))) / bestRows
            var totalGridH = bestRows * finalCellH + (bestRows - 1) * gap, stackStartY = offY + (useH - totalGridH) / 2
            for (var i = 0; i < N; ++i) {
                var item = others[i], row = Math.floor(i / bestCols), col = i % bestCols
                var cellAbsX = stackStartX + col * (finalCellW + gap), cellAbsY = stackStartY + row * (finalCellH + gap)
                var sc = Math.min(finalCellW / item.width, finalCellH / item.height)
                result.push({ win: item.win, x: cellAbsX + (finalCellW - item.width * sc) / 2, y: cellAbsY + (finalCellH - item.height * sc) / 2, width: item.width * sc, height: item.height * sc, isHero: false })
            }
        }
        return result
    }
}

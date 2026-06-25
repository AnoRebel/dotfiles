pragma Singleton
import Quickshell

Singleton {
    function doLayout(windowList, outerWidth, outerHeight, activeAddress, maxSplits) {
        var N = windowList.length; if (N === 0) return []
        if (maxSplits === undefined) maxSplits = 3
        var rawGap = outerWidth * 0.008, gap = Math.max(8, Math.min(24, rawGap)), primaryGap = gap * 3
        var contentScale = 0.90, useW = outerWidth * contentScale, useH = outerHeight * contentScale
        var offX = (outerWidth - useW) / 2, offY = (outerHeight - useH) / 2

        if (activeAddress) {
            var activeIdx = windowList.findIndex(it => (it.lastIpcObject?.address ?? it.address) === activeAddress)
            if (activeIdx > 0) windowList = [windowList[activeIdx], ...windowList.filter((_, i) => i !== activeIdx)]
        }

        var result = [], curX = offX, curY = offY, curW = useW, curH = useH
        var spiralCount = Math.min(N - 1, maxSplits)
        for (var k = 0; k < spiralCount; k++) {
            var sItem = windowList[k], currentGap = (k === 0) ? primaryGap : gap, sBoxX = curX, sBoxY = curY, sBoxW, sBoxH
            if (curW > curH) { sBoxW = (curW - currentGap) / 2; sBoxH = curH; curX += sBoxW + currentGap; curW -= (sBoxW + currentGap) }
            else { sBoxW = curW; sBoxH = (curH - currentGap) / 2; curY += sBoxH + currentGap; curH -= (sBoxH + currentGap) }
            var sw0 = (sItem.width > 0) ? sItem.width : 100, sh0 = (sItem.height > 0) ? sItem.height : 100
            var sScale = Math.min(sBoxW / sw0, sBoxH / sh0)
            result.push({ win: sItem.win, x: sBoxX + (sBoxW - sw0 * sScale) / 2, y: sBoxY + (sBoxH - sh0 * sScale) / 2, width: sw0 * sScale, height: sh0 * sScale, isSpiral: true })
        }

        var remainingItems = windowList.slice(spiralCount), remN = remainingItems.length
        if (remN > 0) {
            var bestCols = 1, bestScale = 0, TARGET_ASPECT = 16.0 / 9.0
            for (var c = 1; c <= remN; c++) {
                var r = Math.ceil(remN / c), avW = curW - gap * (c - 1), avH = curH - gap * (r - 1)
                if (avW <= 0 || avH <= 0) continue
                var sc = Math.min((avW / c) / TARGET_ASPECT, avH / r)
                if (sc > bestScale) { bestScale = sc; bestCols = c }
            }
            var remRows = Math.ceil(remN / bestCols), finalCellW = (curW - gap * (bestCols - 1)) / bestCols, finalCellH = (curH - gap * (remRows - 1)) / remRows
            var gridContentH = remRows * finalCellH + (remRows - 1) * gap, gridStartY = curY + (curH - gridContentH) / 2
            for (var j = 0; j < remN; j++) {
                var rItem = remainingItems[j], row = Math.floor(j / bestCols), col = j % bestCols
                var itemsInRow = Math.min((row + 1) * bestCols, remN) - (row * bestCols)
                var rowW = itemsInRow * finalCellW + (itemsInRow - 1) * gap, rowStartX = curX + (curW - rowW) / 2
                var cellX = rowStartX + col * (finalCellW + gap), cellY = gridStartY + row * (finalCellH + gap)
                var rw0 = (rItem.width > 0) ? rItem.width : 100, rh0 = (rItem.height > 0) ? rItem.height : 100
                var rSc = Math.min(finalCellW / rw0, finalCellH / rh0)
                result.push({ win: rItem.win, x: cellX + (finalCellW - rw0 * rSc) / 2, y: cellY + (finalCellH - rh0 * rSc) / 2, width: rw0 * rSc, height: rh0 * rSc, isSpiral: false })
            }
        }
        return result
    }
}

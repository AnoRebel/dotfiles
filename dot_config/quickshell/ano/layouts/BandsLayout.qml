pragma Singleton
import Quickshell

Singleton {
    function doLayout(windowList, outerWidth, outerHeight) {
        var N = windowList.length; if (N === 0) return []
        var rawGap = Math.min(outerWidth * 0.08, outerHeight * 0.08)
        var gap = Math.max(12, Math.min(24, rawGap))
        var contentScale = 0.90, useW = outerWidth * contentScale, useH = outerHeight * contentScale
        var offX = (outerWidth - useW) / 2, offY = (outerHeight - useH) / 2

        var groups = {}, wsOrder = []
        for (var i = 0; i < N; i++) {
            var w = windowList[i], wsId = w.workspaceId
            if (!groups[wsId]) { groups[wsId] = []; wsOrder.push(wsId) }
            groups[wsId].push(w)
        }
        var bandCount = wsOrder.length; if (bandCount === 0) return []
        var totalGapH = gap * (bandCount - 1), bandHeight = (useH - totalGapH) / bandCount
        var absoluteMaxH = useH * 0.45, localMaxH = Math.min(bandHeight, absoluteMaxH)
        if (localMaxH < 10) localMaxH = 10

        var result = [], currentY = offY
        for (var b = 0; b < bandCount; b++) {
            var items = groups[wsOrder[b]], itemCount = items.length
            var rows = [], currentRow = [], currentAspectSum = 0
            for (var k = 0; k < itemCount; k++) {
                var item = items[k], w0 = (item.width > 0) ? item.width : 100, h0 = (item.height > 0) ? item.height : 100
                var aspect = w0 / h0, hypotheticalWidth = (currentAspectSum + aspect) * localMaxH + (currentRow.length * gap)
                if (currentRow.length > 0 && hypotheticalWidth > useW) { rows.push({ items: currentRow, aspectSum: currentAspectSum }); currentRow = []; currentAspectSum = 0 }
                currentRow.push({ win: item.win, aspect: aspect }); currentAspectSum += aspect
            }
            if (currentRow.length > 0) rows.push({ items: currentRow, aspectSum: currentAspectSum })

            var totalContentH = 0, finalRows = []
            for (var r = 0; r < rows.length; r++) {
                var rItems = rows[r].items, availRowW = useW - (gap * (rItems.length - 1))
                var optimalH = Math.min(availRowW / rows[r].aspectSum, localMaxH)
                finalRows.push({ items: rItems, h: optimalH }); totalContentH += optimalH
            }
            if (finalRows.length > 1) totalContentH += gap * (finalRows.length - 1)
            var scaleFactor = totalContentH > bandHeight ? bandHeight / totalContentH : 1.0
            if (scaleFactor < 1) totalContentH = bandHeight

            var rowY = currentY + (bandHeight - totalContentH) / 2
            for (var r2 = 0; r2 < finalRows.length; r2++) {
                var fRow = finalRows[r2], rHeight = fRow.h * scaleFactor, rItems2 = fRow.items
                var actualRowW = 0; for (var j = 0; j < rItems2.length; j++) actualRowW += rItems2[j].aspect * rHeight
                actualRowW += gap * (rItems2.length - 1)
                var rowX = offX + (useW - actualRowW) / 2
                for (var j2 = 0; j2 < rItems2.length; j2++) {
                    var finalW = rItems2[j2].aspect * rHeight
                    result.push({ win: rItems2[j2].win, x: rowX, y: rowY, width: finalW, height: rHeight })
                    rowX += finalW + gap
                }
                rowY += rHeight + (gap * scaleFactor)
            }
            currentY += bandHeight + gap
        }
        return result
    }
}

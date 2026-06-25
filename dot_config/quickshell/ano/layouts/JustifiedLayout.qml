pragma Singleton
import Quickshell

Singleton {
    function doLayout(windowList, outerWidth, outerHeight) {
        var N = windowList.length
        if (N === 0) return []
        var containerWidth = outerWidth * 0.9, containerHeight = outerHeight * 0.9
        var rawGap = Math.min(outerWidth * 0.08, outerHeight * 0.08)
        var gap = Math.max(12, Math.min(32, rawGap))
        var maxThumbHeight = outerHeight * 0.3
        if (containerWidth <= 0 || containerHeight <= 0) return windowList.map(item => ({ win: item.win, x: 0, y: 0, width: 0, height: 0 }))

        var rows = [], currentRow = [], sumAspect = 0
        function flushRow() {
            if (currentRow.length === 0) return
            var n = currentRow.length, rowHeight = maxThumbHeight
            if (sumAspect > 0) { var hFit = (containerWidth - gap * (n - 1)) / sumAspect; if (hFit < rowHeight) rowHeight = hFit }
            if (rowHeight > maxThumbHeight) rowHeight = maxThumbHeight; if (rowHeight <= 0) rowHeight = 1
            rows.push({ items: currentRow.slice(), height: rowHeight, sumAspect: sumAspect })
            currentRow = []; sumAspect = 0
        }

        for (var i = 0; i < N; ++i) {
            var item = windowList[i], w0 = item.width > 0 ? item.width : 1, h0 = item.height > 0 ? item.height : 1
            var a = w0 / h0; item.aspect = a
            if (currentRow.length > 0 && ((sumAspect + a) * maxThumbHeight + gap * currentRow.length) > containerWidth) flushRow()
            currentRow.push(item); sumAspect += a
        }
        if (currentRow.length > 0) flushRow()

        var totalRawHeight = 0
        for (var r = 0; r < rows.length; ++r) totalRawHeight += rows[r].height
        if (rows.length > 1) totalRawHeight += gap * (rows.length - 1)
        var sV = (totalRawHeight > containerHeight) ? containerHeight / totalRawHeight : 1.0
        var yAcc = (outerHeight - totalRawHeight * sV) / 2; if (!isFinite(yAcc) || yAcc < 0) yAcc = 0
        var result = []

        for (var r2 = 0; r2 < rows.length; ++r2) {
            var row = rows[r2], rowH = row.height * sV
            var totalRowW = 0; for (var j = 0; j < row.items.length; ++j) totalRowW += row.items[j].aspect * rowH
            totalRowW += gap * (row.items.length - 1)
            var xAcc = (outerWidth - totalRowW) / 2; if (!isFinite(xAcc)) xAcc = 0
            for (var j2 = 0; j2 < row.items.length; ++j2) {
                var it = row.items[j2], wS = it.aspect * rowH
                result.push({ win: it.win, x: xAcc, y: yAcc, width: wS, height: rowH })
                xAcc += wS + gap
            }
            yAcc += rowH; if (r2 < rows.length - 1) yAcc += gap * sV
        }
        return result
    }
}

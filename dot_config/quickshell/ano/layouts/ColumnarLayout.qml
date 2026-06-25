pragma Singleton
import Quickshell

Singleton {
    function doLayout(windowList, outerWidth, outerHeight) {
        var N = windowList.length; if (N === 0) return []
        var gap = Math.max(8, outerWidth * 0.005)
        var useW = outerWidth * 0.95, useH = outerHeight * 0.90
        var offX = (outerWidth - useW) / 2, offY = (outerHeight - useH) / 2
        var colW = (useW - (gap * (N - 1))) / N
        if (colW < 200) colW = 200
        var totalW = N * colW + (N - 1) * gap
        var startX = offX; if (totalW < useW) startX = offX + (useW - totalW) / 2
        var result = []

        for (var i = 0; i < N; i++) {
            var item = windowList[i], w0 = (item.width > 0) ? item.width : 100, h0 = (item.height > 0) ? item.height : 100
            var sc = Math.min(colW / w0, useH / h0), thumbW = w0 * sc, thumbH = h0 * sc
            result.push({ win: item.win, x: startX + i * (colW + gap) + (colW - thumbW) / 2, y: offY + (useH - thumbH) / 2, width: thumbW, height: thumbH })
        }
        return result
    }
}

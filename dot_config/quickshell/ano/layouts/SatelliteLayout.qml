pragma Singleton
import Quickshell

Singleton {
    function doLayout(windowList, outerWidth, outerHeight, activeAddress) {
        var N = windowList.length; if (N === 0) return []

        if (activeAddress) {
            var activeIdx = windowList.findIndex(it => (it.lastIpcObject?.address ?? it.address) === activeAddress)
            if (activeIdx > 0) windowList = [windowList[activeIdx], ...windowList.filter((_, i) => i !== activeIdx)]
        }

        var useW = outerWidth * 0.90, useH = outerHeight * 0.90
        var offX = (outerWidth - useW) / 2, offY = (outerHeight - useH) / 2
        var result = []

        var centerItem = windowList[0]
        var centerW = useW * 0.35, centerH = useH * 0.35
        var w0 = (centerItem.width > 0) ? centerItem.width : 100, h0 = (centerItem.height > 0) ? centerItem.height : 100
        var sc0 = Math.min(centerW / w0, centerH / h0)
        result.push({ win: centerItem.win, x: offX + (useW - w0 * sc0) / 2, y: offY + (useH - h0 * sc0) / 2, width: w0 * sc0, height: h0 * sc0, isSatellite: false })

        var satellites = windowList.slice(1), numSat = satellites.length
        if (numSat > 0) {
            var radiusX = useW * 0.4, radiusY = useH * 0.4
            var maxSatW = (useW * 0.25) / Math.max(1, numSat / 6), maxSatH = (useH * 0.25) / Math.max(1, numSat / 6)
            var startAngle = -Math.PI / 2, stepAngle = (2 * Math.PI) / numSat
            for (var i = 0; i < numSat; i++) {
                var item = satellites[i], angle = startAngle + i * stepAngle
                var cx = (useW / 2) + radiusX * Math.cos(angle), cy = (useH / 2) + radiusY * Math.sin(angle)
                var ws = (item.width > 0) ? item.width : 100, hs = (item.height > 0) ? item.height : 100
                var scS = Math.min(maxSatW / ws, maxSatH / hs)
                result.push({ win: item.win, x: offX + cx - ws * scS / 2, y: offY + cy - hs * scS / 2, width: ws * scS, height: hs * scS, isSatellite: true })
            }
        }
        return result
    }
}

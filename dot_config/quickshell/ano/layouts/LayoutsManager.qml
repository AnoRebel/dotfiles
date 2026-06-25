pragma Singleton
import Quickshell
import "."

/**
 * Dispatches layout computation to the appropriate layout algorithm.
 * Each layout's doLayout(windowList, width, height) returns an array of
 * { win, x, y, width, height, ... } objects.
 */
Singleton {
    id: root

    readonly property var layoutNames: [
        "smartgrid", "justified", "bands", "masonry", "hero",
        "spiral", "satellite", "staggered", "columnar", "vortex"
    ]

    function doLayout(layoutAlgorithm, windowList, width, height, activeAddress) {
        switch (layoutAlgorithm) {
            case 'smartgrid':  return SmartGridLayout.doLayout(windowList, width, height)
            case 'justified':  return JustifiedLayout.doLayout(windowList, width, height)
            case 'bands':      return BandsLayout.doLayout(windowList, width, height)
            case 'masonry':    return MasonryLayout.doLayout(windowList, width, height)
            case 'hero':       return HeroLayout.doLayout(windowList, width, height, activeAddress)
            case 'spiral':     return SpiralLayout.doLayout(windowList, width, height, activeAddress)
            case 'satellite':  return SatelliteLayout.doLayout(windowList, width, height, activeAddress)
            case 'staggered':  return StaggeredLayout.doLayout(windowList, width, height)
            case 'columnar':   return ColumnarLayout.doLayout(windowList, width, height)
            case 'vortex':     return VortexLayout.doLayout(windowList, width, height)
            default:           return SmartGridLayout.doLayout(windowList, width, height)
        }
    }
}

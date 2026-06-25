import QtQuick
import qs.modules.common
import qs.services

/**
 * Linear audio spectrum visualizer. Bars grow from bottom (or configurable edge).
 * Horizontally mirrored: left half is reversed copy of right half for symmetry.
 */
Item {
    id: root
    property color fillColor: Appearance?.colors.colPrimary ?? "#65558F"
    property color strokeColor: "transparent"
    property int strokeWidth: 0
    property var values: SpectrumService.values
    property bool vertical: false
    property string barPosition: "bottom"
    property bool showMinimumSignal: false
    property real minimumSignalValue: 0.03
    property real barWidthRatio: 0.5
    property real cornerRadius: 2

    readonly property int valuesCount: (values && Array.isArray(values)) ? values.length : 0
    readonly property int totalBars: valuesCount * 2
    readonly property real barSlotSize: totalBars > 0 ? (vertical ? height : width) / totalBars : 0

    Repeater {
        model: root.totalBars

        Rectangle {
            property int valueIndex: index < root.valuesCount
                ? root.valuesCount - 1 - index
                : index - root.valuesCount
            property real rawAmp: (root.values && root.values[valueIndex] !== undefined) ? root.values[valueIndex] : 0
            property real amp: (root.showMinimumSignal && rawAmp === 0) ? root.minimumSignalValue : rawAmp

            color: root.fillColor
            border.color: root.strokeColor
            border.width: root.strokeWidth
            radius: root.cornerRadius

            width: vertical ? root.width * amp : root.barSlotSize * root.barWidthRatio
            height: vertical ? root.barSlotSize * root.barWidthRatio : root.height * amp

            x: vertical
                ? (root.barPosition === "left" ? 0 : root.width - width)
                : index * root.barSlotSize + (root.barSlotSize * (1 - root.barWidthRatio) / 2)
            y: vertical
                ? index * root.barSlotSize + (root.barSlotSize * (1 - root.barWidthRatio) / 2)
                : (root.barPosition === "top" ? 0 : root.height - height)

            visible: root.visible
        }
    }
}

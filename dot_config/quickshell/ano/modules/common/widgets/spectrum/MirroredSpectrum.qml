import QtQuick
import qs.modules.common
import qs.services

/**
 * Mirrored audio spectrum visualizer. Bars grow from center outward
 * in both directions (up+down or left+right). Horizontally mirrored
 * for left-right symmetry as well.
 */
Item {
    id: root
    property color fillColor: Appearance?.colors.colPrimary ?? "#65558F"
    property color strokeColor: "transparent"
    property int strokeWidth: 0
    property var values: SpectrumService.values
    property bool vertical: false
    property bool showMinimumSignal: false
    property real minimumSignalValue: 0.03
    property real barWidthRatio: 0.8
    property real cornerRadius: 2

    readonly property int valuesCount: (values && Array.isArray(values)) ? values.length : 0
    readonly property int totalBars: valuesCount * 2
    readonly property real barSlotSize: totalBars > 0 ? (vertical ? height : width) / totalBars : 0
    readonly property real centerY: height / 2
    readonly property real centerX: width / 2

    Repeater {
        model: root.totalBars

        Rectangle {
            property int valueIndex: index < root.valuesCount
                ? root.valuesCount - 1 - index
                : index - root.valuesCount
            property real rawAmp: (root.values && root.values[valueIndex] !== undefined) ? root.values[valueIndex] : 0
            property real amp: (root.showMinimumSignal && rawAmp === 0) ? root.minimumSignalValue : rawAmp
            property real barSize: (vertical ? root.width : root.height) * amp

            color: root.fillColor
            border.color: root.strokeColor
            border.width: root.strokeWidth
            radius: root.cornerRadius

            width: vertical ? barSize : root.barSlotSize * root.barWidthRatio
            height: vertical ? root.barSlotSize * root.barWidthRatio : barSize

            x: vertical
                ? root.centerX - (barSize / 2)
                : index * root.barSlotSize + (root.barSlotSize * (1 - root.barWidthRatio) / 2)
            y: vertical
                ? index * root.barSlotSize + (root.barSlotSize * (1 - root.barWidthRatio) / 2)
                : root.centerY - (barSize / 2)

            visible: root.visible
        }
    }
}

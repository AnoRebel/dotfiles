import QtQuick
import QtQuick.Shapes
import qs.modules.common

/**
 * Combined circular progress — two overlapping rings in one gauge.
 * Inspired by hefty-hype HResources' combined CPU+RAM indicator.
 * Inner ring is typically RAM, outer is CPU (or any two values).
 *
 * Usage:
 *   CombinedCircularProgress {
 *       outerValue: cpuUsage; innerValue: ramUsage
 *       outerColor: "#65558F"; innerColor: "#42A5F5"
 *   }
 */
Item {
    id: root
    property int implicitSize: 48
    property int outerLineWidth: 3
    property int innerLineWidth: 3
    property real outerValue: 0
    property real innerValue: 0
    property color outerColor: Appearance?.colors.colPrimary ?? "#65558F"
    property color innerColor: "#42A5F5"
    property color trackColor: Appearance?.colors.colSecondaryContainer ?? "#E8DEF8"
    property bool enableAnimation: true

    implicitWidth: implicitSize; implicitHeight: implicitSize

    property real outerDegree: outerValue * 360
    property real innerDegree: innerValue * 360
    property real outerRadius: implicitSize / 2 - outerLineWidth
    property real innerRadius: implicitSize / 2 - outerLineWidth - innerLineWidth - 2
    property real centerX: implicitSize / 2
    property real centerY: implicitSize / 2

    Behavior on outerDegree { enabled: root.enableAnimation; NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Behavior on innerDegree { enabled: root.enableAnimation; NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    Shape {
        anchors.fill: parent
        layer.enabled: true; layer.smooth: true
        preferredRendererType: Shape.CurveRenderer

        // Outer track
        ShapePath {
            strokeColor: root.trackColor; strokeWidth: root.outerLineWidth
            capStyle: ShapePath.RoundCap; fillColor: "transparent"
            PathAngleArc { centerX: root.centerX; centerY: root.centerY; radiusX: root.outerRadius; radiusY: root.outerRadius; startAngle: -90; sweepAngle: 360 }
        }
        // Outer value
        ShapePath {
            strokeColor: root.outerColor; strokeWidth: root.outerLineWidth
            capStyle: ShapePath.RoundCap; fillColor: "transparent"
            PathAngleArc { centerX: root.centerX; centerY: root.centerY; radiusX: root.outerRadius; radiusY: root.outerRadius; startAngle: -90; sweepAngle: root.outerDegree }
        }
        // Inner track
        ShapePath {
            strokeColor: root.trackColor; strokeWidth: root.innerLineWidth
            capStyle: ShapePath.RoundCap; fillColor: "transparent"
            PathAngleArc { centerX: root.centerX; centerY: root.centerY; radiusX: root.innerRadius; radiusY: root.innerRadius; startAngle: -90; sweepAngle: 360 }
        }
        // Inner value
        ShapePath {
            strokeColor: root.innerColor; strokeWidth: root.innerLineWidth
            capStyle: ShapePath.RoundCap; fillColor: "transparent"
            PathAngleArc { centerX: root.centerX; centerY: root.centerY; radiusX: root.innerRadius; radiusY: root.innerRadius; startAngle: -90; sweepAngle: root.innerDegree }
        }
    }
}

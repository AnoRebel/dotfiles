import qs.modules.common
import QtQuick
import QtQuick.Layouts

/**
 * Single-select icon-row picker. Replaces the ad-hoc Repeater + GroupButton
 * patterns scattered through the Settings pages (hot corners, bar click
 * actions, AnoSpot drop-action mode, lyrics backend).
 *
 * Contract:
 *   - model: array of { value, label, icon, enabled? }
 *   - current: bound value; the parent owns the binding
 *   - chose(value): emitted on click of a non-selected, enabled option
 *   - compact: when true, icon-only (no label below); default false
 *
 * Visual: selected option uses fill: 1 icon + colSecondaryContainer
 * background. Hit target ≥32×32 (compact) or ≥48×48 (with label).
 */
Flow {
    id: root

    property var model: []
    property var current: null
    property bool compact: false
    property real itemSpacing: 6

    signal chose(var value)

    spacing: root.itemSpacing

    Repeater {
        model: root.model

        delegate: Rectangle {
            id: cell
            required property var modelData

            readonly property bool itemEnabled: modelData.enabled === undefined || modelData.enabled
            readonly property bool selected: root.current === modelData.value

            implicitWidth: root.compact ? 36 : Math.max(56, contentCol.implicitWidth + 16)
            implicitHeight: root.compact ? 36 : Math.max(48, contentCol.implicitHeight + 12)
            radius: Appearance?.rounding.small ?? 8

            color: cell.selected
                ? (Appearance?.colors.colSecondaryContainer ?? "#E8DEF8")
                : cellMA.containsMouse && cell.itemEnabled
                    ? (Appearance?.colors.colLayer1Hover ?? "#3C3947")
                    : "transparent"
            border.width: cell.selected ? 1 : 0
            border.color: Appearance?.colors.colPrimary ?? "#65558F"
            opacity: cell.itemEnabled ? 1.0 : 0.4

            Behavior on color { ColorAnimation { duration: 150 } }

            ColumnLayout {
                id: contentCol
                anchors.centerIn: parent
                spacing: root.compact ? 0 : 2

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: cell.modelData.icon ?? ""
                    iconSize: root.compact ? 18 : 20
                    fill: cell.selected ? 1 : 0
                    color: cell.selected
                        ? (Appearance?.m3colors.m3onSecondaryContainer ?? "#1D192B")
                        : (Appearance?.colors.colOnLayer1 ?? "#E6E1E5")
                }

                StyledText {
                    visible: !root.compact && (cell.modelData.label ?? "").length > 0
                    Layout.alignment: Qt.AlignHCenter
                    text: cell.modelData.label ?? ""
                    font.pixelSize: Appearance?.font.pixelSize.smaller ?? 11
                    color: cell.selected
                        ? (Appearance?.m3colors.m3onSecondaryContainer ?? "#1D192B")
                        : (Appearance?.colors.colOnLayer1 ?? "#E6E1E5")
                }
            }

            MouseArea {
                id: cellMA
                anchors.fill: parent
                hoverEnabled: true
                enabled: cell.itemEnabled
                cursorShape: cell.itemEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (!cell.itemEnabled) return;
                    if (cell.selected) return;
                    root.chose(cell.modelData.value);
                }
            }

            // Icon-only tooltip when compact
            Loader {
                active: root.compact && (cell.modelData.label ?? "").length > 0
                sourceComponent: StyledToolTip {
                    text: cell.modelData.label ?? ""
                    visible: cellMA.containsMouse
                }
            }
        }
    }
}

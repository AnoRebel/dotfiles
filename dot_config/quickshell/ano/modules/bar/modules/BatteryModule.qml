import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Battery bar module with rich hover popup showing health, time estimate,
 * power rate, and visual gauge.
 */
Item {
    id: root
    visible: Battery.available
    implicitWidth: row.implicitWidth + 12
    implicitHeight: Appearance.sizes.barHeight

    property bool hovered: batteryMA.containsMouse

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2

        MaterialSymbol {
            text: Battery.isCharging ? "bolt" : ""
            iconSize: Appearance.font.pixelSize.smaller
            fill: 1
            visible: Battery.isCharging && Battery.percentage < 1
            Layout.alignment: Qt.AlignVCenter
        }

        CircularProgress {
            implicitSize: 22; lineWidth: 2
            value: Battery.percentage
            colPrimary: Battery.isLow && !Battery.isCharging
                ? Appearance?.m3colors.m3error ?? "#BA1A1A"
                : Appearance?.colors.colOnSecondaryContainer ?? "#1D1B20"
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            text: `${Math.round(Battery.percentage * 100)}%`
            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 13
            color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: batteryMA
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // Rich hover popup
    BarModulePopout {
        shown: root.hovered
        popupWidth: 240; popupHeight: popupCol.implicitHeight + 24

        ColumnLayout {
            id: popupCol
            anchors { fill: parent }
            spacing: 10

            // Large gauge
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                CircularProgress {
                    implicitSize: 56; lineWidth: 4
                    value: Battery.percentage
                    colPrimary: Battery.isLow && !Battery.isCharging ? Appearance?.m3colors.m3error ?? "#BA1A1A"
                        : Battery.isCharging ? "#81C784" : Appearance?.colors.colPrimary ?? "#65558F"
                }
                ColumnLayout {
                    spacing: 2
                    StyledText {
                        text: `${Math.round(Battery.percentage * 100)}%`
                        font.pixelSize: 24; font.weight: Font.Bold
                        font.family: Appearance?.font.family.numbers ?? "monospace"
                    }
                    StyledText {
                        text: Battery.isCharging ? "Charging" : "On battery"
                        font.pixelSize: 12; opacity: 0.5
                    }
                }
            }

            // Stats
            Repeater {
                model: [
                    { label: "Health", value: Battery.health > 0 ? `${Math.round(Battery.health)}%` : "N/A" },
                    { label: "Power rate", value: `${Battery.energyRate.toFixed(1)} W` },
                    { label: "Time to " + (Battery.isCharging ? "full" : "empty"),
                      value: (() => {
                        const t = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                        return t > 0 ? `${Math.round(t / 60)} min` : "Calculating...";
                      })() },
                ]
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true; spacing: 8
                    StyledText { text: modelData.label; font.pixelSize: 12; opacity: 0.5; Layout.fillWidth: true }
                    StyledText { text: modelData.value; font.pixelSize: 12; font.family: Appearance?.font.family.mono ?? "monospace" }
                }
            }
        }
    }
}

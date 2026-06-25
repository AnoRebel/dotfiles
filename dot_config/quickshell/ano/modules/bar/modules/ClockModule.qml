import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Clock bar module with morph-capable popout showing calendar, uptime, weather summary.
 */
Item {
    id: root
    property bool showDate: Config.options?.bar?.verbose ?? true
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    property bool hovered: clockMA.containsMouse

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent; spacing: 4
        StyledText { font.pixelSize: Appearance.font.pixelSize.large; color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"; text: DateTime.time }
        StyledText { visible: root.showDate; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"; text: "•" }
        StyledText { visible: root.showDate; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance?.colors.colOnLayer1 ?? "#E6E1E5"; text: DateTime.date }
    }

    MouseArea { id: clockMA; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

    BarModulePopout {
        shown: root.hovered
        popupWidth: 300; popupHeight: popoutCol.implicitHeight + 24

        ColumnLayout {
            id: popoutCol
            anchors.fill: parent; spacing: 12

            // Large clock
            StyledText {
                text: DateTime.time
                font.pixelSize: 36; font.weight: Font.Bold
                font.family: Appearance?.font.family.numbers ?? "monospace"
                Layout.alignment: Qt.AlignHCenter
            }
            StyledText {
                text: DateTime.collapsedCalendarFormat
                font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                opacity: 0.5; Layout.alignment: Qt.AlignHCenter
            }

            // Mini calendar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: calView.implicitHeight + 16
                radius: Appearance?.rounding.small ?? 8
                color: Appearance?.colors.colLayer2 ?? "#2B2930"

                CalendarView {
                    id: calView
                    anchors { fill: parent; margins: 8 }
                }
            }

            // Uptime + weather summary
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                RowLayout {
                    spacing: 4
                    MaterialSymbol { text: "schedule"; iconSize: 14; opacity: 0.4 }
                    StyledText { text: `Up ${DateTime.uptime}`; font.pixelSize: 11; opacity: 0.4 }
                }
                Item { Layout.fillWidth: true }
                Loader {
                    active: (Config.options?.bar?.weather?.enable ?? false) && (Weather.data.temp ?? "").length > 0
                    visible: active
                    sourceComponent: RowLayout {
                        spacing: 4
                        MaterialSymbol { text: "thermostat"; iconSize: 14; color: Appearance?.colors.colPrimary ?? "#65558F" }
                        StyledText { text: Weather.data.temp; font.pixelSize: 11; font.family: Appearance?.font.family.mono ?? "monospace" }
                    }
                }
            }
        }
    }
}

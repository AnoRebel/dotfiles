import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * Calendar panel — month grid + upcoming-events list, sourced from
 * CalendarSync (external ICS feeds) and DateTime (today highlight).
 *
 * IPC: `qs -c ano ipc call calendar toggle`. Panel is layer-shell
 * Overlay, scrim+escape closes.
 *
 * Read-only: clicking a date filters the bottom list to that day's
 * events; "Today" button resets to the upcoming view. Editing feeds
 * happens in Settings → Services → Calendar sync.
 *
 * Spec: ano-deferred-features-batch-2026 ▸ calendar-sync.
 */
Scope {
    id: root

    readonly property bool open: GlobalStates.calendarOpen

    IpcHandler {
        target: "calendar"
        function toggle(): void { GlobalStates.calendarOpen = !GlobalStates.calendarOpen }
        function open(): void { GlobalStates.calendarOpen = true }
        function close(): void { GlobalStates.calendarOpen = false }
    }

    Variants {
        model: root.open ? Quickshell.screens : []

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: root.open
            color: "transparent"

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:calendar"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            // Click-outside scrim
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: GlobalStates.calendarOpen = false
            }

            // Card
            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 420
                height: Math.min(620, parent.height * 0.85)
                radius: Appearance?.rounding.normal ?? 14
                color: Appearance?.colors.colLayer0 ?? "#1e1e2e"
                border.width: Appearance?.glassTokens?.borderWidth ?? 1
                border.color: Appearance?.glassTokens?.borderColor
                            ?? Appearance?.colors.colOutlineVariant ?? "#444"
                opacity: Appearance?.glassTokens?.opacity ?? 1

                MouseArea { anchors.fill: parent }  // swallow scrim clicks

                // Animation in/out
                scale: root.open ? 1 : 0.95
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // Internal state — what date the events list is filtered to
                property date filterDate: new Date()
                property bool showingUpcoming: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // ─── Header ──────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        MaterialSymbol {
                            text: "calendar_month"; iconSize: 18
                            color: Appearance?.colors.colPrimary ?? "#a6e3a1"
                        }
                        StyledText {
                            text: "Calendar"
                            font.pixelSize: 15; font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: CalendarSync.fetching
                                ? "syncing…"
                                : (CalendarSync.ready
                                    ? `${CalendarSync.events.length} event${CalendarSync.events.length === 1 ? "" : "s"}`
                                    : "no feeds")
                            font.pixelSize: 10
                            opacity: 0.5
                        }
                    }

                    // ─── Month grid ─────────────────────────────────
                    CalendarView {
                        id: grid
                        Layout.fillWidth: true
                        Layout.preferredHeight: 250
                        showEventDots: true
                        onDateClicked: clickedDate => {
                            card.filterDate = clickedDate
                            card.showingUpcoming = false
                        }
                    }

                    // ─── Events list ────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        StyledText {
                            text: card.showingUpcoming
                                ? "Upcoming"
                                : Qt.locale().toString(card.filterDate, "dddd, MMM d")
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }
                        RippleButton {
                            visible: !card.showingUpcoming
                            implicitHeight: 22
                            buttonRadius: 6
                            contentItem: StyledText {
                                text: "Upcoming"; font.pixelSize: 10
                                anchors.leftMargin: 8; anchors.rightMargin: 8
                            }
                            onClicked: card.showingUpcoming = true
                        }
                    }

                    ListView {
                        id: eventList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4

                        readonly property var sourceEvents: card.showingUpcoming
                            ? CalendarSync.getUpcomingEvents(Config.options?.calendar?.upcomingDays ?? 7)
                            : CalendarSync.getEventsForDate(card.filterDate)

                        model: sourceEvents

                        // Same expressive transitions as the notification list,
                        // gated on the same flag so users have one knob.
                        readonly property bool expressive: Config.options?.notifications?.expressiveAnimations ?? true
                        add: Transition {
                            enabled: eventList.expressive
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                                NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 180; easing.type: Easing.OutCubic }
                            }
                        }
                        displaced: Transition {
                            enabled: eventList.expressive
                            NumberAnimation { property: "y"; duration: 180; easing.type: Easing.OutCubic }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            width: ListView.view ? ListView.view.width : 0
                            implicitHeight: rowCol.implicitHeight + 12
                            radius: 8
                            color: Appearance?.colors.colLayer1 ?? "#2b2930"
                            border.width: 1
                            border.color: Appearance?.colors.colOutlineVariant ?? "#44444466"

                            // Source-color stripe on the left edge
                            Rectangle {
                                width: 3
                                height: parent.height - 8
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 1.5
                                color: modelData.sourceColor || (Appearance?.colors.colPrimary ?? "#a6e3a1")
                            }

                            ColumnLayout {
                                id: rowCol
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 8
                                anchors.topMargin: 6
                                anchors.bottomMargin: 6
                                spacing: 2

                                StyledText {
                                    text: modelData.title || "(untitled)"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                RowLayout {
                                    spacing: 6
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: {
                                            const start = new Date(modelData.startDate)
                                            if (modelData.allDay) return "All day"
                                            return Qt.locale().toString(start, "ddd MMM d · h:mm AP")
                                        }
                                        font.pixelSize: 10; opacity: 0.65
                                    }
                                    StyledText {
                                        visible: !!modelData.location
                                        text: modelData.location ? `· ${modelData.location}` : ""
                                        font.pixelSize: 10; opacity: 0.5
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }
                                StyledText {
                                    visible: !!modelData.description && modelData.description.length > 0
                                    text: modelData.description ?? ""
                                    font.pixelSize: 10
                                    opacity: 0.5
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // ─── Empty state ────────────────────────────────
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8
                        spacing: 4
                        visible: eventList.count === 0
                        MaterialSymbol {
                            text: card.showingUpcoming ? "event_busy" : "event_available"
                            iconSize: 28; opacity: 0.3
                            Layout.alignment: Qt.AlignHCenter
                        }
                        StyledText {
                            text: card.showingUpcoming
                                ? (CalendarSync.events.length === 0
                                    ? "No calendar feeds configured. Add one in Settings → Services → Calendar sync."
                                    : `No upcoming events in the next ${Config.options?.calendar?.upcomingDays ?? 7} days`)
                                : "No events on this day"
                            font.pixelSize: 11
                            opacity: 0.55
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            Layout.maximumWidth: 320
                        }
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) GlobalStates.calendarOpen = false
                }
            }
        }
    }
}

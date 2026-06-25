import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * FocusTime content — the actual UI for the time tracker.
 * Uses Appearance singleton for theming.
 * Data comes from focus_daemon.py (live state file) and get_stats.py (historical queries).
 */
Item {
    id: root

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"]

    // ─── State ──────────────────────────────────────────────────────────────
    property var globalDate: new Date()
    property var appDate: new Date()
    readonly property var activeDate: root.selectedAppClass === "" ? root.globalDate : root.appDate

    property string selectedDateStr: ""
    property string selectedAppClass: ""
    property string selectedAppName: ""
    property string selectedAppIcon: ""
    property int totalSeconds: 0
    property int averageSeconds: 0
    property int yesterdaySeconds: 0
    property string weekRangeStr: ""
    property string liveActiveApp: "Desktop"
    property bool isWeekView: false

    property var topApps: []
    property var weekData: []
    property real maxWeekTotal: 1
    property var monthData: []
    property real maxMonthTotal: 1
    property var weekAppsData: []
    property var weekHeatmapData: [[], [], [], [], [], [], []]
    property real maxWeekHour: 1
    property string peakUsageHours: "N/A"
    property var hourlyData: new Array(48).fill(0)
    property real maxHourlyTotal: 1

    property real animatedTotalSeconds: 0
    Behavior on animatedTotalSeconds {
        NumberAnimation { duration: 850; easing.type: Easing.OutQuint }
    }
    onTotalSecondsChanged: animatedTotalSeconds = totalSeconds

    property bool isFirstLoad: true
    readonly property bool isTodaySelected: root.selectedDateStr === getIsoDate(new Date())

    readonly property string scriptsDir: FocusTime.scriptsDir
    readonly property string stateFilePath: FocusTime.stateFile

    property real introState: 0.0
    Component.onCompleted: {
        introState = 1.0;
        requestDataUpdate();
    }
    Behavior on introState { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }

    // ─── Data Ingestion ─────────────────────────────────────────────────────
    function updateFromData(data) {
        root.selectedDateStr = data.selected_date;
        root.totalSeconds = data.total || 0;
        root.averageSeconds = data.average || 0;
        root.yesterdaySeconds = data.yesterday || 0;
        root.weekRangeStr = data.week_range || "";
        root.liveActiveApp = data.current || "Unknown";

        if (root.isFirstLoad) firstLoadTimer.start();

        root.topApps = data.apps || [];
        syncAppsModel();
        root.weekAppsData = data.week_apps || [];
        syncWeekAppsModel();

        root.weekHeatmapData = data.week_heatmap || [[], [], [], [], [], [], []];
        let mwh = 1;
        for (let i = 0; i < 7; i++) {
            if (!root.weekHeatmapData[i]) continue;
            for (let j = 0; j < 24; j++) {
                if (root.weekHeatmapData[i][j] > mwh) mwh = root.weekHeatmapData[i][j];
            }
        }
        root.maxWeekHour = mwh;

        if (data.peak_usage_str && data.peak_usage_str !== "N/A") {
            root.peakUsageHours = data.peak_usage_str;
        } else {
            root.peakUsageHours = "N/A";
        }

        let parsedWeek = data.week || [];
        if (JSON.stringify(root.weekData) !== JSON.stringify(parsedWeek)) {
            root.weekData = parsedWeek;
            syncWeekModel();
        }

        let parsedMonth = data.month || [];
        if (JSON.stringify(root.monthData) !== JSON.stringify(parsedMonth)) {
            root.monthData = parsedMonth;
            syncMonthModel();
        }

        root.hourlyData = data.hourly || new Array(48).fill(0);
        let currentMaxHour = 1;
        for (let i = 0; i < 48; i++) {
            if (root.hourlyData[i] > currentMaxHour) currentMaxHour = root.hourlyData[i];
        }
        root.maxHourlyTotal = currentMaxHour;
    }

    // ─── Data Fetching ──────────────────────────────────────────────────────
    function requestDataUpdate() {
        if (root.selectedAppClass === "" && getIsoDate(root.activeDate) === getIsoDate(new Date())) {
            liveFileReader.running = true;
        } else {
            let cmd = ["python3", root.scriptsDir + "/get_stats.py", getIsoDate(root.activeDate)];
            if (root.selectedAppClass !== "") {
                cmd.push("--app");
                cmd.push(root.selectedAppClass);
            }
            statsPoller.command = cmd;
            statsPoller.running = true;
        }
    }

    Process {
        id: liveFileReader
        command: ["cat", root.stateFilePath]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (raw === "") return;
                try {
                    let data = JSON.parse(raw);
                    root.updateFromData(data);
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1000
        running: root.isTodaySelected && root.visible
        repeat: true
        onTriggered: root.requestDataUpdate()
    }

    Process {
        id: statsPoller
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (raw === "") return;
                try {
                    let data = JSON.parse(raw);
                    root.updateFromData(data);
                } catch (e) {}
            }
        }
    }

    // ─── Date Helpers ───────────────────────────────────────────────────────
    function getIsoDate(d) {
        let z = d.getTimezoneOffset() * 60000;
        return (new Date(d - z)).toISOString().slice(0, 10);
    }

    function getFancyDate(d) {
        let monthName = root.monthNames[d.getMonth()];
        let dateNum = d.getDate();
        return getIsoDate(d) === getIsoDate(new Date()) ? "Today" : `${monthName} ${dateNum}`;
    }

    function changeDay(offsetDays) {
        let d = new Date(root.activeDate);
        d.setDate(d.getDate() + offsetDays);
        if (root.selectedAppClass === "") root.globalDate = d;
        else root.appDate = d;
        root.isFirstLoad = true;
        root.requestDataUpdate();
    }

    function changeToDate(clickedDateStr) {
        if (!clickedDateStr) return;
        let currentIso = getIsoDate(root.activeDate);
        if (clickedDateStr === currentIso) return;
        let dCurrent = new Date(currentIso + "T12:00:00");
        let dClicked = new Date(clickedDateStr + "T12:00:00");
        let diffDays = Math.round((dClicked - dCurrent) / (1000 * 60 * 60 * 24));
        if (diffDays !== 0) changeDay(diffDays);
    }

    Timer {
        id: firstLoadTimer
        interval: 1000
        onTriggered: root.isFirstLoad = false
    }

    function formatTimeLarge(secs) {
        let h = Math.floor(secs / 3600);
        let m = Math.floor((secs % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    function formatTimeList(secs) {
        let h = Math.floor(secs / 3600);
        let m = Math.floor((secs % 3600) / 60);
        return h > 0 ? h + "h " + m.toString().padStart(2, '0') + "m" : m + "m";
    }

    // ─── Models ─────────────────────────────────────────────────────────────
    ListModel { id: appListModel }
    ListModel { id: weekAppListModel }
    ListModel { id: weekListModel }
    ListModel { id: monthListModel }

    function syncAppsModel() {
        for (let i = 0; i < root.topApps.length; i++) {
            let app = root.topApps[i];
            if (i < appListModel.count) {
                appListModel.setProperty(i, "name", app.name);
                appListModel.setProperty(i, "appClass", app["class"]);
                appListModel.setProperty(i, "icon", app.icon || "");
                appListModel.setProperty(i, "seconds", app.seconds);
                appListModel.setProperty(i, "percent", app.percent);
            } else {
                appListModel.append({ name: app.name, appClass: app["class"], icon: app.icon || "",
                    seconds: app.seconds, percent: app.percent, idx: i });
            }
        }
        while (appListModel.count > root.topApps.length) appListModel.remove(appListModel.count - 1);
    }

    function syncWeekAppsModel() {
        for (let i = 0; i < root.weekAppsData.length; i++) {
            let app = root.weekAppsData[i];
            if (i < weekAppListModel.count) {
                weekAppListModel.setProperty(i, "name", app.name);
                weekAppListModel.setProperty(i, "appClass", app["class"]);
                weekAppListModel.setProperty(i, "icon", app.icon || "");
                weekAppListModel.setProperty(i, "seconds", app.seconds);
                weekAppListModel.setProperty(i, "percent", app.percent);
            } else {
                weekAppListModel.append({ name: app.name, appClass: app["class"], icon: app.icon || "",
                    seconds: app.seconds, percent: app.percent, idx: i });
            }
        }
        while (weekAppListModel.count > root.weekAppsData.length) weekAppListModel.remove(weekAppListModel.count - 1);
    }

    function syncWeekModel() {
        let currentMax = 1;
        for (let i = 0; i < root.weekData.length; i++) {
            if (root.weekData[i].total > currentMax) currentMax = root.weekData[i].total;
        }
        root.maxWeekTotal = currentMax;
        for (let i = 0; i < root.weekData.length; i++) {
            let w = root.weekData[i];
            if (i < weekListModel.count) {
                weekListModel.setProperty(i, "dateStr", w.date);
                weekListModel.setProperty(i, "dayName", w.day);
                weekListModel.setProperty(i, "total", w.total);
                weekListModel.setProperty(i, "isTarget", w.is_target);
            } else {
                weekListModel.append({ dateStr: w.date, dayName: w.day, total: w.total, isTarget: w.is_target });
            }
        }
        while (weekListModel.count > root.weekData.length) weekListModel.remove(weekListModel.count - 1);
    }

    function syncMonthModel() {
        let currentMax = 1;
        for (let i = 0; i < root.monthData.length; i++) {
            if (root.monthData[i].total > currentMax) currentMax = root.monthData[i].total;
        }
        root.maxMonthTotal = currentMax;
        for (let i = 0; i < root.monthData.length; i++) {
            let m = root.monthData[i];
            if (i < monthListModel.count) {
                monthListModel.setProperty(i, "dateStr", m.date);
                monthListModel.setProperty(i, "total", m.total);
                monthListModel.setProperty(i, "isTarget", m.is_target);
            } else {
                monthListModel.append({ dateStr: m.date, total: m.total, isTarget: m.is_target });
            }
        }
        while (monthListModel.count > root.monthData.length) monthListModel.remove(monthListModel.count - 1);
    }

    // ─── Keyboard Navigation ────────────────────────────────────────────────
    Shortcut { sequence: "Left"; onActivated: changeDay(-1) }
    Shortcut { sequence: "Right"; onActivated: changeDay(1) }
    Shortcut { sequence: "Escape"; onActivated: GlobalStates.focusTimeOpen = false }

    // ═══════════════════════════════════════════════════════════════════════
    // UI
    // ═══════════════════════════════════════════════════════════════════════
    Item {
        anchors.fill: parent
        scale: 0.97 + (0.03 * root.introState)
        opacity: root.introState

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.screenRounding
            color: Appearance.colors.colLayer0
            border.color: Qt.alpha(Appearance.colors.colOnLayer0, 0.1)
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                // ─── Header ─────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40

                    Row {
                        Layout.preferredWidth: 84
                        Layout.preferredHeight: 40
                        spacing: 4

                        // Back button
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            visible: root.selectedAppClass !== "" || root.isWeekView
                            color: backMa.containsMouse ? Appearance.colors.colLayer1 : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MaterialSymbol { anchors.centerIn: parent; text: "arrow_back"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            MouseArea {
                                id: backMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.selectedAppClass !== "") {
                                        root.selectedAppClass = ""; root.selectedAppName = ""; root.selectedAppIcon = "";
                                        root.requestDataUpdate();
                                    } else if (root.isWeekView) {
                                        root.isWeekView = false;
                                    }
                                }
                            }
                        }

                        // Week view button
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            visible: root.selectedAppClass === "" && !root.isWeekView
                            color: weekMa.containsMouse ? Appearance.colors.colLayer1 : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MaterialSymbol { anchors.centerIn: parent; text: "calendar_view_week"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            MouseArea {
                                id: weekMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.isWeekView = true
                            }
                        }

                        // Prev day
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: prevMa.containsMouse ? Appearance.colors.colLayer1 : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MaterialSymbol { anchors.centerIn: parent; text: "chevron_left"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: changeDay(-1) }
                        }
                    }

                    // Title
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        Image {
                            visible: root.selectedAppClass !== "" && root.selectedAppIcon !== "" && !root.isWeekView
                            source: root.selectedAppIcon.startsWith("/") ? "file://" + root.selectedAppIcon : "image://icon/" + root.selectedAppIcon
                            sourceSize: Qt.size(20, 20)
                            Layout.preferredWidth: 20; Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignVCenter
                            fillMode: Image.PreserveAspectFit
                        }

                        StyledText {
                            horizontalAlignment: Text.AlignHCenter
                            font.weight: Font.DemiBold
                            font.pixelSize: 18
                            color: Appearance.colors.colOnLayer0
                            text: root.isWeekView ? "Week Overview" :
                                (root.selectedAppClass !== "" ? `${root.selectedAppName} - ${root.getFancyDate(root.activeDate)}` :
                                root.getFancyDate(root.activeDate))
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Next day
                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 20
                        color: nextMa.containsMouse ? Appearance.colors.colLayer1 : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        MaterialSymbol { anchors.centerIn: parent; text: "chevron_right"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                        MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: changeDay(1) }
                    }
                }

                // ─── Stats Cards ────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    spacing: 16
                    visible: !root.isWeekView

                    // Daily average
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 200
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer1
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 2
                            StyledText { Layout.alignment: Qt.AlignHCenter; font.weight: Font.DemiBold; font.pixelSize: 13; color: Appearance.m3colors.m3outline; text: "Daily average" }
                            StyledText { Layout.alignment: Qt.AlignHCenter; font.weight: Font.Bold; font.pixelSize: 20; color: Appearance.colors.colOnLayer0; text: root.formatTimeList(root.averageSeconds) }
                            StyledText { Layout.alignment: Qt.AlignHCenter; font.pixelSize: 11; color: Appearance.m3colors.m3outline; text: root.weekRangeStr; visible: root.weekRangeStr !== "" }
                        }
                    }

                    // Total time (hero)
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 300
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer1
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 0
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter; font.weight: Font.Black; font.pixelSize: 36
                                color: Appearance.colors.colOnLayer0; text: root.formatTimeLarge(root.animatedTotalSeconds)
                            }
                        }
                    }

                    // vs Yesterday
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 200
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer1
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 4
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter; spacing: 6
                                visible: !(root.totalSeconds === 0 && root.yesterdaySeconds === 0) && root.totalSeconds !== root.yesterdaySeconds
                                StyledText {
                                    font.weight: Font.Bold; font.pixelSize: 16
                                    color: (root.totalSeconds - root.yesterdaySeconds) > 0 ? Appearance.m3colors.m3error : Appearance.m3colors.m3primary
                                    text: ((root.totalSeconds - root.yesterdaySeconds) > 0 ? "\u2191 " : "\u2193 ") + root.formatTimeList(Math.abs(root.totalSeconds - root.yesterdaySeconds))
                                }
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter; font.weight: Font.DemiBold; font.pixelSize: 14; color: Appearance.m3colors.m3outline
                                text: (root.totalSeconds === 0 && root.yesterdaySeconds === 0) ? "No data" : (root.totalSeconds === root.yesterdaySeconds ? "Same time" : "")
                                visible: (root.totalSeconds === 0 && root.yesterdaySeconds === 0) || root.totalSeconds === root.yesterdaySeconds
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter; font.weight: Font.DemiBold; font.pixelSize: 13; color: Appearance.m3colors.m3outline
                                text: "vs yesterday"; visible: !(root.totalSeconds === 0 && root.yesterdaySeconds === 0)
                            }
                        }
                    }
                }

                // ─── Week bar chart + Month heatmap ─────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    spacing: 16
                    visible: !root.isWeekView

                    // Week bars
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 400
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer1
                        RowLayout {
                            anchors.centerIn: parent; height: parent.height - 32; spacing: 12
                            Repeater {
                                model: weekListModel
                                delegate: Item {
                                    Layout.fillHeight: true; Layout.preferredWidth: 42
                                    MouseArea {
                                        id: barMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.changeToDate(model.dateStr)
                                    }
                                    Item {
                                        anchors.bottom: dayLbl.top; anchors.bottomMargin: 8
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 42; height: Math.max(4, (parent.height - 25) * (model.total / Math.max(root.maxWeekTotal, 1)))
                                        Behavior on height { NumberAnimation { duration: root.isFirstLoad ? 800 : 600; easing.type: Easing.OutQuint } }
                                        Rectangle {
                                            anchors.fill: parent; radius: 4
                                            color: model.isTarget ? Appearance.m3colors.m3primary : Appearance.colors.colLayer2
                                            opacity: barMa.containsMouse ? 0.7 : 1.0
                                        }
                                    }
                                    StyledText {
                                        id: dayLbl; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                        font.weight: Font.DemiBold; font.pixelSize: 12
                                        color: model.isTarget ? Appearance.colors.colOnLayer0 : Appearance.m3colors.m3outline
                                        text: model.dayName
                                    }
                                }
                            }
                        }
                    }

                    // Month heatmap
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 300
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer1
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 4
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter; font.weight: Font.DemiBold; font.pixelSize: 13
                                color: Appearance.colors.colOnLayer0; text: root.monthNames[root.activeDate.getMonth()] + " " + root.activeDate.getFullYear()
                            }
                            Grid {
                                Layout.alignment: Qt.AlignHCenter
                                columns: 7; spacing: 3
                                Repeater {
                                    model: monthListModel
                                    delegate: Rectangle {
                                        width: 14; height: 14; radius: 3
                                        color: {
                                            if (model.total < 0) return "transparent";
                                            if (model.isTarget) return Appearance.m3colors.m3primary;
                                            if (model.total === 0) return Appearance.colors.colLayer2;
                                            let intensity = Math.min(model.total / Math.max(root.maxMonthTotal, 1), 1.0);
                                            return Qt.alpha(Appearance.m3colors.m3primary, 0.2 + intensity * 0.8);
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: model.total >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: { if (model.dateStr) root.changeToDate(model.dateStr) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ─── Hourly breakdown ───────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 60
                    radius: Appearance.rounding.small; color: Appearance.colors.colLayer1
                    visible: !root.isWeekView
                    Row {
                        anchors.fill: parent; anchors.margins: 8; spacing: 1
                        Repeater {
                            model: 48
                            delegate: Item {
                                width: (parent.width - 47) / 48; height: parent.height
                                Rectangle {
                                    anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width; radius: 2
                                    height: Math.max(2, parent.height * (root.hourlyData[index] / Math.max(root.maxHourlyTotal, 1)))
                                    color: Appearance.m3colors.m3primary; opacity: 0.6
                                    Behavior on height { NumberAnimation { duration: root.isFirstLoad ? 800 : 400; easing.type: Easing.OutQuint } }
                                }
                            }
                        }
                    }
                    RowLayout {
                        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                        anchors.margins: 8; anchors.bottomMargin: 2
                        Repeater {
                            model: 5
                            delegate: StyledText {
                                Layout.fillWidth: true; horizontalAlignment: index === 0 ? Text.AlignLeft : (index === 4 ? Text.AlignRight : Text.AlignHCenter)
                                font.pixelSize: 9; color: Appearance.m3colors.m3outline; text: (index * 6) + ":00"
                            }
                        }
                    }
                }

                // ─── App List ───────────────────────────────────────────
                StyledFlickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: !root.isWeekView
                    contentHeight: appColumn.implicitHeight; clip: true
                    ColumnLayout {
                        id: appColumn; width: parent.width; spacing: 2
                        Repeater {
                            model: appListModel
                            delegate: Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 44
                                radius: Appearance.rounding.small
                                color: appItemMa.containsMouse ? Appearance.colors.colLayer1 : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                MouseArea {
                                    id: appItemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedAppClass = model.appClass;
                                        root.selectedAppName = model.name;
                                        root.selectedAppIcon = model.icon;
                                        root.appDate = new Date(root.globalDate);
                                        root.requestDataUpdate();
                                    }
                                }
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                    Image {
                                        source: model.icon ? (model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon) : ""
                                        sourceSize: Qt.size(24, 24); Layout.preferredWidth: 24; Layout.preferredHeight: 24
                                        fillMode: Image.PreserveAspectFit; visible: model.icon !== ""
                                    }
                                    MaterialSymbol {
                                        text: "apps"; iconSize: 24; color: Appearance.m3colors.m3outline
                                        visible: model.icon === ""
                                    }
                                    StyledText {
                                        Layout.fillWidth: true; text: model.name
                                        font.pixelSize: 14; color: Appearance.colors.colOnLayer0; elide: Text.ElideRight
                                    }
                                    Rectangle {
                                        Layout.preferredWidth: Math.max(60, Math.min(200, 200 * model.percent / 100))
                                        Layout.preferredHeight: 6; radius: 3
                                        color: Appearance.colors.colLayer2
                                        Rectangle {
                                            width: parent.width * (model.percent / 100); height: parent.height; radius: 3
                                            color: Appearance.m3colors.m3primary
                                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
                                        }
                                    }
                                    StyledText {
                                        text: root.formatTimeList(model.seconds); font.pixelSize: 13; font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnLayer0; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignRight
                                    }
                                    StyledText {
                                        text: model.percent.toFixed(1) + "%"; font.pixelSize: 11
                                        color: Appearance.m3colors.m3outline; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }

                // ─── Week Overview ──────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: root.isWeekView; spacing: 16

                    // Week stats row
                    RowLayout {
                        Layout.fillWidth: true; Layout.preferredHeight: 70; spacing: 16
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            radius: Appearance.rounding.small; color: Appearance.colors.colLayer1
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 2
                                StyledText { Layout.alignment: Qt.AlignHCenter; font.pixelSize: 12; color: Appearance.m3colors.m3outline; text: "Peak hours" }
                                StyledText { Layout.alignment: Qt.AlignHCenter; font.weight: Font.Bold; font.pixelSize: 18; color: Appearance.colors.colOnLayer0; text: root.peakUsageHours }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            radius: Appearance.rounding.small; color: Appearance.colors.colLayer1
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 2
                                StyledText { Layout.alignment: Qt.AlignHCenter; font.pixelSize: 12; color: Appearance.m3colors.m3outline; text: "Weekly average" }
                                StyledText { Layout.alignment: Qt.AlignHCenter; font.weight: Font.Bold; font.pixelSize: 18; color: Appearance.colors.colOnLayer0; text: root.formatTimeList(root.averageSeconds) }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            radius: Appearance.rounding.small; color: Appearance.colors.colLayer1
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 2
                                StyledText { Layout.alignment: Qt.AlignHCenter; font.pixelSize: 12; color: Appearance.m3colors.m3outline; text: "Week range" }
                                StyledText { Layout.alignment: Qt.AlignHCenter; font.weight: Font.Bold; font.pixelSize: 14; color: Appearance.colors.colOnLayer0; text: root.weekRangeStr }
                            }
                        }
                    }

                    // Week heatmap (7x24 grid)
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 180
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer1
                        Column {
                            anchors.fill: parent; anchors.margins: 12; spacing: 2
                            // Header row
                            Row {
                                spacing: 2
                                Item { width: 30; height: 14 }
                                Repeater {
                                    model: 24
                                    delegate: StyledText {
                                        width: (parent.parent.parent.width - 34 - 46) / 24; height: 14
                                        text: index % 3 === 0 ? index.toString() : ""; font.pixelSize: 9
                                        color: Appearance.m3colors.m3outline; horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                            // Data rows
                            Repeater {
                                model: 7
                                delegate: Row {
                                    property int dayIdx: index
                                    spacing: 2
                                    StyledText {
                                        width: 30; height: 20; text: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][dayIdx]
                                        font.pixelSize: 10; font.weight: Font.DemiBold; color: Appearance.m3colors.m3outline
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Repeater {
                                        model: 24
                                        delegate: Rectangle {
                                            property int hourIdx: index
                                            width: (parent.parent.parent.parent.width - 34 - 46) / 24; height: 20; radius: 2
                                            color: {
                                                let val = (root.weekHeatmapData[dayIdx] && root.weekHeatmapData[dayIdx][hourIdx]) || 0;
                                                if (val === 0) return Appearance.colors.colLayer2;
                                                let intensity = Math.min(val / Math.max(root.maxWeekHour, 1), 1.0);
                                                return Qt.alpha(Appearance.m3colors.m3primary, 0.15 + intensity * 0.85);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Weekly top apps
                    StyledFlickable {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        contentHeight: weekAppColumn.implicitHeight; clip: true
                        ColumnLayout {
                            id: weekAppColumn; width: parent.width; spacing: 2
                            Repeater {
                                model: weekAppListModel
                                delegate: Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 40
                                    radius: Appearance.rounding.small
                                    color: weekAppMa.containsMouse ? Appearance.colors.colLayer1 : "transparent"
                                    MouseArea { id: weekAppMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                        Image {
                                            source: model.icon ? (model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon) : ""
                                            sourceSize: Qt.size(20, 20); Layout.preferredWidth: 20; Layout.preferredHeight: 20
                                            fillMode: Image.PreserveAspectFit; visible: model.icon !== ""
                                        }
                                        StyledText { Layout.fillWidth: true; text: model.name; font.pixelSize: 13; color: Appearance.colors.colOnLayer0; elide: Text.ElideRight }
                                        StyledText { text: root.formatTimeList(model.seconds); font.pixelSize: 13; font.weight: Font.DemiBold; color: Appearance.colors.colOnLayer0 }
                                        StyledText { text: model.percent.toFixed(1) + "%"; font.pixelSize: 11; color: Appearance.m3colors.m3outline; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

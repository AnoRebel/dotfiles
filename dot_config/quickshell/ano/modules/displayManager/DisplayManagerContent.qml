import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

Item {
    id: window

    // ─── Colors from Appearance ─────────────────────────────────────────
    readonly property color base: Appearance.colors.colLayer0
    readonly property color mantle: Appearance.colors.colLayer1
    readonly property color crust: Appearance.colors.colLayer2
    readonly property color text_: Appearance.colors.colOnLayer0
    readonly property color subtext0: Appearance.m3colors.m3onSurfaceVariant
    readonly property color overlay0: Appearance.m3colors.m3outline
    readonly property color surface0: Appearance.m3colors.m3surfaceContainerLow
    readonly property color surface1: Appearance.m3colors.m3surfaceContainer
    readonly property color surface2: Appearance.m3colors.m3surfaceContainerHigh

    readonly property color accentPink: Appearance.m3colors.m3tertiary
    readonly property color accentMauve: Appearance.m3colors.m3primary
    readonly property color accentBlue: Appearance.m3colors.m3secondary
    readonly property color accentTeal: Appearance.m3colors.m3primaryContainer
    readonly property color accentYellow: Appearance.m3colors.m3tertiaryContainer
    readonly property color accentPeach: Appearance.m3colors.m3error
    readonly property color accentGreen: Appearance.m3colors.m3secondaryContainer
    readonly property color accentRed: Appearance.m3colors.m3error

    // ─── State ──────────────────────────────────────────────────────────
    property int activeEditIndex: 0
    property real uiScale: 0.10
    property int stationaryIndex: monitorsModel.count === 2 ? (activeEditIndex === 0 ? 1 : 0) : 0
    property int originalLayoutOriginX: 0
    property int originalLayoutOriginY: 0

    ListModel { id: monitorsModel }

    property color selectedResAccent: accentMauve
    property color selectedRateAccent: accentBlue

    property real currentSimW: monitorsModel.count > 0 ? monitorsModel.get(0).resW : 1920
    property real currentSimH: monitorsModel.count > 0 ? monitorsModel.get(0).resH : 1080

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000
        loops: Animation.Infinite; running: true
    }

    property real introState: 0.0
    Component.onCompleted: introState = 1.0
    Behavior on introState { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }

    property bool applyHovered: false
    property bool applyPressed: false

    onActiveEditIndexChanged: menuTransitionAnim.restart()

    // ─── Perimeter Snap ─────────────────────────────────────────────────
    function getPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT) {
        let edges = [
            { x1: sX - mW, x2: sX + sW, y1: sY - mH, y2: sY - mH },
            { x1: sX - mW, x2: sX + sW, y1: sY + sH, y2: sY + sH },
            { x1: sX - mW, x2: sX - mW, y1: sY - mH, y2: sY + sH },
            { x1: sX + sW, x2: sX + sW, y1: sY - mH, y2: sY + sH }
        ];
        let bestX = pX, bestY = pY, minDist = 999999;
        for (let i = 0; i < 4; i++) {
            let e = edges[i];
            let cx = Math.max(e.x1, Math.min(pX, e.x2));
            let cy = Math.max(e.y1, Math.min(pY, e.y2));
            if (Math.abs(cx - sX) < snapT) cx = sX;
            if (Math.abs(cx - (sX + sW - mW)) < snapT) cx = sX + sW - mW;
            if (Math.abs(cx - (sX + sW/2 - mW/2)) < snapT) cx = sX + sW/2 - mW/2;
            if (Math.abs(cy - sY) < snapT) cy = sY;
            if (Math.abs(cy - (sY + sH - mH)) < snapT) cy = sY + sH - mH;
            if (Math.abs(cy - (sY + sH/2 - mH/2)) < snapT) cy = sY + sH/2 - mH/2;
            let dist = Math.hypot(pX - cx, pY - cy);
            if (dist < minDist) { minDist = dist; bestX = cx; bestY = cy; }
        }
        return { x: bestX, y: bestY };
    }

    function forceLayoutUpdate() {
        if (monitorsModel.count === 2) {
            let mIdx = activeEditIndex, sIdx = stationaryIndex;
            let sModel = monitorsModel.get(sIdx), mModel = monitorsModel.get(mIdx);
            let sW = (sModel.resW / sModel.sysScale) * uiScale;
            let sH = (sModel.resH / sModel.sysScale) * uiScale;
            let mW = (mModel.resW / mModel.sysScale) * uiScale;
            let mH = (mModel.resH / mModel.sysScale) * uiScale;
            let snapped = getPerimeterSnap(mModel.uiX, mModel.uiY, sModel.uiX, sModel.uiY, sW, sH, mW, mH, 20);
            monitorsModel.setProperty(mIdx, "uiX", snapped.x);
            monitorsModel.setProperty(mIdx, "uiY", snapped.y);
        }
    }

    Timer {
        id: delayedLayoutUpdate
        interval: 10; running: false; repeat: false
        onTriggered: window.forceLayoutUpdate()
    }

    // ─── System Query ───────────────────────────────────────────────────
    Process {
        id: displayPoller
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    monitorsModel.clear();
                    let minX = 999999, minY = 999999;
                    for (let i = 0; i < data.length; i++) {
                        if (data[i].x < minX) minX = data[i].x;
                        if (data[i].y < minY) minY = data[i].y;
                    }
                    window.originalLayoutOriginX = minX !== 999999 ? minX : 0;
                    window.originalLayoutOriginY = minY !== 999999 ? minY : 0;
                    for (let i = 0; i < data.length; i++) {
                        let scl = data[i].scale !== undefined ? data[i].scale : 1.0;
                        let normalizedX = (data[i].x - minX) * window.uiScale;
                        let normalizedY = (data[i].y - minY) * window.uiScale;
                        monitorsModel.append({
                            name: data[i].name,
                            resW: data[i].width, resH: data[i].height,
                            sysScale: scl,
                            rate: Math.round(data[i].refreshRate).toString(),
                            uiX: normalizedX, uiY: normalizedY
                        });
                        if (data[i].focused) window.activeEditIndex = i;
                    }
                    window.forceLayoutUpdate();
                } catch(e) {}
            }
        }
    }

    // ─── UI ─────────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * introState)
        opacity: introState

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.screenRounding
            color: window.base
            border.color: window.surface0
            border.width: 1
            clip: true

            // Orbiting background decorations
            Rectangle {
                width: parent.width * 0.8; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(globalOrbitAngle * 2) * 150
                y: (parent.height / 2 - height / 2) + Math.sin(globalOrbitAngle * 2) * 100
                opacity: 0.04; color: selectedResAccent
                Behavior on color { ColorAnimation { duration: 1000 } }
            }
            Rectangle {
                width: parent.width * 0.9; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(globalOrbitAngle * 1.5) * -150
                y: (parent.height / 2 - height / 2) + Math.cos(globalOrbitAngle * 1.5) * -100
                opacity: 0.04; color: selectedRateAccent
                Behavior on color { ColorAnimation { duration: 1000 } }
            }

            // ═════════════════════════════════════════════════════════════
            // LEFT: Monitor Preview
            // ═════════════════════════════════════════════════════════════
            Item {
                id: leftVisualArea
                width: 380; height: 300
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20

                // Single monitor mode
                Item {
                    anchors.fill: parent
                    visible: monitorsModel.count === 1

                    Item {
                        id: singleMonitorZoom
                        anchors.centerIn: parent
                        width: 380; height: 280
                        scale: Math.min(1.0, 2200 / currentSimW)
                        Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

                        Rectangle {
                            id: deskSurface
                            width: 1000; height: 14; radius: 6
                            anchors.top: standBase.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: window.mantle; border.color: window.surface0; border.width: 1
                            Rectangle { width: 24; height: 350; radius: 4; color: window.crust; anchors { top: parent.bottom; topMargin: -5; left: parent.left; leftMargin: 100 }
                            z: -1 }
                            Rectangle { width: 24; height: 350; radius: 4; color: window.crust; anchors { top: parent.bottom; topMargin: -5; right: parent.right; rightMargin: 100 }
                            z: -1 }
                        }
                        Rectangle {
                            id: standBase
                            width: 130; height: 8; radius: 4
                            anchors { bottom: parent.bottom; bottomMargin: 20; horizontalCenter: parent.horizontalCenter }
                            color: window.surface1
                        }
                        Rectangle {
                            id: standNeck
                            width: 34; height: 70
                            anchors { bottom: standBase.top; horizontalCenter: parent.horizontalCenter }
                            color: window.surface0
                            Rectangle { width: 10; height: 30; radius: 5; anchors.centerIn: parent; color: window.base }
                        }
                        Rectangle {
                            id: screenBezel
                            width: 140 + (180 * (currentSimW / 1920))
                            height: 90 + (90 * (currentSimH / 1080))
                            anchors { bottom: standNeck.top; bottomMargin: -10; horizontalCenter: parent.horizontalCenter }
                            radius: 12; color: window.crust; border.color: window.surface2; border.width: 2
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
                            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

                            Rectangle {
                                anchors.fill: parent; anchors.margins: 10; radius: 6; color: window.surface0; clip: true
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0.0; color: Qt.tint(window.surface0, Qt.alpha(selectedResAccent, 0.15)); Behavior on color { ColorAnimation { duration: 400 } } }
                                    GradientStop { position: 1.0; color: Qt.tint(window.surface0, Qt.alpha(selectedRateAccent, 0.1)); Behavior on color { ColorAnimation { duration: 400 } } }
                                }
                                Grid { anchors.centerIn: parent; rows: 10; columns: 15; spacing: 20; Repeater { model: 150; Rectangle { width: 2; height: 2; radius: 1; color: Qt.alpha(window.text_, 0.1) } } }
                                Item {
                                    anchors.centerIn: parent
                                    scale: 1.0 / singleMonitorZoom.scale
                                    ColumnLayout {
                                        anchors.centerIn: parent; spacing: 4
                                        StyledText { Layout.alignment: Qt.AlignHCenter; font.family: Appearance.font.family.iconNerd; font.pixelSize: 38; color: selectedResAccent; text: "󰍹"; Behavior on color { ColorAnimation { duration: 400 } } }
                                        StyledText { Layout.alignment: Qt.AlignHCenter; font.family: Appearance.font.family.monospace; font.weight: Font.Bold; font.pixelSize: 16; color: window.text_; text: monitorsModel.count > 0 ? monitorsModel.get(0).name : "Unknown" }
                                        StyledText { Layout.alignment: Qt.AlignHCenter; font.family: Appearance.font.family.monospace; font.pixelSize: 12; color: window.subtext0; text: currentSimW + "x" + currentSimH + " @ " + (monitorsModel.count > 0 ? monitorsModel.get(0).rate : "60") + "Hz" }
                                    }
                                }
                            }
                        }
                    }
                }

                // Multi-monitor mode
                Item {
                    anchors.fill: parent
                    visible: monitorsModel.count > 1

                    Item {
                        id: multiMonitorView
                        width: 380; height: 280; anchors.centerIn: parent; clip: true
                        Grid { anchors.centerIn: parent; rows: 25; columns: 34; spacing: 18; Repeater { model: 850; Rectangle { width: 2; height: 2; radius: 1; color: Qt.alpha(window.text_, 0.1) } } }

                        property real targetScale: {
                            if (monitorsModel.count < 2) return 1.0;
                            let sModel = monitorsModel.get(stationaryIndex), mModel = monitorsModel.get(activeEditIndex);
                            let sW = (sModel.resW / sModel.sysScale) * uiScale, sH = (sModel.resH / sModel.sysScale) * uiScale;
                            let mW = (mModel.resW / mModel.sysScale) * uiScale, mH = (mModel.resH / mModel.sysScale) * uiScale;
                            let minX = Math.min(sModel.uiX, mModel.uiX), minY = Math.min(sModel.uiY, mModel.uiY);
                            let maxX = Math.max(sModel.uiX + sW, mModel.uiX + mW), maxY = Math.max(sModel.uiY + sH, mModel.uiY + mH);
                            return Math.min(1.8, Math.min(340 / ((maxX - minX) + 80), 240 / ((maxY - minY) + 80)));
                        }
                        property real offsetX: {
                            if (monitorsModel.count < 2) return 0;
                            let sModel = monitorsModel.get(stationaryIndex), mModel = monitorsModel.get(activeEditIndex);
                            let sW = (sModel.resW / sModel.sysScale) * uiScale, mW = (mModel.resW / mModel.sysScale) * uiScale;
                            let minX = Math.min(sModel.uiX, mModel.uiX), maxX = Math.max(sModel.uiX + sW, mModel.uiX + mW);
                            return 190 - ((minX + (maxX - minX) / 2) * targetScale);
                        }
                        property real offsetY: {
                            if (monitorsModel.count < 2) return 0;
                            let sModel = monitorsModel.get(stationaryIndex), mModel = monitorsModel.get(activeEditIndex);
                            let sH = (sModel.resH / sModel.sysScale) * uiScale, mH = (mModel.resH / mModel.sysScale) * uiScale;
                            let minY = Math.min(sModel.uiY, mModel.uiY), maxY = Math.max(sModel.uiY + sH, mModel.uiY + mH);
                            return 140 - ((minY + (maxY - minY) / 2) * targetScale);
                        }

                        Item {
                            id: transformNode
                            x: multiMonitorView.offsetX; y: multiMonitorView.offsetY
                            scale: multiMonitorView.targetScale; transformOrigin: Item.TopLeft
                            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                            Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                            Repeater {
                                model: monitorsModel
                                Item {
                                    property bool isActive: activeEditIndex === index
                                    Rectangle {
                                        id: monitorCard
                                        x: model.uiX; y: model.uiY
                                        width: (model.resW / model.sysScale) * uiScale
                                        height: (model.resH / model.sysScale) * uiScale
                                        radius: 8; color: isActive ? window.surface1 : window.crust
                                        border.color: isActive ? selectedResAccent : window.surface2
                                        border.width: isActive ? 2 : 1; z: isActive ? 5 : 0
                                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                        Behavior on border.color { ColorAnimation { duration: 300 } }
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                                        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                                        Item {
                                            anchors.centerIn: parent; width: 110; height: 80
                                            property real idealScale: Math.min(1.2, parent.width / 110, parent.height / 80) / transformNode.scale
                                            property real maxPhysicalScale: Math.min((parent.width * 0.9) / width, (parent.height * 0.9) / height)
                                            scale: Math.min(idealScale, maxPhysicalScale)
                                            ColumnLayout {
                                                anchors.centerIn: parent; spacing: 2
                                                StyledText { Layout.alignment: Qt.AlignHCenter; font.family: Appearance.font.family.iconNerd; font.pixelSize: 32; color: isActive ? selectedResAccent : window.text_; text: "󰍹"; Behavior on color { ColorAnimation { duration: 300 } } }
                                                StyledText { Layout.alignment: Qt.AlignHCenter; font.family: Appearance.font.family.monospace; font.weight: Font.Black; font.pixelSize: 13; color: window.text_; text: model.name }
                                                StyledText { Layout.alignment: Qt.AlignHCenter; font.family: Appearance.font.family.monospace; font.pixelSize: 10; color: window.subtext0; text: model.resW + "x" + model.resH + " @ " + model.rate + "Hz" }
                                            }
                                        }
                                    }
                                    // Ghost dragger
                                    Item {
                                        id: ghostDrag; x: model.uiX; y: model.uiY
                                        width: monitorCard.width; height: monitorCard.height; z: isActive ? 10 : 1
                                        MouseArea {
                                            anchors.fill: parent; drag.target: ghostDrag; drag.axis: Drag.XAndYAxis
                                            onPressed: { activeEditIndex = index; ghostDrag.x = model.uiX; ghostDrag.y = model.uiY; }
                                            onPositionChanged: {
                                                if (drag.active && monitorsModel.count === 2) {
                                                    let sIdx = stationaryIndex, sModel = monitorsModel.get(sIdx);
                                                    let sW = (sModel.resW / sModel.sysScale) * uiScale, sH = (sModel.resH / sModel.sysScale) * uiScale;
                                                    let mW = monitorCard.width, mH = monitorCard.height;
                                                    let padding = 40;
                                                    ghostDrag.x = Math.max(sModel.uiX - mW - padding, Math.min(ghostDrag.x, sModel.uiX + sW + padding));
                                                    ghostDrag.y = Math.max(sModel.uiY - mH - padding, Math.min(ghostDrag.y, sModel.uiY + sH + padding));
                                                    let snapped = getPerimeterSnap(ghostDrag.x, ghostDrag.y, sModel.uiX, sModel.uiY, sW, sH, mW, mH, 20);
                                                    monitorsModel.setProperty(index, "uiX", snapped.x);
                                                    monitorsModel.setProperty(index, "uiY", snapped.y);
                                                }
                                            }
                                            onReleased: { ghostDrag.x = model.uiX; ghostDrag.y = model.uiY; }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ═════════════════════════════════════════════════════════════
            // RIGHT: Resolution & Refresh Rate
            // ═════════════════════════════════════════════════════════════
            Item {
                anchors.left: leftVisualArea.right; anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10; anchors.rightMargin: 30; height: 310

                SequentialAnimation {
                    id: menuTransitionAnim
                    ParallelAnimation {
                        ScaleAnimator { target: rightSideContainer; from: 0.99; to: 1.0; duration: 200; easing.type: Easing.OutSine }
                        NumberAnimation { target: highlightFlash; property: "opacity"; from: 0.05; to: 0.0; duration: 250; easing.type: Easing.OutQuad }
                    }
                }

                Rectangle {
                    id: highlightFlash
                    anchors.fill: rightSideContainer; anchors.margins: -10
                    color: selectedResAccent; opacity: 0.0; radius: 12
                }

                ColumnLayout {
                    id: rightSideContainer
                    anchors.fill: parent; spacing: 12

                    // Resolution cards
                    GridLayout {
                        Layout.fillWidth: true; columns: 2; columnSpacing: 10; rowSpacing: 10
                        Repeater {
                            model: [
                                { resW: 3840, resH: 2160, label: "4K",   accent: accentPink },
                                { resW: 2560, resH: 1440, label: "QHD",  accent: accentMauve },
                                { resW: 1920, resH: 1080, label: "FHD",  accent: accentBlue },
                                { resW: 1600, resH: 900,  label: "HD+",  accent: accentTeal },
                                { resW: 1366, resH: 768,  label: "WXGA", accent: accentYellow },
                                { resW: 1280, resH: 720,  label: "HD",   accent: accentPeach },
                                { resW: 1024, resH: 768,  label: "XGA",  accent: accentGreen },
                                { resW: 800,  resH: 600,  label: "SVGA", accent: accentRed }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 48; radius: Appearance.rounding.small
                                property bool isSel: monitorsModel.count > 0 && monitorsModel.get(activeEditIndex).resW === modelData.resW && monitorsModel.get(activeEditIndex).resH === modelData.resH
                                property color accentColor: modelData.accent
                                color: isSel ? Qt.alpha(accentColor, 0.15) : (resMa.containsMouse ? window.surface0 : window.mantle)
                                border.color: isSel ? accentColor : (resMa.containsMouse ? window.surface1 : "transparent"); border.width: isSel ? 2 : 1
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 8
                                    StyledText { font.family: Appearance.font.family.monospace; font.weight: isSel ? Font.Black : Font.Bold; font.pixelSize: 16; color: isSel ? accentColor : window.text_; text: modelData.label; Behavior on color { ColorAnimation { duration: 200 } } }
                                    Item { Layout.fillWidth: true }
                                    StyledText { font.family: Appearance.font.family.monospace; font.pixelSize: 12; color: isSel ? window.text_ : window.overlay0; text: modelData.resW + "x" + modelData.resH; Behavior on color { ColorAnimation { duration: 200 } } }
                                }
                                scale: resMa.pressed ? 0.96 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
                                MouseArea {
                                    id: resMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (monitorsModel.count > 0) {
                                            selectedResAccent = accentColor;
                                            monitorsModel.setProperty(activeEditIndex, "resW", modelData.resW);
                                            monitorsModel.setProperty(activeEditIndex, "resH", modelData.resH);
                                            delayedLayoutUpdate.restart();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 15 }

                    // Refresh rate slider
                    Item {
                        id: sliderContainer
                        Layout.fillWidth: true; Layout.preferredHeight: 50
                        Layout.leftMargin: 10; Layout.rightMargin: 10
                        property var rates: [60, 75, 100, 120, 144, 240]
                        property var rateColors: [accentRed, accentMauve, accentBlue, accentBlue, accentTeal, accentGreen]
                        property int currentIndex: {
                            if (monitorsModel.count === 0) return 0;
                            let currentVal = parseInt(monitorsModel.get(activeEditIndex).rate) || 60;
                            let closestIdx = 0, minDiff = 9999;
                            for (let i = 0; i < rates.length; i++) { let diff = Math.abs(rates[i] - currentVal); if (diff < minDiff) { minDiff = diff; closestIdx = i; } }
                            return closestIdx;
                        }
                        property real visualPct: currentIndex / (rates.length - 1)
                        onCurrentIndexChanged: { if (!sliderMa.pressed) visualPct = currentIndex / (rates.length - 1); }

                        Rectangle {
                            id: track
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; verticalCenterOffset: -10 }
                            height: 12; radius: 6; color: window.mantle; border.color: window.crust; border.width: 1
                            Rectangle { width: knob.x + knob.width / 2; height: parent.height; radius: parent.radius; color: selectedRateAccent; Behavior on color { ColorAnimation { duration: 200 } } }
                        }
                        Repeater {
                            model: sliderContainer.rates.length
                            Item {
                                x: (index / (sliderContainer.rates.length - 1)) * track.width; y: track.y + 20
                                StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: sliderContainer.rates[index]; font.family: Appearance.font.family.monospace; font.pixelSize: 13; font.weight: sliderContainer.currentIndex === index ? Font.Bold : Font.Normal; color: sliderContainer.currentIndex === index ? selectedRateAccent : window.overlay0; Behavior on color { ColorAnimation { duration: 200 } } }
                            }
                        }
                        Rectangle {
                            id: knob; width: 24; height: 24; radius: 12
                            color: sliderMa.containsPress ? selectedRateAccent : window.text_
                            anchors.verticalCenter: track.verticalCenter
                            x: (sliderContainer.visualPct * track.width) - width / 2
                            Behavior on x { enabled: !sliderMa.pressed; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            border.width: sliderMa.containsMouse ? 4 : 0; border.color: Qt.alpha(selectedRateAccent, 0.3)
                            Behavior on border.width { NumberAnimation { duration: 150 } }
                        }
                        MouseArea {
                            id: sliderMa; anchors.fill: parent; anchors.margins: -15; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            function updateSelection(mouseX, snapToGrid) {
                                if (monitorsModel.count === 0) return;
                                let pct = Math.max(0, Math.min(1, (mouseX - track.x) / track.width));
                                let idx = Math.round(pct * (sliderContainer.rates.length - 1));
                                sliderContainer.visualPct = snapToGrid ? idx / (sliderContainer.rates.length - 1) : pct;
                                monitorsModel.setProperty(activeEditIndex, "rate", sliderContainer.rates[idx].toString());
                                selectedRateAccent = sliderContainer.rateColors[idx];
                            }
                            onPressed: (mouse) => updateSelection(mouse.x, false)
                            onPositionChanged: (mouse) => { if (pressed) updateSelection(mouse.x, false) }
                            onReleased: (mouse) => updateSelection(mouse.x, true)
                            onCanceled: () => sliderContainer.visualPct = sliderContainer.currentIndex / (sliderContainer.rates.length - 1)
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // ═════════════════════════════════════════════════════════════
            // Apply Button
            // ═════════════════════════════════════════════════════════════
            Item {
                id: applyButtonContainer
                anchors { bottom: parent.bottom; right: parent.right; margins: 30 }
                width: 170; height: 50

                MultiEffect {
                    source: applyBtn; anchors.fill: applyBtn
                    shadowEnabled: true; shadowColor: selectedRateAccent
                    shadowBlur: applyHovered ? 1.2 : 0.6; shadowOpacity: applyHovered ? 0.6 : 0.2
                    shadowVerticalOffset: 4; z: -1
                    Behavior on shadowBlur { NumberAnimation { duration: 300 } }
                    Behavior on shadowOpacity { NumberAnimation { duration: 300 } }
                    Behavior on shadowColor { ColorAnimation { duration: 400 } }
                }

                Rectangle {
                    id: applyBtn; anchors.fill: parent; radius: 25
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: selectedResAccent; Behavior on color { ColorAnimation { duration: 400 } } }
                        GradientStop { position: 1.0; color: selectedRateAccent; Behavior on color { ColorAnimation { duration: 400 } } }
                    }
                    scale: applyPressed ? 0.94 : (applyHovered ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                    Rectangle {
                        id: flashRect; anchors.fill: parent; radius: 25; color: window.text_; opacity: 0.0
                        PropertyAnimation on opacity { id: applyFlashAnim; to: 0.0; duration: 400; easing.type: Easing.OutExpo }
                    }

                    RowLayout {
                        anchors.centerIn: parent; spacing: 8
                        StyledText { font.family: Appearance.font.family.iconNerd; font.pixelSize: 20; color: window.crust; text: "󰸵" }
                        StyledText { font.family: Appearance.font.family.monospace; font.weight: Font.Black; font.pixelSize: 14; color: window.crust; text: monitorsModel.count > 1 ? "Apply All" : "Apply" }
                    }
                }

                MouseArea {
                    anchors.fill: parent; z: 10; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: applyHovered = true; onExited: applyHovered = false
                    onPressed: applyPressed = true; onReleased: applyPressed = false; onCanceled: applyPressed = false
                    onClicked: {
                        flashRect.opacity = 0.8; applyFlashAnim.start();
                        if (monitorsModel.count === 0) return;
                        if (monitorsModel.count === 1) {
                            let mon = monitorsModel.get(0);
                            let monitorStr = mon.name + "," + mon.resW + "x" + mon.resH + "@" + mon.rate + ",auto," + mon.sysScale;
                            Quickshell.execDetached(["notify-send", "Display Update", "Applied: " + mon.resW + "x" + mon.resH + " @ " + mon.rate + "Hz"]);
                            Quickshell.execDetached(["sh", "-c", "hyprctl keyword monitor " + monitorStr]);
                        } else {
                            let rects = [];
                            for (let i = 0; i < monitorsModel.count; i++) {
                                let m = monitorsModel.get(i);
                                rects.push({ x: m.uiX / uiScale, y: m.uiY / uiScale, w: Math.round(m.resW / m.sysScale), h: Math.round(m.resH / m.sysScale), resW: m.resW, resH: m.resH, name: m.name, rate: m.rate, sysScale: m.sysScale });
                            }
                            if (rects.length === 2) {
                                let r0 = rects[0], r1 = rects[1];
                                let snapped = getPerimeterSnap(r1.x, r1.y, r0.x, r0.y, r0.w, r0.h, r1.w, r1.h, 200);
                                r1.x = Math.round(snapped.x); r1.y = Math.round(snapped.y);
                            }
                            let finalMinX = 999999, finalMinY = 999999;
                            for (let i = 0; i < rects.length; i++) { if (rects[i].x < finalMinX) finalMinX = rects[i].x; if (rects[i].y < finalMinY) finalMinY = rects[i].y; }
                            let batchCmds = [], summaryString = "";
                            for (let i = 0; i < rects.length; i++) {
                                let r = rects[i];
                                r.x = Math.round((r.x - finalMinX) + originalLayoutOriginX);
                                r.y = Math.round((r.y - finalMinY) + originalLayoutOriginY);
                                batchCmds.push("keyword monitor " + r.name + "," + r.resW + "x" + r.resH + "@" + r.rate + "," + r.x + "x" + r.y + "," + r.sysScale);
                                summaryString += r.name + " ";
                            }
                            Quickshell.execDetached(["sh", "-c", "hyprctl --batch '" + batchCmds.join(" ; ") + "'"]);
                            Quickshell.execDetached(["notify-send", "Display Update", "Applied layout for: " + summaryString]);
                        }
                        GlobalStates.displayManagerOpen = false;
                    }
                }
            }
        }
    }
}

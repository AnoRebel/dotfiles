import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

/**
 * Popout panel anchored beneath/above the AnoSpot pill that lists items
 * staged in the AnoSpotStash, with action buttons for LocalSend / Open /
 * Copy path / Move / Reveal, plus any user-defined dropTargets rules from
 * Config.options.anoSpot.dropTargets.
 *
 * UI states (footerStack.current):
 *   "actions"    — default toolbar, one button per action
 *   "localsend"  — device discovery + selection list (replaces toolbar
 *                  while a scan is in progress or devices are listed)
 */
Scope {
    id: root

    readonly property bool open: GlobalStates.anoSpotStashOpen
    readonly property string spotPosition: Config.options?.anoSpot?.position ?? "top"
    readonly property bool spotIsVertical: spotPosition === "left" || spotPosition === "right"

    // Auto-close when the stash empties.
    Connections {
        target: AnoSpotStash
        function onEmptyChanged() {
            if (AnoSpotStash.empty) GlobalStates.anoSpotStashOpen = false;
        }
    }

    Variants {
        model: root.open ? Quickshell.screens : []

        PanelWindow {
            id: popoutWindow
            required property var modelData
            screen: modelData

            visible: root.open
            color: "transparent"

            implicitWidth: 380
            implicitHeight: 460

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:anospot:stash"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            // Anchor opposite the spot. If spot is top, popout drops down
            // from the top edge; if bottom, popout rises from the bottom.
            // For left/right spots we anchor to the same vertical edge.
            anchors {
                top: root.spotPosition === "top" || root.spotIsVertical
                bottom: root.spotPosition === "bottom" || root.spotIsVertical
                left: root.spotPosition === "left"
                right: root.spotPosition === "right"
            }
            margins {
                top: root.spotPosition === "top" ? 56 : 0  // clear the pill (~36px + gap)
                bottom: root.spotPosition === "bottom" ? 56 : 0
                left: root.spotPosition === "left" ? 56 : 0
                right: root.spotPosition === "right" ? 56 : 0
            }

            // Click-outside-to-close scrim. Layer-shell exclusionMode is
            // Ignore so we don't fight the bar; the scrim is invisible but
            // catches clicks anywhere outside the card.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: GlobalStates.anoSpotStashOpen = false
            }

            // The card itself
            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 380
                height: 460
                radius: Appearance?.rounding?.normal ?? 14
                color: Appearance?.colors?.colLayer0 ?? "#1e1e2e"
                // Glass-token opt-in for the popout surface. Inner cells
                // remain solid (Layer1) so the layered look reads cleanly
                // even with translucent themes like aurora/angel.
                border.width: Appearance?.glassTokens?.borderWidth ?? 1
                border.color: Appearance?.glassTokens?.borderColor
                            ?? Appearance?.colors?.colOutlineVariant
                            ?? "#444"
                opacity: Appearance?.glassTokens?.opacity ?? 1

                // Swallow clicks on the card so the scrim doesn't close it.
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // ─── Header: title + count + total size ───────────────
                    ColumnLayout {
                        id: headerCol
                        spacing: 2
                        Layout.fillWidth: true

                        RowLayout {
                            spacing: 8
                            MaterialSymbol {
                                text: "inventory_2"
                                iconSize: 18
                                color: Appearance?.colors?.colPrimary ?? "#a6e3a1"
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: "Stash"
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
                            }
                            StyledText {
                                text: `${AnoSpotStash.count} ${AnoSpotStash.count === 1 ? "item" : "items"} · ${AnoSpotStash.totalSizeText}`
                                font.pixelSize: 11
                                opacity: 0.7
                                color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
                            }
                        }
                    }

                    // ─── Item grid ────────────────────────────────────────
                    GridView {
                        id: grid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        cellWidth: 110
                        cellHeight: 100
                        clip: true
                        model: AnoSpotStash.items

                        delegate: Item {
                            id: cellRoot
                            width: grid.cellWidth - 6
                            height: grid.cellHeight - 6

                            required property string fileURL
                            required property string filePath
                            required property string name
                            required property bool isDir
                            required property string sizeText

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: Appearance?.colors?.colLayer1 ?? "#2b2930"
                                border.width: 1
                                border.color: Appearance?.colors?.colOutlineVariant ?? "#44444466"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 4

                                    // Thumbnail (image preview if it's an image, icon otherwise)
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 50

                                        Image {
                                            id: thumb
                                            anchors.fill: parent
                                            source: cellRoot.isDir ? "" : cellRoot.fileURL
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            cache: true
                                            visible: status === Image.Ready
                                            sourceSize.width: 200
                                            sourceSize.height: 100
                                        }
                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            visible: !thumb.visible
                                            text: cellRoot.isDir ? "folder" : "draft"
                                            iconSize: 32
                                            color: Appearance?.colors?.colOnLayer0Subtle ?? "#a6adc8"
                                        }
                                    }

                                    // Filename (elided)
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: cellRoot.name
                                        font.pixelSize: 10
                                        elide: Text.ElideMiddle
                                        horizontalAlignment: Text.AlignHCenter
                                        color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
                                    }
                                    // Size
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: cellRoot.sizeText
                                        font.pixelSize: 9
                                        opacity: 0.6
                                        horizontalAlignment: Text.AlignHCenter
                                        color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
                                    }
                                }

                                // Per-item × removal button (top-right corner)
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 2
                                    width: 18; height: 18
                                    radius: 9
                                    color: removeMa.containsMouse
                                        ? (Appearance?.colors?.colError ?? "#f38ba8")
                                        : Qt.rgba(0, 0, 0, 0.4)
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: 12
                                        color: "#ffffff"
                                    }
                                    MouseArea {
                                        id: removeMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AnoSpotStash.remove(cellRoot.filePath)
                                    }
                                }
                            }
                        }
                    }

                    // ─── Footer: actions toolbar ↔ LocalSend picker ──────
                    Loader {
                        id: footerLoader
                        Layout.fillWidth: true
                        property string mode: "actions"   // "actions" | "localsend"
                        sourceComponent: mode === "localsend" ? localsendComp : actionsComp

                        // When the popout closes, snap back to actions mode.
                        Connections {
                            target: GlobalStates
                            function onAnoSpotStashOpenChanged() {
                                if (!GlobalStates.anoSpotStashOpen) {
                                    footerLoader.mode = "actions";
                                    AnoSpotStash.localSendStop();
                                }
                            }
                        }
                    }

                    // ─── Action toolbar ──────────────────────────────────
                    Component {
                        id: actionsComp
                        ColumnLayout {
                            spacing: 6

                            // Built-in actions row 1
                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                AnoSpotActionButton {
                                    icon: "send"; label: "LocalSend"
                                    accent: Appearance?.colors?.colPrimary ?? "#a6e3a1"
                                    onActivated: {
                                        footerLoader.mode = "localsend";
                                        AnoSpotStash.localSendDiscover();
                                    }
                                }
                                AnoSpotActionButton {
                                    icon: "open_in_new"; label: "Open"
                                    onActivated: AnoSpotStash.openAll()
                                }
                                AnoSpotActionButton {
                                    icon: "content_copy"; label: "Copy path"
                                    onActivated: AnoSpotStash.copyPaths()
                                }
                                AnoSpotActionButton {
                                    icon: "drive_file_move"; label: "Move to…"
                                    onActivated: moveToProc.running = true
                                }
                                AnoSpotActionButton {
                                    icon: "folder_open"; label: "Reveal"
                                    onActivated: AnoSpotStash.revealFirst()
                                }
                            }

                            // Custom user-defined rules (each renders as a button)
                            Flow {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: customRulesRepeater.count > 0

                                Repeater {
                                    id: customRulesRepeater
                                    model: Config.options?.anoSpot?.dropTargets ?? []

                                    AnoSpotActionButton {
                                        required property var modelData
                                        icon: modelData.icon ?? "play_arrow"
                                        label: modelData.name ?? "Custom"
                                        onActivated: AnoSpotStash.runCustomRule(modelData)
                                    }
                                }
                            }

                            // Bottom row: clear-all
                            RowLayout {
                                Layout.fillWidth: true
                                Item { Layout.fillWidth: true }

                                RippleButton {
                                    implicitHeight: 30
                                    buttonRadius: 8
                                    colBackground: Appearance?.colors?.colLayer1 ?? "#2b2930"
                                    contentItem: RowLayout {
                                        spacing: 6
                                        MaterialSymbol {
                                            text: "delete_sweep"; iconSize: 14
                                            color: Appearance?.colors?.colError ?? "#f38ba8"
                                        }
                                        StyledText {
                                            text: "Clear all"; font.pixelSize: 11
                                            color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
                                        }
                                    }
                                    onClicked: AnoSpotStash.clear()
                                }
                            }
                        }
                    }

                    // ─── LocalSend picker ────────────────────────────────
                    Component {
                        id: localsendComp
                        ColumnLayout {
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                MaterialSymbol {
                                    text: "wifi_find"; iconSize: 14
                                    color: Appearance?.colors?.colPrimary ?? "#a6e3a1"
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: AnoSpotStash.discoverState === "scanning"
                                        ? "Scanning for LocalSend devices…"
                                        : (AnoSpotStash.discoveredDevices.count === 0
                                            ? "No devices found on this network"
                                            : `${AnoSpotStash.discoveredDevices.count} device${AnoSpotStash.discoveredDevices.count === 1 ? "" : "s"} found`)
                                    font.pixelSize: 11
                                    color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
                                }
                                RippleButton {
                                    implicitHeight: 26
                                    buttonRadius: 6
                                    contentItem: RowLayout {
                                        spacing: 4
                                        MaterialSymbol { text: "refresh"; iconSize: 12 }
                                        StyledText { text: "Rescan"; font.pixelSize: 11 }
                                    }
                                    onClicked: AnoSpotStash.localSendDiscover()
                                }
                                RippleButton {
                                    implicitHeight: 26
                                    buttonRadius: 6
                                    contentItem: RowLayout {
                                        spacing: 4
                                        MaterialSymbol { text: "arrow_back"; iconSize: 12 }
                                        StyledText { text: "Back"; font.pixelSize: 11 }
                                    }
                                    onClicked: {
                                        AnoSpotStash.localSendStop();
                                        footerLoader.mode = "actions";
                                    }
                                }
                            }

                            // Device list
                            ListView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(120, contentHeight)
                                clip: true
                                model: AnoSpotStash.discoveredDevices
                                spacing: 4

                                delegate: Rectangle {
                                    width: ListView.view ? ListView.view.width : 0
                                    height: 32
                                    radius: 6
                                    color: deviceMa.containsMouse
                                        ? (Appearance?.colors?.colLayer2 ?? "#3a3845")
                                        : (Appearance?.colors?.colLayer1 ?? "#2b2930")
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    required property string alias
                                    required property string ip

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6
                                        MaterialSymbol {
                                            text: "smartphone"; iconSize: 14
                                            color: Appearance?.colors?.colPrimary ?? "#a6e3a1"
                                        }
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: parent.parent.alias
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
                                        }
                                        StyledText {
                                            text: parent.parent.ip
                                            font.pixelSize: 10
                                            opacity: 0.55
                                            color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
                                        }
                                    }

                                    MouseArea {
                                        id: deviceMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            AnoSpotStash.localSendAll(parent.ip);
                                            // Return to actions; user sees notify-send for results.
                                            footerLoader.mode = "actions";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Move-to picker via zenity. User picks a directory; we mv every
            // staged item there and refresh the stash. Out of band of the
            // service so that the popout stays free of zenity coupling.
            Process {
                id: moveToProc
                command: ["bash", "-c",
                    "set -e; " +
                    "dir=$(zenity --file-selection --directory --title='Move stashed items to…' 2>/dev/null) || exit 0; " +
                    "[ -z \"$dir\" ] && exit 0; " +
                    "for f in '" + AnoSpotStash.stashDir.replace(/'/g, "'\\''") + "'/*; do " +
                    "  [ -e \"$f\" ] && mv -f -- \"$f\" \"$dir/\" || true; " +
                    "done"]
                onExited: AnoSpotStash.refresh()
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) GlobalStates.anoSpotStashOpen = false;
            }
        }
    }
}

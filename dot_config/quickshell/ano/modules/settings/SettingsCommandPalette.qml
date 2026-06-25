import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import "."

/**
 * Ctrl+K command palette over the Settings UI.
 *
 * Opens via SettingsKeyHandler. Search query is matched against
 * SettingsRegistry.entries (dotted config paths + page names + camel-
 * case-split tokens). Multi-word queries AND all terms together,
 * case-insensitive.
 *
 * Selecting an entry:
 *   1. Switches the parent shell's currentPage to the entry's pageIndex.
 *   2. After the page Loader has the new page mounted (Loader.onLoaded),
 *      walks the loaded page for a SettingsCard whose configKeys covers
 *      the entry's key, and animates the page flickable to its position.
 *
 * The host shell wires:
 *   - currentPage / pageCount inputs
 *   - pageRequested(idx) signal — called when user picks an entry
 *   - flickable property — the StyledFlickable wrapping the page
 *     content, used for scroll-to-card
 */
Loader {
    id: root

    property int currentPage: 0
    property int pageCount: 1
    property var flickable: null

    // Set by host — typically a binding to the page Loader's item
    // (so the palette can walk the active page's SettingsCard children).
    property var activePageItem: null

    signal pageRequested(int index)
    signal closed()

    active: GlobalStates.settingsCommandPaletteOpen
    visible: active

    sourceComponent: paletteComponent

    Component {
        id: paletteComponent

        Rectangle {
            id: scrim
            anchors.fill: parent

            // Parent fills the whole Settings panel — the Loader's parent
            // is whatever the host shell anchors it to. Scrim dims the
            // page behind.
            color: Qt.rgba(0, 0, 0, 0.55)

            opacity: GlobalStates.settingsCommandPaletteOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            // Click-to-close on the scrim
            MouseArea {
                anchors.fill: parent
                onClicked: root._close()
            }

            // The palette card itself — clicks inside don't propagate to scrim
            Rectangle {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Math.max(60, parent.height * 0.12)
                width: Math.min(640, parent.width * 0.8)
                implicitHeight: contentCol.implicitHeight + 24
                radius: Appearance?.rounding.normal ?? 14
                color: Appearance?.m3colors.m3surfaceContainerHigh ?? "#2B2930"
                border.width: 1
                border.color: Appearance?.colors.colOutlineVariant ?? "#49454F"

                // Stop click propagation from inside the card to the scrim
                MouseArea { anchors.fill: parent; preventStealing: true }

                ColumnLayout {
                    id: contentCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 8

                    // ── Query input ─────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        MaterialSymbol {
                            text: "search"
                            iconSize: 18
                            color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                        }
                        StyledTextInput {
                            id: input
                            Layout.fillWidth: true
                            font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                            text: SettingsRegistry.query
                            onTextChanged: {
                                SettingsRegistry.query = text;
                                paletteList.currentIndex = SettingsRegistry.results.length > 0 ? 0 : -1;
                            }
                            focus: true

                            // Up/Down move the highlighted result; Enter activates;
                            // Esc closes. Plain ASCII Tab/Shift+Tab also move.
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                    paletteList.currentIndex = Math.min(
                                        SettingsRegistry.results.length - 1,
                                        paletteList.currentIndex + 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                    paletteList.currentIndex = Math.max(0, paletteList.currentIndex - 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root._activateCurrent();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    root._close();
                                    event.accepted = true;
                                }
                            }
                        }
                        StyledText {
                            text: `${SettingsRegistry.results.length} match${SettingsRegistry.results.length === 1 ? "" : "es"}`
                            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 12
                            opacity: 0.55
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Appearance?.colors.colOutlineVariant ?? "#49454F"
                        opacity: 0.4
                    }

                    // ── Results list ────────────────────────────────────
                    Loader {
                        Layout.fillWidth: true
                        active: SettingsRegistry.results.length === 0 && (SettingsRegistry.query || "").length > 0
                        visible: active
                        sourceComponent: StyledText {
                            text: "No matches"
                            opacity: 0.55
                            font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                    }

                    ListView {
                        id: paletteList
                        objectName: "settingsPaletteList"
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(420, contentHeight)
                        clip: true
                        model: SettingsRegistry.results
                        currentIndex: 0
                        keyNavigationEnabled: false  // input handles keys
                        boundsBehavior: Flickable.StopAtBounds
                        spacing: 2

                        delegate: Rectangle {
                            id: paletteDelegate
                            required property int index
                            required property var modelData
                            width: paletteList.width
                            implicitHeight: 44
                            radius: Appearance?.rounding.small ?? 8
                            color: paletteList.currentIndex === paletteDelegate.index
                                ? (Appearance?.colors.colSecondaryContainer ?? "#3F3957")
                                : (paletteMA.containsMouse
                                    ? (Appearance?.colors.colLayer1Hover ?? "#3C3947")
                                    : "transparent")
                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 10

                                MaterialSymbol {
                                    text: paletteDelegate.modelData.pageIcon
                                    iconSize: 18
                                    color: Appearance?.colors.colSubtext ?? "#CAC4D0"
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    StyledText {
                                        text: paletteDelegate.modelData.key
                                        font.pixelSize: Appearance?.font.pixelSize.small ?? 14
                                        font.family: Appearance?.font.family.mono ?? "monospace"
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                    StyledText {
                                        text: paletteDelegate.modelData.pageName
                                        font.pixelSize: Appearance?.font.pixelSize.smaller ?? 11
                                        opacity: 0.55
                                    }
                                }

                                MaterialSymbol {
                                    visible: paletteList.currentIndex === paletteDelegate.index
                                    text: "keyboard_return"
                                    iconSize: 14
                                    opacity: 0.6
                                }
                            }

                            MouseArea {
                                id: paletteMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    paletteList.currentIndex = paletteDelegate.index;
                                    root._activateCurrent();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Activation ────────────────────────────────────────────────────

    function _close() {
        GlobalStates.settingsCommandPaletteOpen = false;
        root.closed();
    }

    function _activateCurrent() {
        const list = root._findByObjectName(root.item, "settingsPaletteList");
        const idx = list ? list.currentIndex : -1;
        if (idx < 0 || idx >= SettingsRegistry.results.length) return;
        const entry = SettingsRegistry.results[idx];
        root.pageRequested(entry.pageIndex);
        // Scroll-to-card after the page Loader swaps in the new page.
        // We use a one-shot Timer because activePageItem is bound through
        // the host shell, and the new page may not exist yet on this tick.
        scrollPendingTimer.targetKey = entry.key;
        scrollPendingTimer.restart();
        root._close();
    }

    function _findByObjectName(item, name) {
        if (!item) return null;
        const stack = [item];
        while (stack.length > 0) {
            const cur = stack.shift();
            if (!cur) continue;
            if (cur.objectName === name) return cur;
            const children = cur.children || [];
            for (const c of children) stack.push(c);
        }
        return null;
    }

    // After page-switch, find the SettingsCard whose configKeys covers
    // the target key and scroll the host flickable to it.
    Timer {
        id: scrollPendingTimer
        interval: 80   // give the Loader time to materialise the new page
        repeat: false
        property string targetKey: ""
        onTriggered: {
            if (!root.flickable || !root.activePageItem || targetKey.length === 0) return;
            const card = root._findCardForKey(root.activePageItem, targetKey);
            if (!card) return;
            // Compute card's y in the flickable's content coordinate space
            const cardPos = card.mapToItem(root.flickable.contentItem, 0, 0);
            const target = Math.max(0, Math.min(
                root.flickable.contentHeight - root.flickable.height,
                cardPos.y - 16));
            // Animate via direct property assignment (StyledFlickable
            // doesn't expose an animated scroll method).
            scrollAnim.from = root.flickable.contentY;
            scrollAnim.to = target;
            scrollAnim.start();
        }
    }

    NumberAnimation {
        id: scrollAnim
        target: root.flickable
        property: "contentY"
        duration: 320
        easing.type: Easing.OutCubic
    }

    // Walk the page's children for a SettingsCard whose configKeys
    // contains the target key (or its top-level root). Returns the first
    // matching card item.
    function _findCardForKey(pageItem, key) {
        if (!pageItem) return null;
        const top = key.split(".")[0];
        const stack = [pageItem];
        while (stack.length > 0) {
            const cur = stack.shift();
            if (!cur) continue;
            // Detect SettingsCard: it has a `configKeys` property (added
            // by us) and a `title` property. Cheap duck-type check.
            if (cur.configKeys !== undefined && Array.isArray(cur.configKeys)) {
                for (const ck of cur.configKeys) {
                    if (ck === key || ck === top || key.startsWith(ck + ".")) {
                        return cur;
                    }
                }
            }
            const children = cur.children || [];
            for (const c of children) stack.push(c);
        }
        return null;
    }
}

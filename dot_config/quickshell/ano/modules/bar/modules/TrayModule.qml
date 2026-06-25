pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

/**
 * System tray bar module — shows pinned + unpinned items with full DBus menu
 * and pin/unpin support. Right-click opens the app's context menu.
 */
Item {
    id: root
    implicitWidth: trayRow.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    property var activeMenu: null

    function setActiveMenu(menuWindow) {
        if (root.activeMenu && root.activeMenu !== menuWindow) {
            if (typeof root.activeMenu.close === "function")
                root.activeMenu.close();
        }
        root.activeMenu = menuWindow;
    }

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 2

        // Overflow button for unpinned items
        Loader {
            active: TrayService.unpinnedItems.length > 0
            visible: active
            Layout.alignment: Qt.AlignVCenter

            sourceComponent: Item {
                implicitWidth: 20; implicitHeight: 20

                property bool overflowOpen: false

                MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 16
                    text: "expand_more"
                    color: Appearance.colors.colOnLayer1
                    rotation: parent.overflowOpen ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.overflowOpen = !parent.overflowOpen
                }

                StyledPopup {
                    shown: parent.overflowOpen
                    popupWidth: overflowGrid.implicitWidth + 24
                    popupHeight: overflowGrid.implicitHeight + 24

                    GridLayout {
                        id: overflowGrid
                        anchors.centerIn: parent
                        columns: Math.ceil(Math.sqrt(TrayService.unpinnedItems.length))
                        columnSpacing: 8; rowSpacing: 8

                        Repeater {
                            model: TrayService.unpinnedItems
                            delegate: TrayIcon {
                                required property var modelData
                                item: modelData
                                onMenuOpened: (win) => root.setActiveMenu(win)
                            }
                        }
                    }
                }
            }
        }

        // Pinned items
        Repeater {
            model: ScriptModel { values: TrayService.pinnedItems }

            delegate: TrayIcon {
                required property SystemTrayItem modelData
                item: modelData
                Layout.alignment: Qt.AlignVCenter
                onMenuOpened: (win) => root.setActiveMenu(win)
            }
        }
    }

    // ─── Inner component: single tray icon with menu ────────────────────
    component TrayIcon: MouseArea {
        id: trayIcon
        required property SystemTrayItem item
        signal menuOpened(qsWindow: var)

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        implicitWidth: 24; implicitHeight: 24

        onPressed: (event) => {
            switch (event.button) {
            case Qt.LeftButton:
                item.activate();
                break;
            case Qt.RightButton:
                if (item.hasMenu) {
                    if (menuLoader.active && menuLoader.item && typeof menuLoader.item.close === "function")
                        menuLoader.item.close();
                    else
                        menuLoader.active = true;
                }
                break;
            }
            event.accepted = true;
        }

        IconImage {
            anchors.fill: parent
            source: trayIcon.item.icon
            implicitSize: 24
            asynchronous: true
            mipmap: true
        }

        StyledToolTip {
            text: TrayService.getTooltipForItem(trayIcon.item)
        }

        Loader {
            id: menuLoader
            active: false
            sourceComponent: SysTrayMenu {
                Component.onCompleted: this.open()
                trayItemMenuHandle: trayIcon.item.menu
                trayItemId: trayIcon.item.id
                trayItem: trayIcon.item
                anchor {
                    window: trayIcon.QsWindow.window
                    item: trayIcon
                    gravity: Edges.Bottom
                    edges: Edges.Bottom
                }
                onMenuOpened: (window) => trayIcon.menuOpened(window)
                onMenuClosed: menuLoader.active = false
            }
        }
    }
}

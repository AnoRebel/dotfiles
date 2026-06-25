pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

/**
 * System tray context menu with DBus menu rendering and pin/unpin support.
 * Uses StackView for submenu navigation. Right-click or Back to go back.
 * Adapted from end-4/ii for Ano Shell.
 */
PopupWindow {
    id: root
    required property QsMenuHandle trayItemMenuHandle
    property string trayItemId: ""
    property var trayItem: null

    signal menuClosed
    signal menuOpened(qsWindow: var)

    color: "transparent"
    property real padding: 8

    implicitHeight: {
        let result = 0;
        for (let child of stackView.children) {
            result = Math.max(child.implicitHeight, result);
        }
        return result + popupBackground.padding * 2 + root.padding * 2;
    }
    implicitWidth: {
        let result = 0;
        for (let child of stackView.children) {
            result = Math.max(child.implicitWidth, result);
        }
        return result + popupBackground.padding * 2 + root.padding * 2;
    }

    function open() {
        root.visible = true;
        root.menuOpened(root);
    }

    function close() {
        root.visible = false;
        while (stackView.depth > 1)
            stackView.pop();
        root.menuClosed();
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.RightButton
        onPressed: event => {
            if ((event.button === Qt.BackButton || event.button === Qt.RightButton) && stackView.depth > 1)
                stackView.pop();
        }

        Rectangle {
            id: popupBackground
            readonly property real padding: 4
            anchors {
                fill: parent
                margins: root.padding
            }

            color: Appearance?.colors.colLayer0 ?? "#1C1B1F"
            radius: Appearance?.rounding.normal ?? 12
            border.width: 1
            border.color: Appearance?.colors.colLayer0Border ?? "#44444488"
            clip: true

            opacity: 0
            Component.onCompleted: opacity = 1

            implicitWidth: stackView.implicitWidth + popupBackground.padding * 2
            implicitHeight: stackView.implicitHeight + popupBackground.padding * 2

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            StackView {
                id: stackView
                anchors { fill: parent; margins: popupBackground.padding }
                pushEnter: Transition { NumberAnimation { duration: 0 } }
                pushExit: Transition { NumberAnimation { duration: 0 } }
                popEnter: Transition { NumberAnimation { duration: 0 } }
                popExit: Transition { NumberAnimation { duration: 0 } }

                implicitWidth: currentItem.implicitWidth
                implicitHeight: currentItem.implicitHeight

                initialItem: SubMenu { handle: root.trayItemMenuHandle }
            }
        }
    }

    component SubMenu: ColumnLayout {
        id: submenu
        required property QsMenuHandle handle
        property bool isSubMenu: false
        property bool shown: false
        opacity: shown ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: destroy()

        QsMenuOpener {
            id: menuOpener
            menu: submenu.handle
        }

        spacing: 0

        // Back button (visible in submenus)
        Loader {
            Layout.fillWidth: true
            visible: submenu.isSubMenu
            active: visible
            sourceComponent: RippleButton {
                id: backButton
                buttonRadius: popupBackground.radius - popupBackground.padding
                horizontalPadding: 12
                implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
                implicitHeight: 36
                downAction: () => stackView.pop()
                contentItem: RowLayout {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: backButton.horizontalPadding; rightMargin: backButton.horizontalPadding }
                    spacing: 8
                    MaterialSymbol { iconSize: 20; text: "chevron_left" }
                    StyledText { Layout.fillWidth: true; text: "Back" }
                }
            }
        }

        // Pin/Unpin button (only at root menu level)
        RippleButton {
            id: pinEntry
            buttonRadius: popupBackground.radius - popupBackground.padding
            horizontalPadding: 12
            implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
            implicitHeight: 36
            Layout.fillWidth: true
            visible: root.trayItem !== null && stackView.depth === 1
            releaseAction: () => { if (root.trayItem) TrayService.togglePin(root.trayItem) }
            contentItem: RowLayout {
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: pinEntry.horizontalPadding; rightMargin: pinEntry.horizontalPadding }
                spacing: 8
                MaterialSymbol { iconSize: 18; text: "push_pin" }
                StyledText { Layout.fillWidth: true; text: root.trayItem && TrayService.isPinned(root.trayItem) ? "Unpin" : "Pin" }
            }
        }

        // Separator after pin button
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 1
            color: Appearance?.m3colors.m3outlineVariant ?? "#44444488"
            Layout.topMargin: 4; Layout.bottomMargin: 4
            visible: pinEntry.visible
        }

        // Menu entries
        Repeater {
            id: menuEntriesRepeater
            property bool iconColumnNeeded: {
                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    if (menuOpener.children.values[i].icon.length > 0) return true;
                }
                return false;
            }
            property bool specialInteractionColumnNeeded: {
                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    if (menuOpener.children.values[i].buttonType !== QsMenuButtonType.None) return true;
                }
                return false;
            }
            model: menuOpener.children
            delegate: SysTrayMenuEntry {
                required property QsMenuEntry modelData
                forceIconColumn: menuEntriesRepeater.iconColumnNeeded
                forceSpecialInteractionColumn: menuEntriesRepeater.specialInteractionColumnNeeded
                menuEntry: modelData
                buttonRadius: popupBackground.radius - popupBackground.padding
                onDismiss: root.close()
                onOpenSubmenu: handle => {
                    stackView.push(subMenuComponent.createObject(null, { handle: handle, isSubMenu: true }));
                }
            }
        }
    }

    Component {
        id: subMenuComponent
        SubMenu {}
    }
}

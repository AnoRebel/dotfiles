pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

/**
 * Single entry in a system tray DBus menu.
 * Supports: labels, icons, checkboxes, radio buttons, separators, submenus.
 * Adapted from end-4/ii for Ano Shell.
 */
RippleButton {
    id: root
    required property QsMenuEntry menuEntry
    property bool forceIconColumn: false
    property bool forceSpecialInteractionColumn: false
    readonly property bool hasIcon: menuEntry.icon.length > 0
    readonly property bool hasSpecialInteraction: menuEntry.buttonType !== QsMenuButtonType.None

    signal dismiss()
    signal openSubmenu(handle: QsMenuHandle)

    enabled: !menuEntry.isSeparator
    opacity: 1

    horizontalPadding: 12
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: menuEntry.isSeparator ? 1 : 36
    Layout.topMargin: menuEntry.isSeparator ? 4 : 0
    Layout.bottomMargin: menuEntry.isSeparator ? 4 : 0
    Layout.fillWidth: true

    Component.onCompleted: {
        if (menuEntry.isSeparator) {
            root.buttonColor = Appearance.m3colors.m3outlineVariant ?? "#44444488";
        }
    }

    releaseAction: () => {
        if (menuEntry.hasChildren) {
            root.openSubmenu(root.menuEntry);
            return;
        }
        menuEntry.triggered();
        root.dismiss();
    }
    altAction: (event) => { event.accepted = false; }

    contentItem: RowLayout {
        id: contentItem
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left; right: parent.right
            leftMargin: root.horizontalPadding; rightMargin: root.horizontalPadding
        }
        spacing: 8
        visible: !root.menuEntry.isSeparator

        // Checkbox/radio indicator
        Item {
            visible: root.hasSpecialInteraction || root.forceSpecialInteractionColumn
            implicitWidth: 20; implicitHeight: 20

            Loader {
                anchors.fill: parent
                active: root.menuEntry.buttonType === QsMenuButtonType.CheckBox && root.menuEntry.checkState !== Qt.Unchecked
                sourceComponent: MaterialSymbol {
                    text: root.menuEntry.checkState === Qt.PartiallyChecked ? "check_indeterminate_small" : "check"
                    iconSize: 20
                }
            }
            Loader {
                anchors.fill: parent
                active: root.menuEntry.buttonType === QsMenuButtonType.RadioButton && root.menuEntry.checkState === Qt.Checked
                sourceComponent: MaterialSymbol {
                    text: "radio_button_checked"
                    iconSize: 20
                }
            }
        }

        // Icon
        Item {
            visible: root.hasIcon || root.forceIconColumn
            implicitWidth: 20; implicitHeight: 20
            Loader {
                anchors.centerIn: parent
                active: root.menuEntry.icon.length > 0
                sourceComponent: IconImage {
                    asynchronous: true
                    source: root.menuEntry.icon
                    implicitSize: 20
                    mipmap: true
                }
            }
        }

        // Label
        StyledText {
            text: root.menuEntry.text
            Layout.fillWidth: true
        }

        // Submenu arrow
        Loader {
            active: root.menuEntry.hasChildren
            sourceComponent: MaterialSymbol { text: "chevron_right"; iconSize: 20 }
        }
    }
}

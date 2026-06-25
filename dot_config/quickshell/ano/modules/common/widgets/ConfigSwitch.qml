import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * A settings row with a label and a StyledSwitch on the right.
 */
ConfigRow {
    id: root
    property alias checked: toggleSwitch.checked

    StyledSwitch {
        id: toggleSwitch
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
    }
}

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Privacy indicator — visible only when an active microphone or
 * screen-sharing stream is detected via Privacy.qml. Available as
 * bar module ID "privacy".
 *
 * Spec: ano-deferred-features-batch-2026 ▸ bar-status-indicators.
 */
Item {
    id: root

    readonly property bool active: Privacy.micActive || Privacy.screenSharing
    visible: active
    implicitWidth: visible ? row.implicitWidth + 12 : 0
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: Privacy.screenSharing ? "screen_share" : "mic"
            iconSize: 16
            // Distinct accent so the indicator reads as a privacy alert,
            // not just another bar widget.
            color: Appearance?.colors.colError ?? "#f38ba8"
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        StyledToolTip {
            text: {
                const parts = []
                if (Privacy.micActive) parts.push("Microphone in use")
                if (Privacy.screenSharing) parts.push("Screen sharing active")
                return parts.join(" • ") || "Privacy indicator"
            }
        }
    }
}

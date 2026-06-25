import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "."

RowLayout {
    id: wsRow
    spacing: 4

    visible: Config.options?.anoSpot?.showWorkspace ?? true

    readonly property int wsIndex: CompositorService.activeWorkspaceIndex
    readonly property string wsName: CompositorService.activeWorkspaceName
    readonly property bool hoverPreviewEnabled:
        Config.options?.anoSpot?.workspaceHoverPreview?.enable ?? true

    MaterialSymbol {
        text: "view_carousel"
        iconSize: 14
        color: Appearance?.colors?.colSecondary ?? "#cba6f7"
    }

    StyledText {
        text: {
            // Show name if non-empty and non-numeric; otherwise the index.
            if (wsRow.wsName && isNaN(parseInt(wsRow.wsName))) return wsRow.wsName;
            return String(wsRow.wsIndex);
        }
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Appearance?.colors?.colOnLayer0 ?? "#cdd6f4"
    }

    // Open-delay timer — hover briefly without triggering the preview;
    // commit only after the user dwells on the chip. Avoids flicker on
    // accidental cursor passes across AnoSpot.
    Timer {
        id: openDelayTimer
        interval: Config.options?.anoSpot?.workspaceHoverPreview?.openDelayMs ?? 200
        repeat: false
        onTriggered: {
            if (wsRow.hoverPreviewEnabled && wsHoverArea.containsMouse)
                GlobalStates.anoSpotWorkspacePreviewOpen = true
        }
    }

    // Click + hover. Click opens AnoView (existing behavior); hover with
    // dwell opens the inline thumbnail popup. Cursor leaving cancels the
    // pending open without closing an already-open popup — the popup's
    // own close-delay timer handles dismissal so the user can travel
    // between widget and popup.
    MouseArea {
        id: wsHoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onEntered: {
            if (wsRow.hoverPreviewEnabled) openDelayTimer.restart()
        }
        onExited: openDelayTimer.stop()
        onClicked: Quickshell.execDetached(["qs", "-c", "ano", "ipc", "call", "anoview", "toggle"])
    }
}

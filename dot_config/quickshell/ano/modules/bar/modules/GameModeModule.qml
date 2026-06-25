import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * GameMode indicator — visible only when gamemoded reports an active
 * client. Available as bar module ID "gamemode".
 *
 * The detector itself is read-only; activation is handled externally
 * (libgamemode-aware games or the user's ~/.config/hypr/scripts/gamemode
 * helper). The bar widget just surfaces "we're in game mode" so the
 * user isn't surprised that animations/blur/etc. are off.
 *
 * Spec: ano-deferred-features-batch-2026 ▸ bar-status-indicators.
 */
Item {
    id: root

    visible: GameMode.active
    implicitWidth: visible ? row.implicitWidth + 12 : 0
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: "videogame_asset"
            iconSize: 16
            color: Appearance?.colors.colPrimary ?? "#a6e3a1"
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        StyledToolTip {
            text: GameMode.clientCount > 0
                ? `Game mode active · ${GameMode.clientCount} client${GameMode.clientCount === 1 ? "" : "s"}`
                : "Game mode active"
        }
    }
}

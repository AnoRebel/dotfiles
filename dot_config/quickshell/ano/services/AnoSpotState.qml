pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.services

/**
 * Aggregator for AnoSpot widgets. Surfaces a single derived state per slot
 * so the UI binds against one source. No external IPC, no state files —
 * everything is driven by reactive QML bindings against existing ano services.
 *
 * Slots:
 *   mpris            — current track (title/artist/art) or null
 *   latestNotification — most recent notification within notificationTimeoutMs, or null
 *   recording        — { active, elapsedSeconds }
 *   clockWeather     — { time, weather } (always present)
 */
Singleton {
    id: root

    // ─── Mpris ────────────────────────────────────────────────────────────
    readonly property var mpris: {
        const t = MprisController.activeTrack;
        if (!t) return null;
        return {
            title: t.title ?? "",
            artist: t.artist ?? "",
            artUrl: t.artUrl ?? "",
            playing: MprisController.activePlayer?.isPlaying ?? false
        };
    }

    // ─── Latest notification (transient) ──────────────────────────────────
    property var latestNotification: null

    readonly property int notificationTimeoutMs: Config.options?.anoSpot?.notificationTimeoutMs ?? 4000

    Connections {
        target: Notifications
        function onNotify(n) {
            root.latestNotification = {
                appName: n?.appName ?? "",
                summary: n?.summary ?? "",
                body: n?.body ?? "",
                appIcon: n?.appIcon ?? ""
            };
            notificationClearTimer.restart();
        }
    }

    Timer {
        id: notificationClearTimer
        interval: root.notificationTimeoutMs
        repeat: false
        onTriggered: root.latestNotification = null
    }

    // ─── Recording ────────────────────────────────────────────────────────
    readonly property var recording: ({
        active: RecorderStatus.isRecording,
        elapsedSeconds: RecorderStatus.elapsedSeconds
    })

    // ─── Clock + Weather ──────────────────────────────────────────────────
    readonly property var clockWeather: ({
        time: DateTime.time ?? "",
        date: DateTime.shortDate ?? "",
        weatherTemp: Weather.data?.temp ?? "",
        weatherCode: Weather.data?.wCode ?? ""
    })
}

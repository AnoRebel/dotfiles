pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * Aggregate network throughput across all non-loopback interfaces by
 * polling /proc/net/dev. Exposes:
 *   downloadSpeed / uploadSpeed   bytes per second (instantaneous)
 *   downloadTotal / uploadTotal   bytes since service start
 *   downloadHistory / uploadHistory   plain JS arrays of recent speeds
 *                                     (length up to historyLength) for
 *                                     sparklines
 *
 * Plus formatBytes(b) and formatBytesTotal(b) helpers returning
 * {value, unit} for UI rendering.
 *
 * Service is dormant when Config.options.network.usage.enable is false
 * (the default — opt in when a UI surface needs the data).
 *
 * Adapted from caelestia/services/NetworkUsage.qml. Changes:
 *   - Caelestia.Internal.CircularBuffer replaced with a plain JS array
 *     trimmed to historyLength on each push (no QML-side consumer needs
 *     a typed CircularBuffer for ano's surfaces today).
 *   - Caelestia.Config.GlobalConfig replaced with
 *     Config.options.network.usage.{enable, intervalMs}.
 *   - Ref-counting Timer dropped in favour of the simpler enable-flag
 *     gate, consistent with other ano services (e.g. RecorderStatus).
 */
Singleton {
    id: root

    readonly property bool serviceEnabled: Config.options?.network?.usage?.enable ?? false
    readonly property int intervalMs: Config.options?.network?.usage?.intervalMs ?? 1000
    readonly property int historyLength: Config.options?.network?.usage?.historyLength ?? 30

    // Current speeds in bytes per second
    property real downloadSpeed: 0
    property real uploadSpeed: 0

    // Total bytes transferred since service start
    property real downloadTotal: 0
    property real uploadTotal: 0

    // Sparkline history
    property var downloadHistory: []
    property var uploadHistory: []

    // Internal accounting
    property real _prevRxBytes: 0
    property real _prevTxBytes: 0
    property real _prevTimestamp: 0
    property real _initialRxBytes: 0
    property real _initialTxBytes: 0
    property bool _initialized: false

    function formatBytes(bytes) {
        if (bytes < 0 || isNaN(bytes) || !isFinite(bytes))
            return { value: 0, unit: "B/s" };
        if (bytes < 1024)              return { value: bytes,                       unit: "B/s"  };
        if (bytes < 1024 * 1024)       return { value: bytes / 1024,                unit: "KB/s" };
        if (bytes < 1024 * 1024 * 1024) return { value: bytes / (1024 * 1024),       unit: "MB/s" };
        return                                { value: bytes / (1024 * 1024 * 1024), unit: "GB/s" };
    }

    function formatBytesTotal(bytes) {
        if (bytes < 0 || isNaN(bytes) || !isFinite(bytes))
            return { value: 0, unit: "B" };
        if (bytes < 1024)              return { value: bytes,                       unit: "B"  };
        if (bytes < 1024 * 1024)       return { value: bytes / 1024,                unit: "KB" };
        if (bytes < 1024 * 1024 * 1024) return { value: bytes / (1024 * 1024),       unit: "MB" };
        return                                { value: bytes / (1024 * 1024 * 1024), unit: "GB" };
    }

    function parseNetDev(content) {
        const lines = (content || "").split("\n");
        let totalRx = 0;
        let totalTx = 0;
        for (let i = 2; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line) continue;
            const parts = line.split(/\s+/);
            if (parts.length < 10) continue;
            const iface = parts[0].replace(":", "");
            if (iface === "lo") continue;
            totalRx += parseFloat(parts[1]) || 0;
            totalTx += parseFloat(parts[9]) || 0;
        }
        return { rx: totalRx, tx: totalTx };
    }

    function _push(arr, value) {
        const next = arr.slice();
        next.push(value);
        if (next.length > root.historyLength)
            next.shift();
        return next;
    }

    FileView {
        id: netDevFile
        path: "/proc/net/dev"
    }

    Timer {
        interval: root.intervalMs
        running: root.serviceEnabled && Config.ready
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            netDevFile.reload();
            const content = netDevFile.text();
            if (!content) return;

            const data = root.parseNetDev(content);
            const now = Date.now();

            if (!root._initialized) {
                root._initialRxBytes = data.rx;
                root._initialTxBytes = data.tx;
                root._prevRxBytes = data.rx;
                root._prevTxBytes = data.tx;
                root._prevTimestamp = now;
                root._initialized = true;
                return;
            }

            const timeDelta = (now - root._prevTimestamp) / 1000;
            if (timeDelta > 0) {
                let rxDelta = data.rx - root._prevRxBytes;
                let txDelta = data.tx - root._prevTxBytes;
                // Counter wrap (assume 64-bit)
                if (rxDelta < 0) rxDelta += Math.pow(2, 64);
                if (txDelta < 0) txDelta += Math.pow(2, 64);

                root.downloadSpeed = rxDelta / timeDelta;
                root.uploadSpeed = txDelta / timeDelta;

                if (root.downloadSpeed >= 0 && isFinite(root.downloadSpeed))
                    root.downloadHistory = root._push(root.downloadHistory, root.downloadSpeed);
                if (root.uploadSpeed >= 0 && isFinite(root.uploadSpeed))
                    root.uploadHistory = root._push(root.uploadHistory, root.uploadSpeed);
            }

            let downTotal = data.rx - root._initialRxBytes;
            let upTotal = data.tx - root._initialTxBytes;
            if (downTotal < 0) downTotal += Math.pow(2, 64);
            if (upTotal < 0)   upTotal += Math.pow(2, 64);
            root.downloadTotal = downTotal;
            root.uploadTotal = upTotal;

            root._prevRxBytes = data.rx;
            root._prevTxBytes = data.tx;
            root._prevTimestamp = now;
        }
    }
}

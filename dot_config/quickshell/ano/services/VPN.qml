pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * VPN connection status + control for the active configured provider.
 *
 * Supported providers: tailscale, netbird, warp (Cloudflare), wireguard,
 * plus a "custom" provider that lets users specify connectCmd /
 * disconnectCmd / interface in config. The active provider is the first
 * entry in Config.options.vpn.providers with enabled=true.
 *
 * Exposes:
 *   connected, connecting    state booleans
 *   status                   { connected, state, reason, authUrl }
 *   providerName             active provider id ("tailscale" / "netbird" / "warp" / "wireguard" / custom name)
 *   currentConfig            { connectCmd, disconnectCmd, interface, displayName }
 * Methods:
 *   connect(), disconnect(), toggle(), checkStatus()
 *
 * Status detection uses each provider's CLI (`tailscale status --json`,
 * `netbird status --json`, `warp-cli status`, `ip link show <iface>`)
 * and is automatically refreshed on `nmcli monitor` events.
 *
 * Adapted from caelestia/services/VPN.qml. Changes:
 *   - GlobalConfig.utilities.vpn.provider → Config.options.vpn.providers
 *   - Toaster.toast(...) calls dropped (caelestia-specific UI primitive
 *     not present in ano). State transitions log to console; UI surfaces
 *     can subscribe to status changes for their own toasts.
 *   - GlobalConfig.utilities.toasts.vpnChanged read replaced with
 *     Config.options.vpn.notifyOnChange flag (default true).
 *
 * Service is dormant when no provider in Config.options.vpn.providers
 * has enabled=true, OR when Config.options.vpn.enable is false.
 */
Singleton {
    id: root

    property bool connected: false
    property var status: ({
            connected: false,
            state: "disconnected",
            reason: "",
            authUrl: ""
        })

    readonly property bool connecting: connectProc.running || disconnectProc.running
    readonly property bool serviceEnabled: Config.options?.vpn?.enable ?? true
    readonly property var providers: Config.options?.vpn?.providers ?? []
    readonly property bool enabled: serviceEnabled && providers.some(p => typeof p === "object" ? (p.enabled === true) : false)
    readonly property var providerInput: {
        const enabledProvider = providers.find(p => typeof p === "object" ? (p.enabled === true) : false);
        return enabledProvider || "wireguard";
    }
    readonly property bool isCustomProvider: typeof providerInput === "object"
    readonly property string providerName: isCustomProvider ? (providerInput.name || "custom") : String(providerInput)
    readonly property string interfaceName: isCustomProvider ? (providerInput.interface || "") : ""
    readonly property var currentConfig: {
        const name = providerName;
        const iface = interfaceName;
        const defaults = getBuiltinDefaults(name, iface);

        if (isCustomProvider) {
            const custom = providerInput;
            return {
                connectCmd: custom.connectCmd || defaults.connectCmd,
                disconnectCmd: custom.disconnectCmd || defaults.disconnectCmd,
                interface: custom.interface || defaults.interface,
                displayName: custom.displayName || defaults.displayName
            };
        }

        return defaults;
    }

    function getBuiltinDefaults(name, iface) {
        const builtins = {
            "wireguard": {
                connectCmd: ["pkexec", "wg-quick", "up", iface],
                disconnectCmd: ["pkexec", "wg-quick", "down", iface],
                interface: iface,
                displayName: iface
            },
            "warp": {
                connectCmd: ["warp-cli", "connect"],
                disconnectCmd: ["warp-cli", "disconnect"],
                interface: "CloudflareWARP",
                displayName: "Warp"
            },
            "netbird": {
                connectCmd: ["netbird", "up", "--no-browser"],
                disconnectCmd: ["netbird", "down"],
                interface: "wt0",
                displayName: "NetBird"
            },
            "tailscale": {
                connectCmd: ["tailscale", "up"],
                disconnectCmd: ["tailscale", "down"],
                interface: "tailscale0",
                displayName: "Tailscale"
            }
        };

        return builtins[name] || {
            connectCmd: [name, "up"],
            disconnectCmd: [name, "down"],
            interface: iface || name,
            displayName: name
        };
    }

    function connect(): void {
        if (status.state === "needs-auth" && status.authUrl) {
            console.log(lc, "VPN auth required, URL:", status.authUrl);
            return;
        }
        if (!connected && !connecting && root.currentConfig && root.currentConfig.connectCmd) {
            connectProc.exec(root.currentConfig.connectCmd);
        }
    }

    function disconnect(): void {
        if (connected && !connecting && root.currentConfig && root.currentConfig.disconnectCmd) {
            disconnectProc.exec(root.currentConfig.disconnectCmd);
        }
    }

    function toggle(): void {
        connected ? disconnect() : connect();
    }

    function checkStatus(): void {
        if (root.enabled) {
            statusProc.running = true;
        }
    }

    function getStatusCommand(): var {
        switch (providerName) {
        case "tailscale":
            return ["tailscale", "status", "--json"];
        case "netbird":
            return ["netbird", "status", "--json"];
        case "warp":
            return ["warp-cli", "status"];
        case "wireguard":
            return ["ip", "link", "show"];
        default:
            return ["ip", "link", "show"];
        }
    }

    function parseTailscaleStatus(output: string): var {
        const status = { connected: false, state: "disconnected", reason: "", authUrl: "" };
        if (!output || output.trim().length === 0) return status;
        if (output.includes("Logged out") || output.includes("Stopped") || output.includes("not running") || output.includes("Tailscale is not running")) {
            status.state = "disconnected";
            return status;
        }
        try {
            const data = JSON.parse(output);
            const backendState = data.BackendState || "";
            if (backendState === "Running") {
                status.connected = true;
                status.state = "connected";
            } else if (backendState === "Starting") {
                status.state = "connecting";
            } else if (backendState === "NeedsLogin" || backendState === "NeedsMachineAuth") {
                status.state = "needs-auth";
                status.reason = backendState === "NeedsLogin" ? "Login required" : "Machine authorization required";
                status.authUrl = data.AuthURL || "";
            }
        } catch (e) {
            if (output.includes("error") || output.includes("Error") || output.includes("failed")) {
                status.state = "disconnected";
                status.reason = "Tailscale may not be running";
            } else {
                status.state = "disconnected";
            }
        }
        return status;
    }

    function parseNetBirdStatus(output: string): var {
        const status = { connected: false, state: "disconnected", reason: "", authUrl: "" };
        try {
            const data = JSON.parse(output);
            const mgmtConnected = data.management?.connected;
            const signalConnected = data.signal?.connected;
            if (mgmtConnected && signalConnected) {
                status.connected = true;
                status.state = "connected";
            } else if (data.management?.error) {
                const error = data.management.error;
                if (error.includes("auth") || error.includes("login")) {
                    status.state = "needs-auth";
                    status.reason = "Authentication required";
                } else {
                    status.reason = error;
                }
            }
        } catch (e) {
            status.state = "error";
            status.reason = "Failed to parse status";
        }
        return status;
    }

    function parseWarpStatus(output: string): var {
        const status = { connected: false, state: "disconnected", reason: "", authUrl: "" };
        if (output.includes("Connected")) {
            status.connected = true;
            status.state = "connected";
        } else if (output.includes("Connecting")) {
            status.state = "connecting";
        } else if (output.includes("Unable") || output.includes("Registration Missing") || output.includes("registration") || output.includes("register")) {
            status.state = "needs-auth";
            status.reason = "WARP registration required";
        } else if (!output.includes("Disconnected")) {
            status.state = "error";
            status.reason = "Unknown WARP status";
        }
        return status;
    }

    function parseWireGuardStatus(output: string): var {
        const status = { connected: false, state: "disconnected", reason: "", authUrl: "" };
        const iface = root.currentConfig?.interface || "";
        if (iface && output.includes(iface + ":")) {
            status.connected = true;
            status.state = "connected";
        }
        return status;
    }

    function parseStatusOutput(output: string): var {
        switch (providerName) {
        case "tailscale": return parseTailscaleStatus(output);
        case "netbird":   return parseNetBirdStatus(output);
        case "warp":      return parseWarpStatus(output);
        case "wireguard":
        default:          return parseWireGuardStatus(output);
        }
    }

    function extractAuthUrl(text: string): string {
        const urlMatch = text.match(/(https?:\/\/[^\s]+)/);
        return urlMatch ? urlMatch[1] : "";
    }

    function createAuthStatus(authUrl: string): var {
        return { connected: false, state: "needs-auth", reason: "Authentication required", authUrl: authUrl };
    }

    function updateStatus(newStatus: var): void {
        const oldState = status.state;
        if (newStatus.state === "needs-auth" && !newStatus.authUrl && status.authUrl) {
            newStatus.authUrl = status.authUrl;
        }
        status = newStatus;
        root.connected = newStatus.connected;
        if (oldState !== newStatus.state) {
            console.log(lc, `VPN state ${oldState} -> ${newStatus.state}`,
                        newStatus.reason ? `(${newStatus.reason})` : "");
        }
    }

    onProviderNameChanged: {
        status = { connected: false, state: "disconnected", reason: "", authUrl: "" };
        root.connected = false;
        statusCheckTimer.start();
    }

    Component.onCompleted: root.enabled && statusCheckTimer.start()

    Process {
        id: nmMonitor
        running: root.enabled
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: statusCheckTimer.restart()
        }
    }

    Process {
        id: statusProc
        command: root.getStatusCommand()
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: StdioCollector {
            onStreamFinished: {
                const newStatus = root.parseStatusOutput(text);
                root.updateStatus(newStatus);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    if (text.includes("doesn't appear to be running") ||
                        text.includes("failed to connect to local tailscaled") ||
                        text.includes("daemon is not running") ||
                        (text.includes("not running") && (text.includes("netbird") || text.includes("warp")))) {
                        let cmd = "sudo systemctl start ";
                        switch (root.providerName) {
                        case "tailscale": cmd += "tailscaled"; break;
                        case "netbird":   cmd += "netbird"; break;
                        case "warp":      cmd += "warp-svc"; break;
                        default:          cmd += root.providerName + "d"; break;
                        }
                        root.updateStatus({
                            connected: false,
                            state: "disconnected",
                            reason: `Service not running (run: ${cmd})`,
                            authUrl: ""
                        });
                    }
                }
            }
        }
    }

    Process {
        id: connectProc
        onExited: exitCode => {
            if (exitCode !== 0) return;
            if (root.providerName === "tailscale") {
                Qt.callLater(() => {
                    if (root.status.state !== "needs-auth") statusCheckTimer.start();
                });
            } else if (root.status.state !== "needs-auth") {
                statusCheckTimer.start();
            }
        }
        stdout: SplitParser {
            onRead: data => {
                const authUrl = root.extractAuthUrl(data);
                if (authUrl) root.updateStatus(root.createAuthStatus(authUrl));
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error.includes("Access denied") || error.includes("checkprefs access denied")) {
                    root.updateStatus({
                        connected: false,
                        state: "disconnected",
                        reason: "Permission denied. Run in terminal: sudo tailscale set --operator=$USER",
                        authUrl: ""
                    });
                    return;
                }
                if (error.includes("Unknown device type") || error.includes("Protocol not supported")) {
                    root.updateStatus({
                        connected: false,
                        state: "disconnected",
                        reason: "WireGuard module not loaded. Run: sudo modprobe wireguard",
                        authUrl: ""
                    });
                    return;
                }
                const authUrl = root.extractAuthUrl(error);
                if (authUrl) {
                    root.updateStatus(root.createAuthStatus(authUrl));
                } else if (error.includes("already exists")) {
                    root.connected = true;
                }
            }
        }
    }

    Process {
        id: disconnectProc
        onExited: statusCheckTimer.start()
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && !error.includes("[#]"))
                    console.warn(lc, "Disconnection error:", error);
            }
        }
    }

    Process {
        id: warpRegisterProc
        onExited: exitCode => {
            if (exitCode === 0) statusCheckTimer.start();
        }
    }

    Connections {
        target: root
        function onStatusChanged() {
            if (root.providerName === "warp" &&
                root.status.state === "needs-auth" &&
                (root.status.reason || "").includes("registration")) {
                warpRegisterProc.exec(["warp-cli", "registration", "new"]);
            }
        }
    }

    Timer {
        id: statusCheckTimer
        interval: 500
        onTriggered: root.checkStatus()
    }

    LoggingCategory {
        id: lc
        name: "ano.services.vpn"
        defaultLogLevel: LoggingCategory.Info
    }
}

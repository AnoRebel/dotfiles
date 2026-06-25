pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common

/**
 * Shell-runtime detection + script-invocation helper.
 *
 * Resolution order for `current`:
 *   1. Config.options.shell.preferred — explicit user override (one of
 *      "bash" / "zsh" / "fish" / "nushell" / "" for auto)
 *   2. basename of $SHELL env var (your login shell)
 *   3. fallback: "bash"
 *
 * Use `wrap(scriptStem)` when you need to invoke an ano script that has
 * shell-specific variants in scripts/<scriptStem>.<ext>:
 *
 *   const argv = ShellExec.wrap("capture/capture-windows")
 *   //  -> ["zsh",  "/abs/path/scripts/capture/capture-windows.sh"]   (zsh, bash)
 *   //  -> ["fish", "/abs/path/scripts/capture/capture-windows.fish"] (fish)
 *   //  -> ["nu",   "/abs/path/scripts/capture/capture-windows.nu"]   (nushell)
 *
 * ano scripts ship with at minimum a .sh variant; .fish and .nu are
 * provided when the script genuinely needs shell-specific syntax (e.g.
 * fish's structured pipe-to-list semantics). When a non-bash variant
 * isn't present, wrap() falls back to running the .sh under the user's
 * preferred shell — both zsh and fish run a POSIX-compatible bash script
 * fine, nushell does not (so the .nu variant is required for nu users
 * if the script uses anything beyond simple commands).
 */
Singleton {
    id: root

    // Recognized shells. The order matters for autodetection sanity but
    // each is treated independently.
    readonly property var supported: ["bash", "zsh", "fish", "nushell"]

    readonly property string envShell: Quickshell.env("SHELL")

    // Strip path, lowercase, normalize "nu" → "nushell".
    readonly property string detected: {
        const env = String(envShell || "").trim();
        if (env.length === 0) return "bash";
        const base = env.replace(/^.*\//, "").toLowerCase();
        if (base === "nu") return "nushell";
        if (supported.indexOf(base) >= 0) return base;
        return "bash";
    }

    readonly property string preferred: {
        const p = String(Config.options?.shell?.preferred ?? "").trim().toLowerCase();
        if (supported.indexOf(p) >= 0) return p;
        return "";
    }

    readonly property string current: preferred.length > 0 ? preferred : detected
    readonly property bool isBash:    current === "bash"
    readonly property bool isZsh:     current === "zsh"
    readonly property bool isFish:    current === "fish"
    readonly property bool isNushell: current === "nushell"

    // Convenience predicates kept for parity with inir's `ShellExec.supportsFish()`.
    function supportsFish(): bool { return root.current === "fish" }
    function supportsNushell(): bool { return root.current === "nushell" }

    // Map a logical script stem (relative to scripts/) to its full path.
    // Resolves against the ano config root via Quickshell.shellPath().
    function _scriptPath(stem: string, ext: string): string {
        return Quickshell.shellPath("scripts/" + stem + "." + ext);
    }

    // Return the argv (interpreter + script-path) appropriate for the
    // current shell. See class header for the resolution rules.
    function wrap(stem: string): var {
        switch (root.current) {
            case "fish":
                return ["fish", _scriptPath(stem, "fish")];
            case "nushell":
                return ["nu", _scriptPath(stem, "nu")];
            case "zsh":
                // zsh runs sh-style scripts fine; no .zsh extension by convention.
                return ["zsh", _scriptPath(stem, "sh")];
            case "bash":
            default:
                return ["bash", _scriptPath(stem, "sh")];
        }
    }
}

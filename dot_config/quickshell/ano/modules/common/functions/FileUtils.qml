pragma Singleton
import Quickshell

Singleton {
    id: root

    // Remove "file://" protocol prefix from a path
    function trimFileProtocol(path) {
        if (typeof path !== "string") return "";
        if (path.startsWith("file://")) return path.substring(7);
        return path;
    }

    // Add "file://" protocol prefix if not present
    function ensureFileProtocol(path) {
        if (typeof path !== "string") return "";
        if (path.startsWith("file://")) return path;
        return "file://" + path;
    }

    // Get filename from path
    function basename(path) {
        if (typeof path !== "string") return "";
        let cleaned = trimFileProtocol(path);
        let parts = cleaned.split("/");
        return parts[parts.length - 1] || "";
    }

    // Get directory from path
    function dirname(path) {
        if (typeof path !== "string") return "";
        let cleaned = trimFileProtocol(path);
        let parts = cleaned.split("/");
        parts.pop();
        return parts.join("/");
    }

    // Get file extension (without dot)
    function extension(path) {
        let name = basename(path);
        let dotIndex = name.lastIndexOf(".");
        if (dotIndex <= 0) return "";
        return name.substring(dotIndex + 1).toLowerCase();
    }

    // Check if path looks like an image file
    function isImage(path) {
        let ext = extension(path);
        return ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "avif", "ico", "tiff"].indexOf(ext) >= 0;
    }

    // Check if path looks like a video file
    function isVideo(path) {
        let ext = extension(path);
        return ["mp4", "webm", "mkv", "avi", "mov", "wmv", "flv", "m4v"].indexOf(ext) >= 0;
    }

    // Join path components
    function joinPath() {
        let parts = [];
        for (let i = 0; i < arguments.length; i++) {
            let p = arguments[i];
            if (typeof p === "string" && p.length > 0) {
                parts.push(p.replace(/\/+$/, ""));
            }
        }
        return parts.join("/");
    }
}

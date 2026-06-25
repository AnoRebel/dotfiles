pragma Singleton
import Quickshell

Singleton {
    id: root

    // Deep merge two objects (source overrides target)
    function deepMerge(target, source) {
        if (!source || typeof source !== "object") return target;
        if (!target || typeof target !== "object") return source;
        let result = {};
        // Copy target properties
        for (let key in target) {
            if (target.hasOwnProperty(key)) {
                result[key] = target[key];
            }
        }
        // Merge source properties
        for (let key in source) {
            if (source.hasOwnProperty(key)) {
                if (typeof source[key] === "object" && source[key] !== null &&
                    !Array.isArray(source[key]) &&
                    typeof result[key] === "object" && result[key] !== null &&
                    !Array.isArray(result[key])) {
                    result[key] = deepMerge(result[key], source[key]);
                } else {
                    result[key] = source[key];
                }
            }
        }
        return result;
    }

    // Deep clone an object
    function deepClone(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

    // Get nested property by dot-separated path (e.g., "foo.bar.baz")
    function getNestedValue(obj, path, fallback) {
        if (!obj || typeof path !== "string") return fallback;
        let keys = path.split(".");
        let current = obj;
        for (let i = 0; i < keys.length; i++) {
            if (current === null || current === undefined) return fallback;
            current = current[keys[i]];
        }
        return (current === undefined || current === null) ? fallback : current;
    }

    // Set nested property by dot-separated path
    function setNestedValue(obj, path, value) {
        if (!obj || typeof path !== "string") return;
        let keys = path.split(".");
        let current = obj;
        for (let i = 0; i < keys.length - 1; i++) {
            if (!current[keys[i]] || typeof current[keys[i]] !== "object") {
                current[keys[i]] = {};
            }
            current = current[keys[i]];
        }
        current[keys[keys.length - 1]] = value;
    }

    // Check if object is empty
    function isEmpty(obj) {
        if (!obj) return true;
        if (Array.isArray(obj)) return obj.length === 0;
        if (typeof obj === "object") return Object.keys(obj).length === 0;
        return false;
    }

    // Pick specified keys from an object
    function pick(obj, keys) {
        let result = {};
        for (let i = 0; i < keys.length; i++) {
            if (obj.hasOwnProperty(keys[i])) {
                result[keys[i]] = obj[keys[i]];
            }
        }
        return result;
    }
}

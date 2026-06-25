pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

/**
 * Wallpaper service with directory browsing, random rotation,
 * thumbnail generation, and per-monitor wallpaper application.
 * Compositor-agnostic — uses swww/swaybg/hyprpaper via switchwall script.
 */
Singleton {
    id: root

    property alias directory: folderModel.folder
    readonly property string effectiveDirectory: FileUtils.trimFileProtocol(folderModel.folder.toString())
    property url defaultFolder: Qt.resolvedUrl(`${Directories.pictures}/Wallpapers`)
    property alias folderModel: folderModel
    property string searchQuery: ""
    readonly property list<string> extensions: [
        "jpg", "jpeg", "png", "webp", "avif", "bmp", "svg", "mp4", "mkv", "webm", "avi", "mov", "m4v", "ogv"
    ]
    property list<string> wallpapers: []
    readonly property bool thumbnailGenerationRunning: thumbgenProc.running
    property real thumbnailGenerationProgress: 0

    signal changed()
    signal thumbnailGenerated(directory: string)
    signal thumbnailGeneratedFile(filePath: string)

    function load() {} // Force initialization

    property list<string> videoExtensions: ["mp4", "mkv", "webm", "avi", "mov", "m4v", "ogv"]
    function isVideoFile(name) { return videoExtensions.some(ext => name.endsWith("." + ext)) }

    Process { id: applyProc }

    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready || !root.isVideoFile(Config.options.background.wallpaperPath.toLowerCase())) return
            root.apply(Config.options.background.wallpaperPath, Appearance.m3colors.darkmode)
        }
    }

    // Random wallpaper rotation
    property list<string> randomWallpaperList: []

    Timer {
        id: randomWallpaperTimer
        interval: Config.options.background.randomize.interval * 1000
        running: Config.options.background.randomize.enable && Config.options.background.randomize.directory.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.randomWallpaperList.length === 0) {
                getRandomWallpapersProc.running = true
            } else {
                const randomIndex = Math.floor(Math.random() * root.randomWallpaperList.length)
                root.apply(root.randomWallpaperList[randomIndex], Appearance.m3colors.darkmode)
            }
        }
    }

    Process {
        id: getRandomWallpapersProc
        property string expandedDir: Config.options.background.randomize.directory.replace(/^~/, Directories.home)
        command: ["find", expandedDir, "-type", "f", "-regex", ".*\\.\\(jpg\\|jpeg\\|png\\|webp\\|avif\\|bmp\\|svg\\|mp4\\|mkv\\|webm\\|avi\\|mov\\|m4v\\|ogv\\)"]
        stdout: StdioCollector {
            id: randomWallpapersCollector
            onStreamFinished: {
                const output = randomWallpapersCollector.text.trim()
                if (output.length > 0) {
                    root.randomWallpaperList = output.split("\n")
                    const randomIndex = Math.floor(Math.random() * root.randomWallpaperList.length)
                    root.apply(root.randomWallpaperList[randomIndex], Appearance.m3colors.darkmode)
                } else {
                    console.log("[Wallpapers] No wallpapers found in:", getRandomWallpapersProc.expandedDir)
                }
            }
        }
    }

    Connections {
        target: Config.options.background.randomize
        function onDirectoryChanged() {
            root.randomWallpaperList = []
            if (Config.options.background.randomize.enable && Config.options.background.randomize.directory.length > 0) {
                getRandomWallpapersProc.running = true
            }
        }
    }

    function apply(path, darkMode = Appearance.m3colors.darkmode, monitorName = "") {
        if (!path || path.length === 0) return
        const args = [Directories.wallpaperSwitchScriptPath, "--image", path, "--mode", darkMode ? "dark" : "light"]
        if (monitorName !== "") args.push("--monitor", monitorName)
        applyProc.exec(args)
        root.changed()
    }

    Process {
        id: selectProc
        property string filePath: ""
        property bool darkMode: Appearance.m3colors.darkmode
        property string monitorName: ""
        function select(fp, dm = Appearance.m3colors.darkmode, mn = "") {
            selectProc.filePath = fp; selectProc.darkMode = dm; selectProc.monitorName = mn
            selectProc.exec(["test", "-d", FileUtils.trimFileProtocol(fp)])
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) { setDirectory(selectProc.filePath); return }
            root.apply(selectProc.filePath, selectProc.darkMode, selectProc.monitorName)
        }
    }

    function select(filePath, darkMode = Appearance.m3colors.darkmode, monitorName = "") {
        selectProc.select(filePath, darkMode, monitorName)
    }

    function randomFromCurrentFolder(darkMode = Appearance.m3colors.darkmode, monitorName = "") {
        if (folderModel.count === 0) return
        const randomIndex = Math.floor(Math.random() * folderModel.count)
        root.select(folderModel.get(randomIndex, "filePath"), darkMode, monitorName)
    }

    Process {
        id: validateDirProc
        property string nicePath: ""
        function setDirectoryIfValid(path) {
            validateDirProc.nicePath = FileUtils.trimFileProtocol(path).replace(/\/+$/, "")
            if (/^\/*$/.test(validateDirProc.nicePath)) validateDirProc.nicePath = "/"
            validateDirProc.exec(["bash", "-c",
                `if [ -d "${validateDirProc.nicePath}" ]; then echo dir; elif [ -f "${validateDirProc.nicePath}" ]; then echo file; else echo invalid; fi`
            ])
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const result = text.trim()
                if (result === "dir") root.directory = Qt.resolvedUrl(validateDirProc.nicePath)
                else if (result === "file") root.directory = Qt.resolvedUrl(FileUtils.parentDirectory(validateDirProc.nicePath))
            }
        }
    }

    function setDirectory(path) { validateDirProc.setDirectoryIfValid(path) }
    function navigateUp() { folderModel.navigateUp() }

    FolderListModel {
        id: folderModel
        folder: Qt.resolvedUrl(root.defaultFolder)
        caseSensitive: false
        nameFilters: root.extensions.map(ext => `*.${ext}`)
        showDirs: true
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Time
        sortReversed: false
        onCountChanged: {
            root.wallpapers = []
            for (let i = 0; i < folderModel.count; i++) {
                const path = folderModel.get(i, "filePath") || FileUtils.trimFileProtocol(folderModel.get(i, "fileURL"))
                if (path && path.length) root.wallpapers.push(path)
            }
        }
    }

    // Thumbnail generation
    function generateThumbnail(size) {
        if (!["normal", "large", "x-large", "xx-large"].includes(size)) throw new Error("Invalid thumbnail size")
        thumbgenProc.running = false
        const scriptPath = `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/thumbgen-venv.sh`
        const fallbackPath = `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/generate-thumbnails-magick.sh`
        thumbgenProc.command = ["bash", "-c",
            `${scriptPath} --size ${size} --machine_progress -d ${effectiveDirectory} || ${fallbackPath} --size ${size} -d ${effectiveDirectory}`
        ]
        root.thumbnailGenerationProgress = 0
        thumbgenProc.running = true
    }

    Process {
        id: thumbgenProc
        stdout: SplitParser {
            onRead: data => {
                let match = data.match(/PROGRESS (\d+)\/(\d+)/)
                if (match) root.thumbnailGenerationProgress = parseInt(match[1]) / parseInt(match[2])
                match = data.match(/FILE (.+)/)
                if (match) root.thumbnailGeneratedFile(match[1])
            }
        }
        onExited: root.thumbnailGenerated(effectiveDirectory)
    }

    IpcHandler {
        target: "wallpapers"
        function apply(path: string): void { root.apply(path) }
    }
}

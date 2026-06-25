pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions
import QtCore
import QtQuick
import Quickshell

Singleton {
    id: root

    // XDG standard directories (with "file://" prefix)
    readonly property string home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]
    readonly property string genericCache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    readonly property string documents: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
    readonly property string downloads: StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
    readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    readonly property string music: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
    readonly property string videos: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]

    // Shell-specific paths (without "file://")
    property string assetsPath: Quickshell.shellPath("assets")
    property string scriptPath: Quickshell.shellPath("scripts")
    property string pluginsPath: Quickshell.shellPath("plugins")
    property string layoutsPath: Quickshell.shellPath("layouts")

    // Theme paths — bundled themes ship under assets/themes/<name>.json,
    // user themes drop into ~/.config/anoshell/themes/ (takes precedence on
    // name collision so users can override bundled themes by filename).
    property string bundledThemesPath: assetsPath + "/themes"
    property string userThemesPath: FileUtils.trimFileProtocol(`${root.config}/anoshell/themes`)

    // User-overrides directory — user-writable JSON config that's deep-merged
    // on top of the shell's bundled config.json. Survives shell upgrades.
    property string userConfigDir: FileUtils.trimFileProtocol(`${root.config}/anoshell`)
    property string userConfigPath: FileUtils.trimFileProtocol(`${root.config}/anoshell/config.json`)

    // Shell configuration directory (user-writable config, separate from shell source)
    property string shellConfig: FileUtils.trimFileProtocol(`${root.config}/anoshell`)

    // Config files — single config.json (not light/dark split like rebels)
    property string shellConfigPath: FileUtils.trimFileProtocol(Quickshell.shellPath("config.json"))

    // Cache directories for media
    property string favicons: FileUtils.trimFileProtocol(`${root.cache}/anoshell/media/favicons`)
    property string coverArt: FileUtils.trimFileProtocol(`${root.cache}/anoshell/media/coverart`)
    property string tempImages: "/tmp/quickshell-anoshell/media/images"
    property string screenshotTemp: "/tmp/quickshell-anoshell/media/screenshot"

    // User state files
    property string generatedMaterialThemePath: FileUtils.trimFileProtocol(`${root.state}/anoshell/generated/colors.json`)
    property string generatedWallpaperCategoryPath: FileUtils.trimFileProtocol(`${root.state}/anoshell/generated/wallpaper/category.txt`)
    property string notificationsPath: FileUtils.trimFileProtocol(`${root.cache}/anoshell/notifications/notifications.json`)
    property string cliphistDecode: FileUtils.trimFileProtocol("/tmp/quickshell-anoshell/media/cliphist")

    // Script paths
    property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${root.scriptPath}/colors/switchwall.sh`)

    // Wallpaper directory (user's wallpaper collection, configurable in settings)
    property string wallpaperDir: FileUtils.trimFileProtocol(`${root.pictures}/hyprwallpapers`)

    // Shell root
    // Quickshell 0.3 renamed shellRoot → shellDir. shellRoot still works but
    // emits a deprecation warning at load — use shellDir.
    property string shellRoot: FileUtils.trimFileProtocol(Quickshell.shellDir)

    // User avatar locations (common Linux conventions)
    // Priority: ~/.face → AccountsService → ~/.face.icon
    property string userAvatarPathFace: FileUtils.trimFileProtocol(`${root.home}/.face`)
    property string userAvatarPathFaceIcon: FileUtils.trimFileProtocol(`${root.home}/.face.icon`)
    // Quickshell 0.3 removed SystemInfo; fall back to the USER env var.
    readonly property string _username: Quickshell.env("USER") || ""
    property string userAvatarPathAccountsService: FileUtils.trimFileProtocol(`/var/lib/AccountsService/icons/${_username}`)

    // Initialize required directories on startup
    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", shellConfig])
        Quickshell.execDetached(["mkdir", "-p", favicons])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${coverArt}'; mkdir -p '${coverArt}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${cliphistDecode}'; mkdir -p '${cliphistDecode}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${tempImages}'; mkdir -p '${tempImages}'`])
        Quickshell.execDetached(["mkdir", "-p", FileUtils.trimFileProtocol(`${root.state}/anoshell/generated/wallpaper`)])
    }
}

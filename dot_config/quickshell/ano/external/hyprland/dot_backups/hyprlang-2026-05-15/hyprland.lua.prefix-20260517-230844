-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                ANO CONFIG                                ║
-- ║     A standalone Hyprland config with Ano QuickShell UI                  ║
-- ║                                                                          ║
-- ║   Lua rewrite of the previous hyprlang setup (hyprlang deprecated as of  ║
-- ║   Hyprland 0.55). All Ano-specific keybinds and the QuickShell IPC       ║
-- ║   integration preserved 1:1.                                             ║
-- ║                                                                          ║
-- ║   User overrides live in custom/*.lua and are sourced at the very end.   ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝


-- ╶ Locals ────────────────────────────────────────────────────────────────────

-- QuickShell config name, stored at ~/.config/quickshell/<name>/. Every ano
-- IPC call below resolves via `qs -c QS_CONFIG ipc call <target> <method>`.
local QS_CONFIG = "ano"

-- Primary modifier key for window-management binds.
local MAIN_MOD = "SUPER"

-- pypr CLI for scratchpad / minimized / lost-windows dispatchers.
local PYPR = "/usr/bin/pypr-client"

-- Concise IPC-call builder.
local function qs_ipc(target, ...)
    local parts = { "qs", "-c", QS_CONFIG, "ipc", "call", target }
    for _, v in ipairs({ ... }) do table.insert(parts, v) end
    return table.concat(parts, " ")
end

-- For binds that try QuickShell first, fall back to a shell command if the
-- QS process isn't running. TEST_ALIVE exits nonzero when QS isn't up.
local function qs_or(target, method, fallback)
    return ("%s || %s"):format(qs_ipc(target, method), fallback)
end


-- ╶ Monitor ───────────────────────────────────────────────────────────────────
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({
    output    = "",
    mode      = "preferred",
    position  = "auto",
    scale     = "auto",
})


-- ╶ Catchall submap ───────────────────────────────────────────────────────────
-- Required for `quickshell:searchToggleRelease` and friends — the QS shell
-- binds globally-named dispatchers and Hyprland sends events only while the
-- active submap is `global`.

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl dispatch submap global")
end)


-- ╶ Environment variables ─────────────────────────────────────────────────────
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT",       "auto")
hl.env("GDK_BACKEND",                        "wayland,x11,*")
hl.env("QT_QPA_PLATFORM",                    "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION","1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR",        "1")
hl.env("_JAVA_AWT_WM_NONREPARENTING",        "1")
hl.env("SDL_VIDEODRIVER",                    "wayland,x11,windows")
hl.env("CLUTTER_BACKEND",                    "wayland")

-- Flatpak XDG_DATA_DIRS
hl.env(
    "XDG_DATA_DIRS",
    "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
)

-- Theming
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XCURSOR_SIZE",         "16")
hl.env("XCURSOR_THEME",        "Qogir")

-- XDG specs
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Defaults
hl.env("TERMINAL", "kitty")
hl.env("BROWSER",  "zen-browser")
hl.env("EDITOR",   "avim")


-- ╶ Autostart (exec-once equivalents) ─────────────────────────────────────────

hl.on("hyprland.start", function()
    -- XDG portal + Wayland integration
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- QuickShell (Ano UI) — the main shell
    hl.exec_cmd("qs -c " .. QS_CONFIG .. " &")

    -- Core components
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpm reload")

    -- Authentication agent
    hl.exec_cmd("/usr/lib/mate-polkit/polkit-mate-authentication-agent-1")

    -- Clipboard history with QuickShell integration
    hl.exec_cmd(
        "wl-paste --type text  --watch bash -c 'cliphist store && " ..
        qs_ipc("cliphistService", "update") .. "'"
    )
    hl.exec_cmd(
        "wl-paste --type image --watch bash -c 'cliphist store && " ..
        qs_ipc("cliphistService", "update") .. "'"
    )

    -- Cursor theme
    hl.exec_cmd("hyprctl setcursor Qogir 16")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Qogir'")

    -- Wallpaper engine (awww — swww successor)
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("~/.config/awww/scripts/awww_randomize_multi.sh ~/Pictures/hyprwallpapers")

    -- System tray apps
    hl.exec_cmd("nm-applet --indicator")

    -- Notification fallback (QuickShell normally handles them)
    hl.exec_cmd("swaync")

    -- FocusTime daemon (app usage tracker)
    hl.exec_cmd("python3 ~/.config/quickshell/" .. QS_CONFIG .. "/scripts/focustime/focus_daemon.py &")

    -- Extras
    hl.exec_cmd("pypr")
    hl.exec_cmd("kdeconnectd")
    hl.exec_cmd("bauh-tray")
end)


-- ╶ General / layout / decoration / animations / input / misc ─────────────────
-- See https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    general = {
        gaps_in           = 4,
        gaps_out          = 5,
        gaps_workspaces   = 50,
        border_size       = 2,
        resize_on_border  = true,
        hover_icon_on_border = true,
        no_focus_fallback = true,
        allow_tearing     = true,
        layout            = "dwindle",

        snap = {
            enabled      = true,
            window_gap   = 4,
            monitor_gap  = 5,
            respect_gaps = true,
        },
    },

    dwindle = {
        pseudotile      = true,
        preserve_split  = true,
        smart_split     = false,
        smart_resizing  = false,
    },

    master = {
        new_status = "master",
    },

    decoration = {
        rounding_power = 2.4,
        rounding       = 18,

        blur = {
            enabled    = true,
            xray       = true,
            special    = false,
            size       = 10,
            passes     = 3,
            brightness = 1,
            noise      = 0.05,
            contrast   = 0.89,
            vibrancy   = 0.5,
            vibrancy_darkness = 0.5,
            popups     = false,
            ["popups:ignorealpha"] = 0.6,
            input_methods = true,
            ["input_methods:ignorealpha"] = 0.8,
        },

        shadow = {
            enabled       = true,
            ignore_window = true,
            range         = 50,
            offset        = "0 4",
            render_power  = 10,
            color         = "rgba(00000027)",
        },

        dim_inactive = true,
        dim_strength = 0.05,
        dim_special  = 0.07,
    },

    input = {
        kb_layout         = "us",
        numlock_by_default = true,
        repeat_delay      = 250,
        repeat_rate       = 35,
        follow_mouse      = 1,
        off_window_axis_events = 2,
        sensitivity       = 0,

        touchpad = {
            natural_scroll        = true,
            disable_while_typing  = true,
            clickfinger_behavior  = true,
            scroll_factor         = 0.7,
        },
    },

    misc = {
        disable_hyprland_logo       = true,
        disable_splash_rendering    = true,
        disable_autoreload          = false,
        vfr                         = 1,
        mouse_move_enables_dpms     = true,
        key_press_enables_dpms      = true,
        animate_manual_resizes      = false,
        animate_mouse_windowdragging = false,
        enable_swallow              = false,
        swallow_regex               = "(foot|kitty|allacritty|Alacritty|ghostty|Ghostty)",
        on_focus_under_fullscreen   = 2,
        allow_session_lock_restore  = true,
        session_lock_xray           = true,
        initial_workspace_tracking  = false,
        focus_on_activate           = true,
    },

    binds = {
        scroll_event_delay                = 0,
        hide_special_on_workspace_change  = true,
    },

    cursor = {
        zoom_factor      = 1,
        zoom_rigid       = false,
        hotspot_padding  = 1,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    ecosystem = {
        enforce_permissions = false,
    },
})


-- ╶ Bezier curves + animations (expressive MD3-style) ─────────────────────────

hl.curve("expressiveFastSpatial",   { type = "bezier", points = { {0.42, 1.67}, {0.21, 0.90} } })
hl.curve("expressiveSlowSpatial",   { type = "bezier", points = { {0.39, 1.29}, {0.35, 0.98} } })
hl.curve("expressiveDefaultSpatial",{ type = "bezier", points = { {0.38, 1.21}, {0.22, 1.00} } })
hl.curve("emphasizedDecel",         { type = "bezier", points = { {0.05, 0.7},  {0.1,  1}    } })
hl.curve("emphasizedAccel",         { type = "bezier", points = { {0.3,  0},    {0.8,  0.15} } })
hl.curve("standardDecel",           { type = "bezier", points = { {0,    0},    {0,    1}    } })
hl.curve("menu_decel",              { type = "bezier", points = { {0.1,  1},    {0,    1}    } })
hl.curve("menu_accel",              { type = "bezier", points = { {0.52, 0.03}, {0.72, 0.08} } })
hl.curve("stall",                   { type = "bezier", points = { {1,   -0.1},  {0.7,  0.85} } })
hl.curve("specialWorkSwitch",       { type = "bezier", points = { {0.05, 0.7},  {0.1,  1}    } })
hl.curve("standard",                { type = "bezier", points = { {0.2,  0},    {0,    1}    } })

hl.config({
    animations = {
        enabled              = true,
        workspace_wraparound = true,
    },
})

-- Windows
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 3,    bezier = "emphasizedDecel", style = "popin 80%" })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 3,    bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2,    bezier = "emphasizedDecel", style = "popin 90%" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 2,    bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsMove",enabled = true, speed = 3,    bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "border",     enabled = true, speed = 10,   bezier = "emphasizedDecel" })

-- Layers
hl.animation({ leaf = "layersIn",   enabled = true, speed = 2.7,  bezier = "emphasizedDecel", style = "popin 93%" })
hl.animation({ leaf = "layersOut",  enabled = true, speed = 2.4,  bezier = "menu_accel",      style = "popin 94%" })

-- Fade
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 0.5, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.7, bezier = "stall" })

-- Workspaces
hl.animation({ leaf = "workspaces",         enabled = true, speed = 7,   bezier = "menu_decel",      style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2.8, bezier = "emphasizedDecel", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut",enabled = true, speed = 1.2, bezier = "emphasizedAccel", style = "slidevert" })


-- ╶ Gestures (touchpad) ───────────────────────────────────────────────────────

hl.gesture({ fingers = 3, swipe = "move" })
hl.gesture({ fingers = 3, pinch = "float" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up",   action = "dispatcher", dispatcher = "global", arg = "quickshell:overviewWorkspacesToggle" })
hl.gesture({ fingers = 4, direction = "down", action = "dispatcher", dispatcher = "global", arg = "quickshell:overviewWorkspacesClose" })

hl.config({
    gestures = {
        workspace_swipe_distance              = 700,
        workspace_swipe_cancel_ratio          = 0.2,
        workspace_swipe_min_speed_to_force    = 5,
        workspace_swipe_direction_lock        = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new            = true,
    },
})


-- ╶ Plugins ───────────────────────────────────────────────────────────────────

hl.config({
    plugin = {
        ["dynamic-cursors"] = {
            enabled = true,
            mode    = "rotate",
            shake = {
                enabled = true,
                ipc     = true,
            },
            hyprcursor = {
                enabled = true,
            },
        },
        hyprexpo = {
            columns           = 3,
            gap_size          = 5,
            bg_col            = "rgb(111111)",
            workspace_method  = "first 1",
            enable_gesture    = false,
            gesture_distance  = 300,
            gesture_positive  = false,
        },
    },
})


-- ╶ Colors (Appearance theme will override at runtime) ────────────────────────

hl.config({
    general = {
        col = {
            active_border   = "rgb(cdd6f4)",
            inactive_border = "rgba(595959aa)",
        },
    },
})


-- ╶ Window + layer rules ──────────────────────────────────────────────────────
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- File-picker dialogs — center + float
local fileDialogTitles = {
    "^(Open File)(.*)$",
    "^(Select a File)(.*)$",
    "^(Open Folder)(.*)$",
    "^(Save As)(.*)$",
    "^(Choose Files)$",
    "^(File Upload)(.*)$",
    "^(.*)(wants to save)$",
    "^(.*)(wants to open)$",
}
for _, t in ipairs(fileDialogTitles) do
    hl.window_rule({ match = { title = t }, float = true, center = true })
end

-- System utilities (each picks float / size / center to taste)
hl.window_rule({ match = { class = "^(pavucontrol)$" },              float = true, size = "(monitor_w*.45) (monitor_h*.45)", center = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true, size = "(monitor_w*.45) (monitor_h*.45)", center = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" },          float = true, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" },     float = true, size = "(monitor_w*.45) (monitor_h*.45)", center = true })
hl.window_rule({ match = { class = "^(nm-applet)$" },                float = true })
hl.window_rule({ match = { title = "^(btop)$" },                     float = true })
hl.window_rule({ match = { class = "^(nwg-look)$" },                 float = true, size = "50% 60%", center = true, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(qt5ct|qt6ct)$" },              float = true, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(stacer)$" },                   float = true, center = true })

-- kitty running nmtui
hl.window_rule({ match = { class = "kitty", title = "nmtui" }, float = true, size = "60% 70%", center = true })

-- GNOME Settings
hl.window_rule({ match = { class = [[org\.gnome\.Settings]] },  float = true, size = "70% 80%", center = true })

-- yad icon browser sized like pulseaudio
hl.window_rule({ match = { class = [[org\.pulseaudio\.pavucontrol|yad-icon-browser]] }, float = true, size = "60% 70%", center = true })

-- Authentication agents
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(polkit-gnome-authentication-agent-1)$" },       float = true, opacity = "0.80 0.70" })

-- Allow tearing for games that ask for it
hl.window_rule({ match = { class = "^(cs2)$" },          immediate = true })
hl.window_rule({ match = { class = "^(steam_app_.*)$" }, immediate = true })

-- Picture-in-Picture
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true, size = "25% 25%" })
hl.window_rule({ match = { title = "^(Picture in picture)$" }, float = true, pin = true, size = "25% 25%" })

-- Misc — XDG portals
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" },                          float = true })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.gtk)$" },         float = true })

-- QuickShell layer rules — blur + entry animation for every Ano layer surface
hl.layer_rule({ match = { namespace = "ano.*" },     blur = true })
hl.layer_rule({ match = { namespace = "ano.*" },     ignorealpha = 0.1 })
hl.layer_rule({ match = { namespace = "ano.*" },     xray = 0 })
hl.layer_rule({ match = { namespace = "ano.*" },     animation = "popin 93%" })

-- Bar — no entry animation, keep the blur
hl.layer_rule({ match = { namespace = "ano-bar.*" }, no_anim = true })
hl.layer_rule({ match = { namespace = "ano-bar.*" }, blur = true })


-- ╶ Keybinds ──────────────────────────────────────────────────────────────────
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

-- ─── QuickShell UI toggles ───────────────────────────────────────────────────

-- Super tap → toggle search / launcher (QS, rofi fallback). Uses the QS
-- "release" pattern via the global-named dispatcher so a tap releases the
-- shortcut; held Super shows the workspace-number HUD instead.
hl.bind("SUPER, Super_L", "global, quickshell:searchToggleRelease",   { description = "Toggle search" })
hl.bind("SUPER, Super_R", "global, quickshell:searchToggleRelease",   { description = "Toggle search" })
hl.bind("SUPER, Super_L", hl.dsp.exec_cmd(
    qs_or("TEST_ALIVE", "", "pkill rofi || rofi -modi run,window,combi,ssh -show drun -show-icons")
))
hl.bind("SUPER, Super_R", hl.dsp.exec_cmd(
    qs_or("TEST_ALIVE", "", "pkill rofi || rofi -modi run,window,combi,ssh -show drun -show-icons")
))

-- Cancel the search-release if any other key/click happens while Super is held
hl.bind("SUPER, catchall",    "global, quickshell:searchToggleReleaseInterrupt", { non_consuming = true })
hl.bind("CTRL,  Super_L",     "global, quickshell:searchToggleReleaseInterrupt")
hl.bind("CTRL,  Super_R",     "global, quickshell:searchToggleReleaseInterrupt")
hl.bind("SUPER, mouse:272",   "global, quickshell:searchToggleReleaseInterrupt")
hl.bind("SUPER, mouse:273",   "global, quickshell:searchToggleReleaseInterrupt")

-- Workspace-number HUD on Super hold
hl.bind(",      Super_L", "global, quickshell:workspaceNumber", { non_consuming = true })
hl.bind(",      Super_R", "global, quickshell:workspaceNumber", { non_consuming = true })

-- ── Panel toggles ───────────────────────────────────────────────────────────
hl.bind(MAIN_MOD .. ", Tab",         hl.dsp.exec_cmd(qs_ipc("anoview",        "toggle")))
hl.bind(MAIN_MOD .. ", grave",       hl.dsp.exec_cmd(qs_ipc("taskView",       "toggle")))
hl.bind(MAIN_MOD .. ", B",           hl.dsp.exec_cmd(qs_ipc("sidebarLeft",    "toggle")))
hl.bind(MAIN_MOD .. ", N",           hl.dsp.exec_cmd(qs_ipc("sidebarRight",   "toggle")))
hl.bind(MAIN_MOD .. ", A",           hl.dsp.exec_cmd(qs_ipc("search",         "toggle")))
hl.bind(MAIN_MOD .. ", I",           hl.dsp.exec_cmd(qs_ipc("controlPanel",   "toggle")))
hl.bind(MAIN_MOD .. ", comma",       hl.dsp.exec_cmd(qs_ipc("settings",       "toggle")))
hl.bind(MAIN_MOD .. " SHIFT, I",     hl.dsp.exec_cmd(qs_ipc("hud",            "toggle")))
hl.bind(MAIN_MOD .. ", slash",       hl.dsp.exec_cmd(qs_ipc("cheatsheet",     "toggle")))
hl.bind(MAIN_MOD .. ", O",           hl.dsp.exec_cmd(qs_ipc("mediaControls",  "toggle")))
hl.bind(MAIN_MOD .. ", X",           hl.dsp.exec_cmd(qs_ipc("session",        "toggle")))
hl.bind(MAIN_MOD .. " SHIFT, B",     hl.dsp.exec_cmd(qs_ipc("bar",            "toggle")))
hl.bind("CTRL " .. MAIN_MOD .. ", T",hl.dsp.exec_cmd(qs_ipc("wallpaperSelector","toggle")))
hl.bind(MAIN_MOD .. " SHIFT, W",     hl.dsp.exec_cmd(qs_ipc("weatherPanel",   "toggle")))
hl.bind(MAIN_MOD .. " SHIFT, D",     hl.dsp.exec_cmd(qs_ipc("dock",           "toggle")))
hl.bind(MAIN_MOD .. " SHIFT, F",     hl.dsp.exec_cmd(qs_ipc("focusTime",      "toggle")))
hl.bind("CTRL " .. MAIN_MOD .. ", D",hl.dsp.exec_cmd(qs_ipc("displayManager", "toggle")))
hl.bind("CTRL " .. MAIN_MOD .. ", B",hl.dsp.exec_cmd(qs_ipc("antiFlashbang",  "toggle")))
hl.bind("CTRL " .. MAIN_MOD .. ", P",hl.dsp.exec_cmd(qs_ipc("panelFamily",    "cycle")))
hl.bind("CTRL " .. MAIN_MOD .. ", R",hl.dsp.exec_cmd("killall qs quickshell; sleep 0.3; qs -c " .. QS_CONFIG .. " &"))

-- Clipboard (QS first, rofi fallback)
hl.bind("ALT, V", hl.dsp.exec_cmd(qs_or(
    "clipboard", "toggle",
    "cliphist list | rofi -dmenu | cliphist decode | wl-copy"
)))

-- Emoji picker
hl.bind(MAIN_MOD .. ", period", hl.dsp.exec_cmd("wofi-emoji"))


-- ─── Brightness & volume (OSD via QS, brightnessctl/wpctl fallback) ─────────
-- bindle (locked + repeating) for keys that should fire while the screen
-- is locked AND repeat while held.

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(qs_or("brightness", "increment",  "brightnessctl s 5%+")),                      { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(qs_or("brightness", "decrement",  "brightnessctl s 5%-")),                      { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(qs_or("audio", "increment",       "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5")), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(qs_or("audio", "decrement",       "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-")),         { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(qs_or("audio", "toggleMute",      "wpctl set-mute @DEFAULT_SINK@ toggle")),              { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(qs_or("audio", "toggleMicMute",   "wpctl set-mute @DEFAULT_SOURCE@ toggle")),            { locked = true })

-- Keyboard backlight
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd([[brightnessctl -d "*::kbd_backlight" s 10%+]]),                                { locked = true, repeating = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd([[brightnessctl -d "*::kbd_backlight" s 10%-]]),                                { locked = true, repeating = true })
hl.bind("ALT, XF86MonBrightnessUp",   hl.dsp.exec_cmd([[brightnessctl -d "*::kbd_backlight" s 10%+]]),                           { locked = true, repeating = true })
hl.bind("ALT, XF86MonBrightnessDown", hl.dsp.exec_cmd([[brightnessctl -d "*::kbd_backlight" s 10%-]]),                           { locked = true, repeating = true })

-- Mute toggles
hl.bind(MAIN_MOD .. " SHIFT, M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"))
hl.bind(MAIN_MOD .. " ALT, M",   hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"))


-- ─── Screenshots & screen capture ───────────────────────────────────────────

hl.bind(MAIN_MOD .. " SHIFT, S", "global, quickshell:regionScreenshot")
hl.bind(MAIN_MOD .. " SHIFT, S", hl.dsp.exec_cmd(qs_or(
    "TEST_ALIVE", "", "hyprshot --freeze --clipboard-only --mode region --silent"
)))
hl.bind(MAIN_MOD .. " SHIFT, X", "global, quickshell:regionOcr")
hl.bind(MAIN_MOD .. " SHIFT, G", "global, quickshell:regionSearch")

-- Screen recording — locked = work while screen is locked
hl.bind(MAIN_MOD .. " SHIFT, R", "global, quickshell:regionRecord",                                                         { locked = true })
hl.bind(MAIN_MOD .. " SHIFT, R", hl.dsp.exec_cmd(qs_or("TEST_ALIVE", "", "~/.config/quickshell/" .. QS_CONFIG .. "/scripts/videos/record.sh")), { locked = true })
hl.bind(MAIN_MOD .. " SHIFT ALT, R", hl.dsp.exec_cmd("~/.config/quickshell/" .. QS_CONFIG .. "/scripts/videos/record.sh --fullscreen --sound"), { locked = true })

-- Fallback screenshots (swappy + grim)
hl.bind("SHIFT, Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))
hl.bind(",      Print", hl.dsp.exec_cmd("grim - | wl-copy"),                                                         { locked = true })
hl.bind("CTRL,  Print", hl.dsp.exec_cmd(
    [[mkdir -p $(xdg-user-dir PICTURES)/Screenshots && grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_"$(date '+%Y-%m-%d_%H.%M.%S')".png]]
),                                                                                                                  { locked = true, non_consuming = true })

-- Color picker
hl.bind(MAIN_MOD .. " SHIFT, C", hl.dsp.exec_cmd([[hyprpicker -a && notify-send "Color picked" "$(wl-paste)"]]))


-- ─── Zoom ────────────────────────────────────────────────────────────────────
-- binde (repeating) so the zoom keeps changing while the key is held

hl.bind(MAIN_MOD .. ", minus", hl.dsp.exec_cmd(qs_or(
    "zoom", "zoomOut",
    "~/.config/quickshell/" .. QS_CONFIG .. "/scripts/hyprland/zoom.sh decrease 0.1"
)), { repeating = true })
hl.bind(MAIN_MOD .. ", equal", hl.dsp.exec_cmd(qs_or(
    "zoom", "zoomIn",
    "~/.config/quickshell/" .. QS_CONFIG .. "/scripts/hyprland/zoom.sh increase 0.1"
)), { repeating = true })


-- ─── App launchers / quick exec ──────────────────────────────────────────────

hl.bind(MAIN_MOD .. ", RETURN",         hl.dsp.exec_cmd("kitty"))
hl.bind("CTRL ALT, T",                  hl.dsp.exec_cmd("ghostty"))
hl.bind(MAIN_MOD .. " SHIFT, Q",        hl.dsp.window.close())
hl.bind("CTRL ALT, K",                  hl.dsp.exec_cmd("hyprlock"))
hl.bind(MAIN_MOD .. " CTRL, Q",         hl.dsp.exit())
hl.bind(MAIN_MOD .. ", E",              hl.dsp.exec_cmd("nemo ~/Downloads"))
hl.bind("CTRL ALT, B",                  hl.dsp.exec_cmd("neovide --neovim-bin avim"))
hl.bind("CTRL ALT, G",                  hl.dsp.exec_cmd("brave"))
hl.bind(MAIN_MOD .. ", W",              hl.dsp.exec_cmd("exo-open --launch webbrowser"))
hl.bind(MAIN_MOD .. ", Z",              hl.dsp.exec_cmd("zen-browser"))
hl.bind(MAIN_MOD .. ", P",              hl.dsp.exec_cmd("celluloid"))
hl.bind(MAIN_MOD .. ", SPACE",          hl.dsp.window.float({ action = "toggle" }))
hl.bind(MAIN_MOD .. ", D",              hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(MAIN_MOD .. ", R",              hl.dsp.exec_cmd("$HOME/.config/rofi/scripts/launcher.sh"))
hl.bind(MAIN_MOD .. ", F",              hl.dsp.window.fullscreen())
hl.bind(MAIN_MOD .. ", S",              hl.dsp.layout("togglesplit"))

hl.bind("CTRL SHIFT, ESCAPE",           hl.dsp.exec_cmd("kitty -e btop"))
hl.bind("CTRL ALT, U",                  hl.dsp.exec_cmd("pavucontrol"))
hl.bind(MAIN_MOD .. " SHIFT, O",        hl.dsp.exec_cmd("kitty -e avim ~/.config/hypr/Ano/hyprland.lua"))

-- Game mode
hl.bind(MAIN_MOD .. ", F1",             hl.dsp.exec_cmd("~/.config/hypr/Ano/scripts/gamemode"))


-- ─── pypr (scratchpads, minimize, lost windows) ─────────────────────────────

hl.bind(MAIN_MOD .. " SHIFT, T",        hl.dsp.exec_cmd(PYPR .. " toggle term"))

-- Minimize emulation: special workspace "minimized"
hl.bind(MAIN_MOD .. ", M",              hl.dsp.workspace.toggle_special("minimized"))
hl.bind(MAIN_MOD .. " SHIFT, minus",    hl.dsp.exec_cmd(PYPR .. " toggle_special minimized"))

-- Fetch lost off-screen windows
hl.bind("CTRL " .. MAIN_MOD .. ", L",   hl.dsp.exec_cmd(PYPR .. " lost_windows"))


-- ─── Window management ─────────────────────────────────────────────────────

hl.bind(MAIN_MOD .. ", G",                hl.dsp.layout("togglegroup"))
hl.bind("ALT, Tab",                       hl.dsp.focus({ workspace = "e+1" }))
hl.bind("ALT SHIFT, Tab",                 hl.dsp.focus({ workspace = "e-1" }))
hl.bind("ALT, Tab",                       hl.dsp.exec_raw("bringactivetotop"))
hl.bind("ALT SHIFT, Tab",                 hl.dsp.exec_raw("bringactivetotop"))
hl.bind("ALT, F4",                       hl.dsp.window.close())
hl.bind(MAIN_MOD .. ", Q",                hl.dsp.window.close())
hl.bind(MAIN_MOD .. " SHIFT ALT, Q",      hl.dsp.exec_cmd("hyprctl kill"))

-- Special workspace
hl.bind(MAIN_MOD .. " ALT, A",            hl.dsp.workspace.toggle_special())
hl.bind(MAIN_MOD .. " SHIFT, A",          hl.dsp.window.move({ workspace = "special" }))
hl.bind(MAIN_MOD .. " ALT, S",            hl.dsp.exec_raw("movetoworkspacesilent special"))
hl.bind(MAIN_MOD .. ", C",                hl.dsp.exec_raw("centerwindow"))

-- Positioning
hl.bind(MAIN_MOD .. " ALT, SPACE",        hl.dsp.window.float({ action = "toggle" }))
hl.bind(MAIN_MOD .. " ALT, F",            hl.dsp.exec_raw("fullscreenstate 0 3"))
hl.bind(MAIN_MOD .. ", V",                hl.dsp.window.pseudo())

-- Split ratio (repeating)
hl.bind(MAIN_MOD .. ", semicolon",        hl.dsp.exec_raw("splitratio -0.1"), { repeating = true })
hl.bind(MAIN_MOD .. ", apostrophe",       hl.dsp.exec_raw("splitratio +0.1"), { repeating = true })

-- Focus
hl.bind(MAIN_MOD .. ", left",             hl.dsp.focus({ direction = "left"  }))
hl.bind(MAIN_MOD .. ", right",            hl.dsp.focus({ direction = "right" }))
hl.bind(MAIN_MOD .. ", up",               hl.dsp.focus({ direction = "up"    }))
hl.bind(MAIN_MOD .. ", down",             hl.dsp.focus({ direction = "down"  }))
hl.bind(MAIN_MOD .. ", bracketleft",      hl.dsp.focus({ direction = "left"  }))
hl.bind(MAIN_MOD .. ", bracketright",     hl.dsp.focus({ direction = "right" }))

-- Move
hl.bind(MAIN_MOD .. " SHIFT, left",       hl.dsp.window.move({ direction = "left"  }))
hl.bind(MAIN_MOD .. " SHIFT, right",      hl.dsp.window.move({ direction = "right" }))
hl.bind(MAIN_MOD .. " SHIFT, up",         hl.dsp.window.move({ direction = "up"    }))
hl.bind(MAIN_MOD .. " SHIFT, down",       hl.dsp.window.move({ direction = "down"  }))

-- Resize (repeating)
hl.bind(MAIN_MOD .. " CTRL, left",        hl.dsp.exec_raw("resizeactive -20 0"),  { repeating = true })
hl.bind(MAIN_MOD .. " CTRL, right",       hl.dsp.exec_raw("resizeactive 20 0"),   { repeating = true })
hl.bind(MAIN_MOD .. " CTRL, up",          hl.dsp.exec_raw("resizeactive 0 -20"),  { repeating = true })
hl.bind(MAIN_MOD .. " CTRL, down",        hl.dsp.exec_raw("resizeactive 0 20"),   { repeating = true })


-- ─── Workspaces 1-10 ────────────────────────────────────────────────────────
-- Super+N switches; Super+Shift+N moves+follows; Super+Alt+N moves silently.

for i = 1, 10 do
    local key = i % 10  -- key 0 maps to workspace 10
    hl.bind(MAIN_MOD .. ", "         .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(MAIN_MOD .. " SHIFT, "   .. key, hl.dsp.window.move({ workspace = i }))
    hl.bind(MAIN_MOD .. " ALT, "     .. key, hl.dsp.exec_raw("movetoworkspacesilent " .. i))
end

-- Scroll-wheel workspaces
hl.bind(MAIN_MOD .. ", mouse_down",       hl.dsp.focus({ workspace = "e+1" }))
hl.bind(MAIN_MOD .. ", mouse_up",         hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL " .. MAIN_MOD .. ", Right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("CTRL " .. MAIN_MOD .. ", Left",  hl.dsp.focus({ workspace = "r-1" }))
hl.bind(MAIN_MOD .. ", Page_Down",        hl.dsp.focus({ workspace = "+1" }))
hl.bind(MAIN_MOD .. ", Page_Up",          hl.dsp.focus({ workspace = "-1" }))

-- Move window with scroll
hl.bind(MAIN_MOD .. " SHIFT, mouse_down", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(MAIN_MOD .. " SHIFT, mouse_up",   hl.dsp.window.move({ workspace = "r+1" }))


-- ─── Mouse binds ───────────────────────────────────────────────────────────

hl.bind(MAIN_MOD .. ", mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(MAIN_MOD .. ", mouse:274", hl.dsp.window.drag(),   { mouse = true })
hl.bind(MAIN_MOD .. ", mouse:273", hl.dsp.window.resize(), { mouse = true })


-- ─── Media controls ─────────────────────────────────────────────────────────

hl.bind(", XF86AudioPlay",           hl.dsp.exec_cmd(qs_or("mpris", "playPause", "playerctl play-pause")), { locked = true })
hl.bind(", XF86AudioPause",          hl.dsp.exec_cmd(qs_or("mpris", "playPause", "playerctl play-pause")), { locked = true })
hl.bind(", XF86AudioNext",           hl.dsp.exec_cmd(qs_or("mpris", "next",      "playerctl next")),       { locked = true })
hl.bind(", XF86AudioPrev",           hl.dsp.exec_cmd(qs_or("mpris", "previous",  "playerctl previous")),   { locked = true })
hl.bind(MAIN_MOD .. " SHIFT, N",     hl.dsp.exec_cmd(qs_or("mpris", "next",      "playerctl next")),       { locked = true })
hl.bind(MAIN_MOD .. " SHIFT, P",     hl.dsp.exec_cmd(qs_or("mpris", "playPause", "playerctl play-pause")), { locked = true })


-- ─── Session ────────────────────────────────────────────────────────────────

hl.bind(MAIN_MOD .. ", L",                                            hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(MAIN_MOD .. " SHIFT, L",                                      hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"))
hl.bind("CTRL SHIFT ALT " .. MAIN_MOD .. ", Delete",                  hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"))


-- ─── Hardware toggles ──────────────────────────────────────────────────────

hl.bind(", XF86TouchpadToggle", hl.dsp.exec_cmd("~/.config/hypr/Ano/scripts/touchpad-toggle.sh"), { locked = true })
hl.bind(", XF86Close",          hl.dsp.window.close(),                                            { locked = true })


-- ─── Virtual-machine mode (a submap that disables everything except its
-- own escape hatch) ────────────────────────────────────────────────────────

hl.bind(MAIN_MOD .. " ALT, F1", hl.dsp.exec_cmd(
    "notify-send 'Virtual Machine Mode' 'Keybinds disabled. Hit Super+Alt+F1 to escape' -a 'Hyprland' && " ..
    "hyprctl dispatch submap virtual-machine"
))
-- (Inside the virtual-machine submap, only the escape hatch fires. The
-- submap definition lives in hyprctl runtime state via the dispatch call
-- above; the only bind we register here is the one that swaps back.)
hl.submap("virtual-machine")
hl.bind(MAIN_MOD .. " ALT, F1", hl.dsp.exec_cmd(
    "notify-send 'Normal Mode' 'Keybinds re-enabled' -a 'Hyprland' && hyprctl dispatch submap global"
))
hl.submap("global")


-- ╶ User overrides ────────────────────────────────────────────────────────────
-- Loaded last so they win on any conflict with the defaults above. Each file
-- is a no-op stub on first install — fill in to taste.

require("Ano.custom.env")
require("Ano.custom.execs")
require("Ano.custom.general")
require("Ano.custom.rules")
require("Ano.custom.keybinds")
require("Ano.custom.colors")


-- ╶ Per-machine overrides (create as needed and uncomment) ────────────────────

-- require("Ano.monitors")
-- require("Ano.workspaces")

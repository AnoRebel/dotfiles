-- ============================================================================
-- Hyprland Lua configuration (translated 1:1 from the previous hyprlang setup)
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/
--
-- Source layout this file replaces:
--   hyprland.conf      -> main sections (this file's body)
--   env_var.conf       -> ENVIRONMENT VARIABLES section
--   keybindings.conf   -> KEYBINDINGS section
--   media-binds.conf   -> MEDIA & SPECIAL KEYS section
--   windowrules.conf   -> WINDOW / LAYER / WORKSPACE RULES section
--
-- The previous *.conf files are kept untouched on disk. A timestamped copy of
-- the original set lives under: ~/.config/hypr/.backups/hyprlang-to-lua-2026-05-14/
-- ============================================================================

-- ----------------------------------------------------------------------------
-- LOCALS (Lua-only enhancement: variables for things referenced repeatedly)
-- ----------------------------------------------------------------------------

-- Modifier alias, mirrors the old `$mainMod = SUPER`.
local mainMod = "SUPER"

-- pypr CLI, mirrors the old `$pypr = /usr/bin/pypr-client`.
local pypr = "/usr/bin/pypr-client"

-- Waybar helper-script directory, mirrors the old `$SCRIPT = ~/.config/waybar/scripts`.
local WAYBAR_SCRIPTS = "~/.config/waybar/scripts"

-- Catppuccin Mocha "text" colour reused for active borders / overview accents.
local ACCENT = "rgb(cdd6f4)"
local INACTIVE = "rgba(595959aa)"
local BLACK_BG = "rgb(111111)"
local SHADOW_BLACK = "rgba(1a1a1aee)"

-- Dropterm class regex, mirrors the old `$dropterm = ^(kitty-dropterm)$`.
local DROPTERM = "^(kitty-dropterm)$"

-- Layer namespace regex reused for blur/xray, mirrors the old `$layers = ...`.
local LAYER_NAMESPACES = "^(eww-.+|bar|system-menu|anyrun|gtk-layer-shell|lockscreen|waybar)$"

------------------
---- MONITORS ----
------------------

-- Setup monitors
-- See https://wiki.hyprland.org/Configuring/Monitors/
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

-- Dual monitor example on G15 Strix
-- eDP-1 is the built in monitor while DP-1 is external
-- Both monitors here are at 1440 and 165Hz
-- DP-1 is on the left and  eDP-1 is on the right
-- hl.monitor({ output = "eDP-1",    mode = "1366x768@60",  position = "0x0",    scale = 1    })
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1366x0", scale = 1.25 })

-- See https://wiki.hyprland.org/Configuring/Keywords/ for more

-------------------
---- AUTOSTART ----
-------------------

-- Execute your favorite apps at launch.
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/hypr/scripts/xdg-portal-hyprland") -- Make sure the correct portal is running
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Wayland magic (screen sharing etc.)
	hl.exec_cmd("dbus-update-activation-environment --systemd --all") -- for XDPH
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- More wayland magic (screen sharing etc.)
	-- hl.exec_cmd("/usr/lib/mate-polkit/polkit-mate-authentication-agent-1") -- used for user sudo graphical elevation
	-- hl.exec_cmd("/usr/bin/lxqt-policykit-agent")
	hl.exec_cmd("systemctl --user start hyprpolkitagent") -- "/usr/lib/hyprpolkitagent/hyprpolkitagent" | used for user sudo graphical elevation
	hl.exec_cmd("hyprctl setcursor Qogir 16")
	hl.exec_cmd('gsettings set org.gnome.desktop.interface cursor-theme "Qogir"')
	hl.exec_cmd("/usr/lib/iio-sensor-proxy &")
	hl.exec_cmd("iio-hyprland")
	-- hl.exec_cmd("hypridle")
	hl.exec_cmd("waybar") -- The top bar
	hl.exec_cmd("~/.config/hypr/scripts/hyprsunset.sh")
	-- hl.exec_cmd("blueman-applet")                                                        -- Systray app for BT
	hl.exec_cmd("nm-applet --indicator") -- Systray app for Network/Wifi
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("swaync")
	hl.exec_cmd("swayosd-server")
	hl.exec_cmd("/usr/bin/pypr")
	-- hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("hyprpm reload -n")
	hl.exec_cmd("shelly-notifications")
	hl.exec_cmd("vicinae server")
	-- hl.exec_cmd([[wlsunset -l $(curl -s "https://location.services.mozilla.com/v1/geolocate?key=geoclue" | jq -r '"\(.location.lat) -L \(.location.lng)"')]])
	hl.exec_cmd("~/.config/awww/scripts/awww_randomize_multi.sh ~/Pictures/hyprwallpapers")
	-- hl.exec_cmd("kanshi")
	hl.exec_cmd("kdeconnectd")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Environment Variables
-- see https://wiki.hyprland.org/Configuring/Environment-variables/

-- █▀▀ █▄░█ █░█
-- ██▄ █░▀█ ▀▄▀

-- Some default env vars.
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- hl.env("QT_STYLE_OVERRIDE",              "kvantum")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
-- hl.env("ELECTRON_OZONE_PLATFORM_HINT",   "wayland")

-- Theming Related Variables
-- Set cursor size. See FAQ below for why you might want this variable set.
-- https://wiki.hyprland.org/FAQ/
hl.env("XCURSOR_SIZE", "16")

-- Set a GTK theme manually, for those who want to avoid appearance tools such as lxappearance or nwg-look
-- hl.env("GTK_THEME", "")

-- Set your cursor theme. The theme needs to be installed and readable by your user.
hl.env("XCURSOR_THEME", "Qogir")

-- the line below may help with multiple monitors
-- hl.env("WLR_EGL_NO_MODIFIERS", "1")

-- XDG Specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Toolkit Backend Variables
-- GTK: Use wayland if available, fall back to x11 if not.
-- hl.env("GDK_BACKEND", "wayland,x11")
-- QT: Use wayland if available, fall back to x11 if not.
-- hl.env("QT_QPA_PLATFORM", "wayland,xcb")
-- Run SDL2 applications on Wayland. Remove or set to x11 if games that
-- provide older versions of SDL cause compatibility issues
-- hl.env("SDL_VIDEODRIVER", "wayland")
-- Clutter package already has wayland enabled, this variable
-- will force Clutter applications to try and use the Wayland backend
-- hl.env("CLUTTER_BACKEND", "wayland")

-- QT Variables
-- (From the QT documentation) enables automatic scaling, based on the monitor's pixel density
-- https://doc.qt.io/qt-5/highdpi.html
-- hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
-- Tell QT applications to use the Wayland backend, and fall back to x11 if Wayland is unavailable
-- hl.env("QT_QPA_PLATFORM", "wayland,xcb")
-- Disables window decorations on QT applications
-- hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- Tells QT based applications to pick your theme from qt5ct, use with Kvantum.
-- hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- use this instead of hidpi patches
hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})

-- For all categories, see https://wiki.hyprland.org/Configuring/Variables/
hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		numlock_by_default = 1,
		follow_mouse = 1,

		touchpad = {
			natural_scroll = true, -- old "yes"
		},

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
	},

	general = {
		-- See https://wiki.hyprland.org/Configuring/Variables/ for more
		gaps_in = 3,
		gaps_out = 5,
		border_size = 2,

		col = {
			-- active_border = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
			active_border = ACCENT,
			inactive_border = INACTIVE,
		},

		layout = "dwindle",
		resize_on_border = true,
		hover_icon_on_border = true,
	},

	misc = {
		-- vrr = 1,
		-- disable auto polling for config file changes
		disable_autoreload = false,
		disable_splash_rendering = false,
		disable_hyprland_logo = true,
	},

	decoration = {
		-- See https://wiki.hyprland.org/Configuring/Variables/ for more
		rounding = 3,

		blur = {
			enabled = true,
			size = 7,
			passes = 3,
			xray = true,
			brightness = 1.0,
			noise = 0.02,
		},

		-- drop_shadow = true (legacy key, replaced by shadow.enabled)
		shadow = {
			enabled = true,
			offset = { 0, 2 },
			range = 4,
			render_power = 3,
			-- color = SHADOW_BLACK,
		},
	},

	animations = {
		enabled = true,
		workspace_wraparound = true,
	},
})

-- Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
-- Bezier definitions (old `bezier = name, p1, p2, p3, p4`)
hl.curve("myBezier", { type = "bezier", points = { { 0.10, 0.9 }, { 0.1, 1.05 } } })
hl.curve("best", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } }) -- old config had "064, 1" which is a typo for 0.64
hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })
-- Animation curves
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })

-- Animation configs
hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "emphasizedAccel", style = "slide" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 5, bezier = "standard" })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "standard" })

hl.animation({
	leaf = "specialWorkspace",
	enabled = true,
	speed = 4,
	bezier = "specialWorkSwitch",
	style = "slidefadevert 15%",
})

hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "standard" })

-- hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier", style = "slide" })
-- hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "best" })
-- hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
-- hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
-- hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })
-- hl.animation({ leaf = "windows",     enabled = true, speed = 6,  bezier = "wind",   style = "slide" })
-- hl.animation({ leaf = "windowsIn",   enabled = true, speed = 6,  bezier = "winIn",  style = "slide" })
-- hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5,  bezier = "winOut", style = "slide" })
-- hl.animation({ leaf = "windowsMove", enabled = true, speed = 5,  bezier = "wind",   style = "slide" })
-- hl.animation({ leaf = "border",      enabled = true, speed = 1,  bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "loop" })
-- hl.animation({ leaf = "fade",        enabled = true, speed = 10, bezier = "default" })
-- hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,  bezier = "wind" })

hl.config({
	dwindle = {
		-- See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
		preserve_split = true, -- you probably want this
	},

	master = {
		-- See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
		new_on_top = false,
	},

	-- scrolling layout config
	scrolling = {
		fullscreen_on_one_column = true,
		column_width = 0.6,
		-- direction              = "right",
		follow_focus = true,
	},

	ecosystem = {
		enforce_permissions = false,
	},
})

-----------------
---- PLUGINS ----
-----------------

-- Per the wiki, plugin config values go through hl.config({ plugin = {...} }).
-- Each block is guarded with `if hl.plugin.<name> ~= nil` so Hyprland does not
-- error when the plugin has not been loaded yet (hyprpm reload runs at startup).

if hl.plugin.dynamic_cursors then
	hl.config({
		plugin = {
			dynamic_cursors = {
				enabled = true,
				mode = "rotate", --"tilt"

				shake = {
					enabled = true,
					ipc = true,
				},
				hyprcursor = {
					enabled = true,
				},
			},
		},
	})
end

if hl.plugin and hl.plugin.hyprexpo then
	hl.config({
		plugin = {
			hyprexpo = {
				columns = 2,
				gap_size = 5,
				bg_col = BLACK_BG,
				workspace_method = "center current", -- [center/first] [workspace] e.g. first 1 or center m+1

				enable_gesture = true, -- laptop touchpad, 4 fingers
				-- gesture_distance = 300, -- how far is the "max"
				-- gesture_positive = true, -- positive = swipe down. Negative = swipe up.
			},
		},
	})
end

if hl.plugin and hl.plugin.overview then
	hl.config({
		plugin = {
			overview = {
				gapsIn = 3,
				gapsOut = 5,
				onBottom = false,
				-- panelHeight       = 120,
				panelBorderWidth = 0,
				workspaceMargin = 20,
				workspaceBorderSize = 0,
				centerAligned = true,
				disableGestures = false,
				showEmptyWorkspace = true,
				hideBackgroundLayers = false,
				-- hideTopLayers     = true,
				-- hideOverlayLayers = true,
				hideRealLayers = true,
				panelBorderColor = ACCENT,
				workspaceActiveBorder = ACCENT,
				workspaceInactiveBorder = INACTIVE,
			},
		},
	})
end

if hl.plugin and hl.plugin.scrolloverview then
	hl.plugin.scrolloverview.configure({
		gesture_distance = 300, -- how far is the "max" for the gesture
		scale = 0.6, -- preferred overview scale
		workspace_gap = 80,
		wallpaper = 0, -- 0: global only, 1: per-workspace only, 2: both
		blur = false, -- blur only the main overview wallpaper

		shadow = {
			enabled = true,
			range = 50,
			render_power = 3,
			-- color        = SHADOW_BLACK,
		},
	})
end

if hl.plugin and hl.plugin.hyprgrass then
	hl.config({
		plugin = {
			hyprgrass = {
				-- The default sensitivity is probably too low on tablet screens,
				-- I recommend turning it up to 4.0
				sensitivity = 3.0,

				-- in milliseconds
				long_press_delay = 400,

				-- resize windows by long-pressing on window borders and gaps.
				-- If general:resize_on_border is enabled, general:extend_border_grab_area is
				-- used for floating windows
				resize_on_border_long_press = true,

				-- in pixels, the distance from the edge that is considered an edge
				edge_margin = 10,
			},
		},
		gestures = {
			workspace_swipe_touch = true,
			workspace_swipe_cancel_ratio = 0.15,
		},
	})
  hl.plugin.hyprgrass.bind {
    pattern = {kind = "pinch", fingers = 3, direction = "pinchin"}
    action = hl.dsp.window.float({ action = "set" })),
  }
  hl.plugin.hyprgrass.bind {
    pattern = {kind = "pinch", fingers = 3, direction = "pinchout"}
    action = hl.dsp.window.fullscreen({ mode = "fullscreen", action = "set" })), -- mode: maximized | fullscreen and action: set | unset | toggle
  }
  hl.plugin.hyprgrass.gesture {
    pattern = {kind = "swipe", fingers = 3, direction = "down"},
    action = hl.plugin.scrolloverview.overview("on"),
  }
end

-------------------
---- GESTURES  ----
-------------------

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- The old `gesture = 4, right, dispatcher, layoutmsg, focus l` had no direct
-- equivalent: the Lua API has no "dispatcher" action, so we run the layout
-- message dispatcher from a lambda instead.
hl.gesture({
	fingers = 4,
	direction = "right",
	action = function()
		hl.dispatch(hl.dsp.layout("focus l"))
	end,
})
hl.gesture({
	fingers = 4,
	direction = "left",
	action = function()
		hl.dispatch(hl.dsp.layout("focus r"))
	end,
})
-- hl.gesture({ fingers = 3, direction = "down",     action = function() hl.dispatch(hl.dsp.global("overview:open")) end })
-- hl.gesture({ fingers = 3, direction = "up",       action = function() hl.dispatch(hl.dsp.global("overview:close")) end })
-- hl.gesture({ fingers = 4, direction = "vertical", action = function() hl.dispatch(hl.dsp.global("overview:toggle")) end })

-----------------
---- DEVICES ----
-----------------

-- Example per-device config
-- See https://wiki.hyprland.org/Configuring/Keywords/#executing for more
hl.device({
	name = "epic mouse V1",
	sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------

-- See https://wiki.hyprland.org/Configuring/Keywords/ for more
-- mainMod = SUPER (declared at top of file)
-- pypr    = /usr/bin/pypr-client (declared at top of file)

-- Key strings join modifiers with "+"; a no-modifier bind is just the bare key.

-- Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
hl.bind(mainMod .. "+RETURN", hl.dsp.exec_cmd("kitty")) -- open the terminal
hl.bind("CTRL+ALT+T", hl.dsp.exec_cmd("ghostty")) -- open the terminal
hl.bind(mainMod .. "+SHIFT+Q", hl.dsp.window.close()) -- close the active window
hl.bind("CTRL+ALT+K", hl.dsp.exec_cmd("hyprlock")) -- Lock the screen
hl.bind(mainMod .. "+X", hl.dsp.exec_cmd("wlogout --protocol layer-shell")) -- show the logout window
hl.bind(mainMod .. "+CTRL+Q", hl.dsp.exec_cmd("hyprshutdown")) -- Exit Hyprland (hyprshutdown for ordered shutdown; the bare `exit` dispatcher is discouraged by the wiki)
hl.bind(mainMod .. "+E", hl.dsp.exec_cmd("nemo ~/Downloads")) -- Show the graphical file browser
-- hl.bind("CTRL+ALT+B",       hl.dsp.exec_cmd("caja"))                                                                  -- Show the graphical file browser
hl.bind("CTRL+ALT+B", hl.dsp.exec_cmd("neovide --neovim-bin avim")) -- Show the graphical Terminal Editor
hl.bind("CTRL+ALT+W", hl.dsp.exec_cmd("libreoffice")) -- Show the graphical file browser
hl.bind("CTRL+ALT+V", hl.dsp.exec_cmd("code"))
-- hl.bind("CTRL+ALT+V",       hl.dsp.exec_cmd("subl"))
-- hl.bind(mainMod .. "+W",    hl.dsp.exec_cmd("exo-open --launch webbrowser"))
hl.bind("CTRL+ALT+G", hl.dsp.exec_cmd("brave"))
hl.bind(mainMod .. "+Z", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. "+F5", hl.dsp.exec_cmd("gimp"))
hl.bind(
	mainMod .. "+SHIFT+c",
	hl.dsp.exec_cmd([[hyprpicker | wl-copy -n && notify-send.py "Hyprpicker" "$(wl-paste)"]])
)
-- hl.bind(mainMod .. "+SHIFT+c", hl.dsp.exec_cmd([[hyprpicker -a && notify-send.py "Hyprpicker" "$(wl-paste)"]]))
hl.bind(mainMod .. "+SPACE", hl.dsp.window.float({ action = "toggle" })) -- Allow a window to float
hl.bind(mainMod .. "+R", hl.dsp.exec_cmd("$HOME/.config/rofi/scripts/launcher.sh")) -- Show the graphical app launcher
hl.bind(mainMod .. "+D", hl.dsp.exec_cmd("vicinae toggle")) -- Show the graphical app launcher
-- hl.bind(mainMod .. "+D",    hl.dsp.exec_cmd("rofi -modi run,window,combi,ssh -show drun -show-icons"))
-- hl.bind(mainMod .. "+D",    hl.dsp.exec_cmd("dmenu-wl_run -i -h 26 -nb '#191919' -nf '#fea63c' -sb '#00695C' -sf '#ECECEC' -fn 'DroidSansMono Nerd Font:bold:pixelsize=12' -p 'Run: '"))
hl.bind(mainMod .. "+period", hl.dsp.exec_cmd("wofi-emoji"))
hl.bind(mainMod .. "+V", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. "+F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind("SHIFT+Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]])) -- take a screenshot of selected area
hl.bind("Print", hl.dsp.exec_cmd("grim - | swappy -f -")) -- take a screenshot

hl.bind(mainMod .. "+CTRL+B", hl.dsp.exec_cmd("killall -SIGUSR2 waybar")) -- Reload Waybar
hl.bind(mainMod .. "+CTRL+R", hl.dsp.exec_cmd("touch ~/.config/hypr/hyprland.lua")) -- Reload Hyprland
-- CTRL+ALT+G already bound to brave above; second copy removed (paste duplicate).
-- hl.bind("SUPER+B",          hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind("CTRL+SHIFT+Escape", hl.dsp.exec_cmd("kitty -e btop"))
hl.bind("CTRL+ALT+U", hl.dsp.exec_cmd("pavucontrol"))
hl.bind(mainMod .. "+SHIFT+O", hl.dsp.exec_cmd("kitty -e avim ~/.config/hypr/hyprland.lua"))

hl.bind(mainMod .. "+F1", hl.dsp.exec_cmd("~/.config/hypr/scripts/gamemode"))

-- ▀█▀ ▄▀█ █▄▄ █▄▄ █▀▀ █▀▄
-- ░█░ █▀█ █▄█ █▄█ ██▄ █▄▀
hl.bind(mainMod .. "+g", hl.dsp.group.toggle())
hl.bind("ALT+TAB", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("ALT+SHIFT+TAB", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("ALT+TAB", hl.dsp.window.alter_zorder({ mode = "top" })) -- old `bringactivetotop`
hl.bind("ALT+SHIFT+TAB", hl.dsp.window.alter_zorder({ mode = "top" })) -- old `bringactivetotop`
hl.bind(mainMod .. "+TAB", hl.dsp.focus({ last = true })) -- old `focuscurrentorlast`

-- █▀ █▀█ █▀▀ █▀▀ █ ▄▀█ █░░
-- ▄█ █▀▀ ██▄ █▄▄ █ █▀█ █▄▄
hl.bind(mainMod .. "+a", hl.dsp.workspace.toggle_special(""))
hl.bind(mainMod .. "+SHIFT+a", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. "+c", hl.dsp.window.center())
hl.bind(mainMod .. "+n", hl.dsp.exec_cmd("swaync-client -t"))
-- hl.bind(mainMod .. "+SHIFT+m", hl.dsp.exec_cmd(pypr .. " layout_center toggle")) -- toggle the layout
hl.bind(mainMod .. "+m", hl.dsp.workspace.toggle_special("minimized")) -- toggles "minimized" special workspace visibility
hl.bind(mainMod .. "+SHIFT+m", hl.dsp.exec_cmd(pypr .. " toggle_special minimized")) -- moves window to/from the "minimized" workspace
hl.bind(mainMod .. "+SHIFT+w", hl.dsp.exec_cmd(pypr .. " expose")) -- toggle expose
hl.bind(mainMod .. "+SHIFT+t", hl.dsp.exec_cmd(pypr .. " toggle term")) -- toggle dropdown terminal
-- focus change keys
-- hl.bind(mainMod .. "+left",  hl.dsp.exec_cmd(pypr .. " layout_center prev"))
-- hl.bind(mainMod .. "+right", hl.dsp.exec_cmd(pypr .. " layout_center next"))
-- hl.bind(mainMod .. "+up",    hl.dsp.exec_cmd(pypr .. " layout_center prev2"))
-- hl.bind(mainMod .. "+down",  hl.dsp.exec_cmd(pypr .. " layout_center next2"))

hl.bind("ALT+V", hl.dsp.exec_cmd("cliphist list | wofi -dmenu | cliphist decode | wl-copy")) -- Open clipboard manager
-- hl.bind(mainMod .. "+SHIFT+T", hl.dsp.exec_cmd("~/.config/hypr/hyprv_util vswitch")) -- Switch HyprV version
-- hl.bind(mainMod .. "+T",     hl.dsp.exec_cmd("~/.config/waybar/scripts/baraction")) -- Switch modes

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. "+left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. "+right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. "+up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. "+down", hl.dsp.focus({ direction = "down" }))

-- Move active window with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. "+SHIFT+left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. "+SHIFT+right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. "+SHIFT+up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. "+SHIFT+down", hl.dsp.window.move({ direction = "down" }))

-- Resize active window with mainMod + CTRL + arrow keys (relative pixel deltas)
hl.bind(mainMod .. "+CTRL+left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind(mainMod .. "+CTRL+right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
hl.bind(mainMod .. "+CTRL+up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind(mainMod .. "+CTRL+down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))

-- Switch workspaces with mainMod + [1-7]
-- Move active window to a workspace with mainMod + SHIFT + [1-7]
-- (Lua-only enhancement: loops replace 14 hand-written binds.)
for i = 1, 7 do
	hl.bind(mainMod .. "+" .. i, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. "+SHIFT+" .. i, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. "+mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. "+mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. "+mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. "+mouse:273", hl.dsp.window.resize(), { mouse = true })

-- hl.bind(mainMod .. "+grave",    hl.dsp.global("hyprexpo:expo"))         -- can be: toggle, off/disable or on/enable
-- hl.bind(mainMod .. "+grave",    hl.dsp.global("overview:toggle"))       -- can be: toggle, off/disable or on/enable
-- hl.bind(mainMod .. "+grave",    hl.dsp.global("scrolloverview:overview")) -- can be: toggle, select, off/disable or on/enable
hl.bind(mainMod .. "+grave", function()
	if hl.plugin and hl.plugin.scrolloverview then
		hl.plugin.scrolloverview.overview("toggle")
	end
end) -- can be: toggle, select, off/disable or on/enable

-------------------------------
---- MEDIA & SPECIAL KEYS  ----
-------------------------------

-- Volume
hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd(WAYBAR_SCRIPTS .. "/volume --inc"))
hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd(WAYBAR_SCRIPTS .. "/volume --dec"))
-- hl.bind("xf86AudioMicMute",  hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"))
hl.bind("xf86AudioMicMute", hl.dsp.exec_cmd(WAYBAR_SCRIPTS .. "/volume --toggle-mic"))
hl.bind("xf86AudioMute", hl.dsp.exec_cmd(WAYBAR_SCRIPTS .. "/volume --toggle"))

-- Keyboard brightness
hl.bind("xf86KbdBrightnessDown", hl.dsp.exec_cmd(WAYBAR_SCRIPTS .. "/kb-brightness --dec"))
hl.bind("xf86KbdBrightnessUp", hl.dsp.exec_cmd(WAYBAR_SCRIPTS .. "/kb-brightness --inc"))

-- Monitor brightness
hl.bind("xf86MonBrightnessDown", hl.dsp.exec_cmd(WAYBAR_SCRIPTS .. "/brightness --dec"))
hl.bind("xf86MonBrightnessUp", hl.dsp.exec_cmd(WAYBAR_SCRIPTS .. "/brightness --inc"))

-- Media player controls
hl.bind(
	"XF86AudioPlay",
	hl.dsp.exec_cmd(
		[[playerctl play-pause && notify-send -u low -i media-playback-start 'Player' 'Play/Pause Toggled']]
	)
)
hl.bind(
	"XF86AudioNext",
	hl.dsp.exec_cmd([[playerctl next       && notify-send -u low -i media-playback-forward 'Player' 'Next']])
)
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd([[playerctl previous   && notify-send -u low -i media-playback-backward 'Player' 'Previous']])
)
hl.bind(
	"XF86AudioStop",
	hl.dsp.exec_cmd([[playerctl stop       && notify-send -u low -i media-playback-stop 'Player' 'Stopped']])
)

-- Misc hardware keys
hl.bind("XF86WLAN", hl.dsp.exec_cmd("systemctl restart NetworkManager"))
hl.bind(
	"XF86TouchpadToggle",
	hl.dsp.exec_cmd([[toggleTouchpad && notify-send -u low -i mouse 'TouchPad' 'TouchPad Toggled']])
)

hl.bind("XF86Close", hl.dsp.window.close())

--------------------------------
---- WINDOW & LAYER RULES ----
--------------------------------

-- See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

-- Example windowrule v1
-- hl.window_rule({ float = true, match = { class = "^(kitty)$" } })

-- pavucontrol — volume scratchpad
hl.window_rule({
	match = { class = "^(pavucontrol)$" },
	float = true,
	size = "(monitor_w*0.4) (monitor_h*0.9)",
	move = "((monitor_w*2)) ((monitor_h*0.05))",
	workspace = "special:scratch_volume silent",
})

hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(chromium)$" }, float = true, animation = "popin" })
hl.window_rule({
	match = { class = "^(thunar)$" },
	float = true,
	animation = "popin",
	opacity = "0.8 0.8",
})
hl.window_rule({ match = { title = "^(btop)$" }, float = true })
hl.window_rule({ match = { title = "^(update-sys)$" }, float = true })

-- --
-- Repeat this for each scratchpad you need
-- hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("pypr toggle volume"))
-- hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pypr toggle term"))
hl.window_rule({
	match = { class = DROPTERM },
	float = true,
	workspace = "special:scratch_term silent",
	size = "(monitor_w*0.75) (monitor_h*0.6)",
	move = "((monitor_w*0.12)) (-(monitor_h*2))",
})
-- --

-- Example windowrule v2
-- hl.window_rule({ match = { class = "^(kitty)$", title = "^(kitty)$" }, float = true })
-- See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
-- rules below would make the specific app transparent
hl.window_rule({
	match = { class = "^()$", title = "^()" },
	no_blur = true,
	float = true,
	center = true,
})
hl.window_rule({ match = { class = "^(kitty)$" }, opacity = "0.8 0.8" })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(update-sys)$" }, animation = "popin" })
hl.window_rule({ match = { class = "^(VSCodium)$" }, opacity = "0.8 0.8" })
hl.window_rule({ match = { class = "^(VSCode)$" }, opacity = "0.8 0.8" })
-- hl.window_rule({ match = { class = "^(wofi)$" }, move = "cursor -3% -105%" })
-- hl.window_rule({ match = { class = "^(wofi)$" }, no_anim = true })
-- hl.window_rule({ match = { class = "^(wofi)$" }, opacity = "0.8 0.6" })
-- hl.window_rule({ match = { class = "^(wofi)$", title = "^(clippick)$" }, move = "100%-433 53" })
hl.window_rule({
	match = { class = "^(Rofi)$" },
	stay_focused = true,
	rounding = 1,
	dim_around = true,
	float = true,
	center = true,
})
-- hl.window_rule({ match = { class = "^(Rofi)$" }, focusonactivate = true })
hl.window_rule({ match = { class = "^(stacer)$" }, float = true, center = true })

hl.window_rule({ match = { class = "^(io.missioncenter.MissionCenter)$" }, float = true, opacity = "0.80 0.80" }) -- MissionCenter-Gtk
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(nm-applet|nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(qt5ct|qt6ct)$" }, float = true, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(vlc)$" }, float = true, size = "640 400" })
hl.window_rule({
	match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },
	float = true,
	opacity = "0.80 0.70",
})

hl.window_rule({ match = { class = "^(net.davidotek.pupgui2)$" }, opacity = "0.80 0.80" }) -- ProtonUp-Qt
hl.window_rule({ match = { class = "^(yad)$" }, opacity = "0.80 0.80" }) -- Protontricks-Gtk
hl.window_rule({ match = { class = "^(com.github.tchx84.Flatseal)$" }, opacity = "0.80 0.80" }) -- Flatseal-Gtk
hl.window_rule({ match = { class = "^(hu.kramo.Cartridges)$" }, opacity = "0.80 0.80" }) -- Cartridges-Gtk
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, opacity = "0.80 0.80" }) -- Obs-Qt
hl.window_rule({ match = { class = "^(gnome-boxes)$" }, opacity = "0.80 0.80" }) -- Boxes-Gtk
hl.window_rule({ match = { class = "^(nm-connection-editor|nm-applet)$" }, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(polkit-gnome-authentication-agent-1)$" }, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.gtk)$" }, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.hyprland)$" }, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^([Ss]team)$" }, opacity = "0.70 0.70" })
hl.window_rule({ match = { class = "^(steamwebhelper)$" }, opacity = "0.70 0.70" })
hl.window_rule({ match = { class = "^(zen|firefox)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(Google-chrome)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(Brave-browser)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(code-oss)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^([Cc]ode)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(code-url-handler)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(code-insiders-url-handler)$" }, opacity = "0.80 0.80" })

-- Caja properties
hl.window_rule({ match = { class = "^(caja)$", title = "^(.* Properties)$" }, float = true, center = true })

-- make Firefox PiP window floating and sticky
-- Picture in picture (resize and move done via script)
hl.window_rule({ match = { title = "Picture(-| )in(-| )[Pp]icture" }, move = "100%-w-2% 100%-w-3%" }) -- Initial move so window doesn't shoot across the screen from the center
hl.window_rule({ match = { title = "Picture(-| )in(-| )[Pp]icture" }, keep_aspect_ratio = true })
hl.window_rule({ match = { title = "Picture(-| )in(-| )[Pp]icture" }, float = true })
hl.window_rule({ match = { title = "Picture(-| )in(-| )[Pp]icture" }, pin = true })
-- hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true })

-- Float, resize and center
hl.window_rule({ match = { class = "kitty", title = "nmtui" }, float = true })
hl.window_rule({ match = { class = "kitty", title = "nmtui" }, size = "60% 70%" })
hl.window_rule({ match = { class = "kitty", title = "nmtui" }, center = 1 })
hl.window_rule({ match = { class = "org\\.gnome\\.Settings" }, float = true })
hl.window_rule({ match = { class = "org\\.gnome\\.Settings" }, size = "70% 80%" })
hl.window_rule({ match = { class = "org\\.gnome\\.Settings" }, center = 1 })
hl.window_rule({ match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser" }, float = true })
hl.window_rule({ match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser" }, size = "60% 70%" })
hl.window_rule({ match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser" }, center = 1 })
hl.window_rule({ match = { class = "nwg-look" }, float = true })
hl.window_rule({ match = { class = "nwg-look" }, size = "50% 60%" })
hl.window_rule({ match = { class = "nwg-look" }, center = 1 })
hl.window_rule({ match = { class = "^(nwg-look)$" }, opacity = "0.80 0.80" })

-- Dialog
hl.window_rule({ match = { title = "(Select|Open)( a)? (File|Folder)(s)?" }, float = true })
hl.window_rule({ match = { title = "File (Operation|Upload)( Progress)?" }, float = true })
hl.window_rule({ match = { title = ".* Properties" }, float = true })
hl.window_rule({ match = { title = "Export Image as PNG" }, float = true })
hl.window_rule({ match = { title = "GIMP Crash Debug" }, float = true })
hl.window_rule({ match = { title = "Save As" }, float = true })
hl.window_rule({ match = { title = "Library" }, float = true })

-- throw sharing indicators away
hl.window_rule({ match = { title = "^(Firefox - Sharing Indicator)$" }, workspace = "special silent" })
hl.window_rule({ match = { title = "^(Zen - Sharing Indicator)$" }, workspace = "special silent" })
hl.window_rule({ match = { title = "^(.*is sharing (your screen|a window)\\.)$" }, workspace = "special silent" })

-- idle inhibit while watching videos
hl.window_rule({ match = { class = "^(celluloid|vlc|mpv|.+exe)$" }, idle_inhibit = "focus" })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(.*Youtube.*)$" }, idle_inhibit = "focus" })
hl.window_rule({
	match = { class = "^(firefox)$" },
	idle_inhibit = "fullscreen",
})
hl.window_rule({
	match = { class = "^(brave)$", title = "^(.*Youtube.*)$" },
	idle_inhibit = "fullscreen",
})
hl.window_rule({
	match = { class = "^(brave-browser)$", title = "^(.*Youtube.*)$" },
	idle_inhibit = "fullscreen",
})
hl.window_rule({ match = { class = "^(zen)$", title = "^(.*Youtube.*)$" }, idle_inhibit = "focus" })
hl.window_rule({
	match = { class = "^(zen)$" },
	idle_inhibit = "fullscreen",
})

-- fix xwayland apps
hl.window_rule({ match = { xwayland = true, float = true }, rounding = 0 })
hl.window_rule({
	match = { class = "^(.*jetbrains.*)$", title = "^(Confirm Exit|Open Project|win424|win201|splash)$" },
	center = true,
})
hl.window_rule({ match = { class = "^(.*jetbrains.*)$", title = "^(splash)$" }, size = "640 400" })

-- Ugh xwayland popups
hl.window_rule({ match = { xwayland = true, title = "win[0-9]+" }, no_dim = true })
hl.window_rule({ match = { xwayland = true, title = "win[0-9]+" }, no_shadow = true })
hl.window_rule({ match = { xwayland = true, title = "win[0-9]+" }, rounding = 10 })

-- XWayland Video Sharing
hl.window_rule({
	match = { class = "^(xwaylandvideobridge)$" },
	opacity = "0.0 override 0.0 override",
	no_anim = true,
	no_initial_focus = true,
	max_size = "1 1",
	no_blur = true,
})

-- File pickers:
hl.window_rule({
	match = { class = "Xdg-desktop-portal-gtk" },
	center = true,
	size = "900 600",
})
hl.window_rule({
	match = { class = "claudia", title = "Open File" },
	center = true,
	size = "900 500",
	float = true,
})
hl.window_rule({
	match = { class = "Brave-browser", title = "Open Files" },
	center = true,
	size = "900 500",
})
hl.window_rule({
	match = { class = "^(zen)$", title = "About Zen Browser" },
	size = "900 500",
	float = true,
	center = true,
})
hl.window_rule({
	match = { class = "xdg-desktop-portal-gtk" },
	center = true,
	float = true,
	size = "900 600",
})
hl.window_rule({
	match = { class = "xdg-desktop-portal-gtk", title = "Save Image File" },
	center = true,
	float = true,
	size = "900 500",
})
hl.window_rule({ match = { class = "engrampa", title = "Extract" }, center = true, float = true })

-- PWAs:
hl.window_rule({
	match = { class = "Brave-browser", title = "^(Element)|^(Reddit)" },
	center = true,
	float = true,
	size = "(monitor_w*0.9) (monitor_h*0.85)",
})
hl.window_rule({ match = { class = "Brave-browser", title = "^(Outlook)|^(Microsoft)" }, tile = true })

-- Bauh
hl.window_rule({
	match = { class = "python3", title = "^(bauh)|^(Authentication)|^(Upgrade)|^(Backup)|^(System restart)" },
	center = true,
	float = true,
})

-- common modals
hl.window_rule({ match = { title = "^(Open)$" }, float = true })
hl.window_rule({ match = { title = "^(Choose Files)$" }, float = true })
hl.window_rule({ match = { title = "^(Save As)$" }, float = true })
hl.window_rule({ match = { title = "^(Confirm to replace files)$" }, float = true })
hl.window_rule({ match = { title = "^(File Operation Progress)$" }, float = true })
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, float = true })
hl.window_rule({ match = { class = "^(yad)$" }, float = true })

-- Layer rules
hl.layer_rule({ match = { namespace = LAYER_NAMESPACES }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "^(bar|gtk-layer-shell)$" }, xray = true })

hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "deadd-notification-center" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })

hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" }) -- Colour picker out animation
hl.layer_rule({ match = { namespace = "logout_dialog" }, animation = "fade" }) -- wlogout
hl.layer_rule({ match = { namespace = "selection" }, animation = "fade" }) -- slurp

hl.layer_rule({ match = { namespace = "launcher" }, animation = "popin 80%" })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true })

-- named rule syntax (Hyprland 0.53+)
-- blur
hl.layer_rule({
	name = "vicinae-blur",
	match = { namespace = "vicinae" },
	blur = true,
	ignore_alpha = 0,
})

-- disable animation for vicinae only
hl.layer_rule({
	name = "vicinae-no-animation",
	match = { namespace = "vicinae" },
	no_anim = true,
})

-- Workspace rules
-- Scroll rules
-- hl.workspace_rule({ workspace = "3", layout = "scrolling" })
-- hl.workspace_rule({ workspace = "3", layout_opts = { direction = "down" } })
hl.workspace_rule({ workspace = "4", layout = "scrolling" })
hl.workspace_rule({ workspace = "4", layout_opts = { direction = "right" } })

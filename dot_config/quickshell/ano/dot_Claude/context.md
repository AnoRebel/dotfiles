# Project Context: Ano QuickShell Configuration

## Overview
A comprehensive QuickShell desktop shell called "ano" located at `/home/ano/.config/quickshell/ano/`. Combines features from 7+ existing QuickShell configurations, using @rebels/ as the base. Supports both Hyprland and Niri with auto-detection. Pure QML/JS with hefty-hype polygon morph system.

## Final Stats
- **169 QML files** (21,112 lines)
- **14 JS files** (2,928 lines — polygon shape library from hefty-hype)
- **3 script files** (626 lines — switchwall.sh, applycolor.sh, get_keybinds.py)
- **1 JSON config** (30+ sections)
- **11 settings pages** (9 in overlay/standalone)
- **25 LazyLoaders** in shell.qml
- **25+ IPC targets**
- **23 module directories** (0 empty)
- **13 Hyprland + 1 Niri companion configs**

## Design Decisions (All Implemented)
1. **Compositor**: Runtime auto-detect + config default. CompositorService + NiriService.
2. **Hefty-Hype**: Polygon morph system ported (16 JS files + ShapeCanvas + MorphedPanel + TopLayerPanel + BarWidgetPopout + BarModulePopout). Per-bar `morphingPanel` flag enables it.
3. **Settings**: Both standalone `settings.qml` (FloatingWindow) AND `SettingsOverlay.qml` (layer-shell panel). 9 pages each.
4. **Moveable Bars**: Content configurable via JSON modules arrays. Bars moveable to 4 edges via config.
5. **Multiple Bars**: N bars per monitor from `bars[]` array. Panel families concept maintained.
6. **Bezel/Margins**: Global `appearance.bezel` for all elements.
7. **Hyprview Layouts**: All 10 layouts + random mode. In both AnoView overview AND separate TaskView.
8. **Config**: JSON with 30+ sections. Material You from wallpapers via matugen. Auto wallpaper rotation via awww.
9. **Pure QML/JS**: No C++ plugins. `plugins/` placeholder for future user extensions.
10. **Companion configs**: `~/.config/hypr/Ano/` (13 files) + `~/.config/niri/ano.kdl`
11. **Per-bar config**: Each bar supports per-bar overrides (morphingPanel, height, radius, spacing, padding, actions). Null = use global.

## Environment
- Language: QML/JavaScript
- Framework: QuickShell v0.2.1+
- Build: `qs -c ano`
- Config: `config.json` (JSON, FileView + JsonAdapter)
- Wallpaper: awww (v0.11+) + matugen (v4.0+) + optional pywal
- AI: OpenAI, Gemini, Anthropic, Mistral, OpenRouter, Ollama

## Source Configs Integrated
| Source | What Was Taken |
|--------|---------------|
| **@rebels/** | Base architecture, MD3 theme, Config/Appearance/Directories, widget library, services pattern |
| **@hyprview/** | All 10 overview layout algorithms + LayoutsManager |
| **@inir/** | CompositorService, NiriService, NiriKeybinds, enabledPanels, FamilyTransition, Dock, AltSwitcher, Translator, AI providers |
| **@ilyamiro/** | Weather/media/battery/network widget designs, toggle pill style |
| **@caelestia/** | Anim/CAnim, hover popups pattern, HUD concept |
| **@noctalia-shell/** | SpectrumService + spectrum visualizers, settings patterns |
| **@end-4 (main)** | AI chat service + sidebar, panel family system |
| **@end-4 (hefty-hype)** | Polygon shape library (rounded-polygon-qmljs), ShapeCanvas morph, MorphedPanel, TopLayerPanel, BarWidgetPopout, ChoreographerLayout, CombinedCircularProgress, FlyFadeEnterChoreographable |

## All Modules (23 directories, 0 empty)

### Core Infrastructure
- `common/` (63 files) — Config, Appearance, Directories, AnimationConfig, 5 utility libs, 50+ widgets, polygon shape system, spectrum widgets, choreographer, morph components

### Bar System
- `bar/` (19 files) — BarManager (N bars), BarWindow (4 edges, per-bar morph), BarContent (configurable spacing/padding/actions), 15 bar modules (8 with morph-capable popouts)

### Overlays & Panels
- `overview/` (3) — AnoView (10 layouts, compositor-agnostic)
- `taskView/` (1) — Current workspace windows, separate from overview
- `altSwitcher/` (1) — Alt-Tab window switcher with thumbnails
- `search/` (1) — App launcher with DesktopEntries + calculator
- `controlPanel/` (1) — Floating notification-shade quick controls
- `mediaControls/` (1) — Full media player with vinyl art + spectrum
- `weather/` (1) — Detailed weather panel
- `hud/` (1) — System dashboard overlay
- `session/` (1) — Hold-to-confirm power actions
- `wallpaperSelector/` (1) — Grid browser with directory nav
- `clipboard/` (1) — Clipboard history manager
- `cheatsheet/` (1) — Searchable keybind viewer
- `lock/` (1) — PAM lock screen (Niri only)

### Sidebars
- `sidebarLeft/` (8) — 3 tabs: AI Chat | Notifications | Translator
- `sidebarRight/` (7) — Configurable widget stack (sliders, toggles, media, calendar, system)

### Persistent Panels
- `dock/` (1) — Pill + macOS styles, 4-edge, pinned+running apps
- `osd/` (1) — 6 indicators (volume/brightness/mic/media/keyboard/network)
- `notificationPopup/` (1) — Stagger entry, swipe dismiss
- `notifications/` (1) — Reusable grouped notification component
- `screenCorners/` (1) — 4 hot corners with configurable dwell

### Settings
- `settings/` (11) — SettingsOverlay (9 pages) + SettingsCard
- Pages: General, Modules (enable/disable + OSD + corners + alt-tab + apps + compositor + advanced), Bar (layout/sizing/actions), Dock (position/style/sizing/behavior/apps), Sidebars, Appearance (colors/bezel/animations/wallpaper), Overview (layout selector), Services (AI/resources/brightness), About (user profile/avatar)

## Services (24 singletons)
Audio, Ai, Battery, BluetoothStatus, Brightness, Cliphist, CompositorService, DateTime, HyprlandData, HyprlandKeybinds, Idle, KeyboardLayoutService, MaterialThemeLoader, MprisController, Network, NiriKeybinds, NiriService, Notifications, ResourceUsage, SpectrumService, TrayService, Wallpapers, Weather, AnoSocket

## Scripts (with backup/restore)
- `switchwall.sh` — awww wallpaper + matugen colors + pywal + applycolor + config update
- `applycolor.sh` — Apply colors to kitty/ghostty/foot/cava/GTK
- `get_keybinds.py` — Parse Hyprland keybind config for cheatsheet

## Key File Paths
- Shell root: `/home/ano/.config/quickshell/ano/`
- Config: `/home/ano/.config/quickshell/ano/config.json`
- API keys: `/home/ano/.config/quickshell/ano/api_keys.json`
- Generated colors: `~/.local/state/ano/generated/colors.json`
- Backups: `~/.cache/ano/backups/`
- Hyprland companion: `~/.config/hypr/Ano/`
- Niri companion: `~/.config/niri/ano.kdl`
- Matugen config: `~/.config/matugen/config.toml`

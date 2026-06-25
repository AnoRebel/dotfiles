#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════
# Ano Shell — switchwall.sh
# Wallpaper switch + Material You color generation pipeline
#
# Usage: switchwall.sh --image PATH [--mode dark|light] [--monitor NAME]
#
# Pipeline:
#   1. Set wallpaper via awww (with transition)
#   2. Generate Material You colors via matugen → colors.json
#   3. Optionally run pywal for terminal colors (if wal is installed)
#   4. Optionally apply colors to external apps via applycolor.sh
#   5. Notify QuickShell to reload theme
#
# Safety:
#   - Backs up current config before changes
#   - All temp files in /tmp/anoshell-switchwall/
#   - Non-destructive: original files preserved with .bak suffix
# ══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── XDG Directories ──────────────────────────────────────────────────────
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

QUICKSHELL_CONFIG_NAME="ano"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
STATE_DIR="$XDG_STATE_HOME/anoshell/generated"
CACHE_DIR="$XDG_CACHE_HOME/anoshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$CACHE_DIR/backups"
COLORS_JSON="$STATE_DIR/colors.json"
MATUGEN_DIR="$XDG_CONFIG_HOME/matugen"
SHELL_CONFIG="$CONFIG_DIR/config.json"

# ── Temp directory ───────────────────────────────────────────────────────
TMPDIR="/tmp/anoshell-switchwall"
mkdir -p "$TMPDIR" "$STATE_DIR" "$BACKUP_DIR"

# ── Parse Arguments ──────────────────────────────────────────────────────
IMAGE=""
MODE="dark"
MONITOR=""
SKIP_PYWAL=false
SKIP_APPLY=false
TRANSITION="fade"
TRANSITION_DURATION="1.5"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image|-i)     IMAGE="$2"; shift 2 ;;
        --mode|-m)      MODE="$2"; shift 2 ;;
        --monitor)      MONITOR="$2"; shift 2 ;;
        --skip-pywal)   SKIP_PYWAL=true; shift ;;
        --skip-apply)   SKIP_APPLY=true; shift ;;
        --transition)   TRANSITION="$2"; shift 2 ;;
        --duration)     TRANSITION_DURATION="$2"; shift 2 ;;
        *)              echo "[switchwall] Unknown arg: $1"; shift ;;
    esac
done

if [[ -z "$IMAGE" ]]; then
    echo "[switchwall] Error: --image PATH is required"
    echo "Usage: switchwall.sh --image PATH [--mode dark|light] [--monitor NAME]"
    exit 1
fi

if [[ ! -f "$IMAGE" ]]; then
    echo "[switchwall] Error: Image not found: $IMAGE"
    exit 1
fi

log() { echo "[switchwall] $*"; }

# ── Safety: Backup current state ─────────────────────────────────────────
backup_current() {
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local bdir="$BACKUP_DIR/$ts"
    mkdir -p "$bdir"

    # Backup colors.json if exists
    [[ -f "$COLORS_JSON" ]] && cp "$COLORS_JSON" "$bdir/colors.json.bak"

    # Backup current wallpaper path from config
    if command -v jq &>/dev/null && [[ -f "$SHELL_CONFIG" ]]; then
        jq -r '.background.wallpaperPath // ""' "$SHELL_CONFIG" > "$bdir/wallpaper_path.bak" 2>/dev/null || true
    fi

    # Keep only last 10 backups
    ls -1dt "$BACKUP_DIR"/*/ 2>/dev/null | tail -n +11 | xargs rm -rf 2>/dev/null || true

    log "Backed up current state to $bdir"
}

# ── Restore from backup ─────────────────────────────────────────────────
restore_backup() {
    local latest
    latest=$(ls -1dt "$BACKUP_DIR"/*/ 2>/dev/null | head -1)
    if [[ -z "$latest" ]]; then
        log "No backups found"
        return 1
    fi

    if [[ -f "$latest/colors.json.bak" ]]; then
        cp "$latest/colors.json.bak" "$COLORS_JSON"
        log "Restored colors.json from $latest"
    fi

    if [[ -f "$latest/wallpaper_path.bak" ]]; then
        local old_wall
        old_wall=$(<"$latest/wallpaper_path.bak")
        if [[ -n "$old_wall" && -f "$old_wall" ]]; then
            log "Restored wallpaper: $old_wall"
            apply_wallpaper "$old_wall"
        fi
    fi

    # Notify shell to reload
    notify_shell
    return 0
}

# Handle --restore flag
if [[ "${1:-}" == "--restore" ]]; then
    restore_backup
    exit $?
fi

backup_current

# ── Step 1: Apply wallpaper via awww ─────────────────────────────────────
apply_wallpaper() {
    local img="$1"

    if command -v awww &>/dev/null; then
        local awww_args=("img" "--transition-type" "$TRANSITION" "--transition-duration" "$TRANSITION_DURATION")
        if [[ -n "$MONITOR" ]]; then
            awww_args+=("--outputs" "$MONITOR")
        fi
        awww_args+=("$img")
        awww "${awww_args[@]}" &
        log "Applied wallpaper via awww: $img"
    elif command -v swaybg &>/dev/null; then
        pkill swaybg 2>/dev/null || true
        swaybg -i "$img" -m fill &
        log "Applied wallpaper via swaybg: $img"
    else
        log "WARNING: No wallpaper engine found (awww, swaybg)"
    fi
}

apply_wallpaper "$IMAGE"

# ── Step 2: Generate Material You colors via matugen ─────────────────────
generate_matugen() {
    if ! command -v matugen &>/dev/null; then
        log "WARNING: matugen not installed — skipping Material You color generation"
        log "  Install: https://github.com/InioX/matugen"
        return 1
    fi

    # Ensure matugen config exists
    if [[ ! -f "$MATUGEN_DIR/config.toml" ]]; then
        mkdir -p "$MATUGEN_DIR/templates"
        log "Creating default matugen config..."
        cat > "$MATUGEN_DIR/config.toml" << 'MATUGENEOF'
[config]
reload_apps = false
strip = true

[templates.colors-json]
input_path = "~/.config/matugen/templates/colors.json"
output_path = "~/.local/state/anoshell/generated/colors.json"
MATUGENEOF
    fi

    # Ensure template exists
    if [[ ! -f "$MATUGEN_DIR/templates/colors.json" ]]; then
        mkdir -p "$MATUGEN_DIR/templates"
        cat > "$MATUGEN_DIR/templates/colors.json" << 'TEMPLATEEOF'
{
    "primary": "<primary>",
    "onPrimary": "<on_primary>",
    "primaryContainer": "<primary_container>",
    "onPrimaryContainer": "<on_primary_container>",
    "secondary": "<secondary>",
    "onSecondary": "<on_secondary>",
    "secondaryContainer": "<secondary_container>",
    "onSecondaryContainer": "<on_secondary_container>",
    "tertiary": "<tertiary>",
    "onTertiary": "<on_tertiary>",
    "tertiaryContainer": "<tertiary_container>",
    "onTertiaryContainer": "<on_tertiary_container>",
    "error": "<error>",
    "onError": "<on_error>",
    "errorContainer": "<error_container>",
    "onErrorContainer": "<on_error_container>",
    "background": "<background>",
    "onBackground": "<on_background>",
    "surface": "<surface>",
    "onSurface": "<on_surface>",
    "surfaceVariant": "<surface_variant>",
    "onSurfaceVariant": "<on_surface_variant>",
    "outline": "<outline>",
    "outlineVariant": "<outline_variant>",
    "shadow": "<shadow>",
    "scrim": "<scrim>",
    "inverseSurface": "<inverse_surface>",
    "inverseOnSurface": "<inverse_on_surface>",
    "inversePrimary": "<inverse_primary>",
    "surfaceDim": "<surface_dim>",
    "surfaceBright": "<surface_bright>",
    "surfaceContainerLowest": "<surface_container_lowest>",
    "surfaceContainerLow": "<surface_container_low>",
    "surfaceContainer": "<surface_container>",
    "surfaceContainerHigh": "<surface_container_high>",
    "surfaceContainerHighest": "<surface_container_highest>",
    "darkmode": true,
    "sourceColor": "<source_color>"
}
TEMPLATEEOF
    fi

    local mode_flag="$MODE"
    local type_flag="scheme-tonal-spot"

    # Read scheme type from config if available
    if command -v jq &>/dev/null && [[ -f "$SHELL_CONFIG" ]]; then
        local cfg_scheme
        cfg_scheme=$(jq -r '.appearance.colors.schemeType // "tonal-spot"' "$SHELL_CONFIG" 2>/dev/null || echo "tonal-spot")
        type_flag="scheme-${cfg_scheme}"
    fi

    log "Generating Material You colors (mode=$mode_flag, type=$type_flag)..."
    matugen --config "$MATUGEN_DIR/config.toml" image "$IMAGE" --mode "$mode_flag" --type "$type_flag" 2>&1 | while read -r line; do
        log "  matugen: $line"
    done

    # Fix darkmode field based on actual mode
    if command -v jq &>/dev/null && [[ -f "$COLORS_JSON" ]]; then
        local is_dark="true"
        [[ "$mode_flag" == "light" ]] && is_dark="false"
        local tmp="$TMPDIR/colors_fixed.json"
        jq --argjson dm "$is_dark" '.darkmode = $dm' "$COLORS_JSON" > "$tmp" && mv "$tmp" "$COLORS_JSON"
    fi

    log "Material You colors generated: $COLORS_JSON"
    return 0
}

generate_matugen || true

# ── Step 3: Optionally run pywal ─────────────────────────────────────────
run_pywal() {
    if [[ "$SKIP_PYWAL" == true ]]; then return; fi
    if ! command -v wal &>/dev/null; then return; fi

    log "Running pywal for terminal colors..."
    wal -i "$IMAGE" -n -q -e 2>/dev/null || true

    # Source pywal colors and update cava if config exists
    local cava_config="$HOME/.config/cava/config"
    if [[ -f "$HOME/.cache/wal/colors.sh" ]]; then
        # shellcheck source=/dev/null
        source "$HOME/.cache/wal/colors.sh" 2>/dev/null || true

        if [[ -f "$cava_config" ]]; then
            sed -i \
                -e "s/^background = .*/background = '${background:-#1C1B1F}'/" \
                -e "s/^foreground = .*/foreground = '${foreground:-#E6E1E5}'/" \
                -e "s/^gradient_color_1 = .*/gradient_color_1 = '${color2:-#65558F}'/" \
                -e "s/^gradient_color_2 = .*/gradient_color_2 = '${color3:-#7F77DD}'/" \
                -e "s/^gradient_color_3 = .*/gradient_color_3 = '${color4:-#AFA9EC}'/" \
                -e "s/^gradient_color_4 = .*/gradient_color_4 = '${color5:-#CECBF6}'/" \
                -e "s/^gradient_color_5 = .*/gradient_color_5 = '${color6:-#E8DEF8}'/" \
                -e "s/^gradient_color_6 = .*/gradient_color_6 = '${color7:-#F1D3F9}'/" \
                -e "s/^gradient_color_7 = .*/gradient_color_7 = '${color8:-#EEDDFF}'/" \
                -e "s/^gradient_color_8 = .*/gradient_color_8 = '${color9:-#F5EEFF}'/" \
                "$cava_config" 2>/dev/null || true
            pkill -USR2 cava 2>/dev/null || true
            log "Updated cava gradient colors"
        fi
    fi
}

run_pywal

# ── Step 4: Apply colors to external apps ────────────────────────────────
apply_external() {
    if [[ "$SKIP_APPLY" == true ]]; then return; fi

    local apply_script="$SCRIPT_DIR/applycolor.sh"
    if [[ -x "$apply_script" ]]; then
        log "Applying colors to external apps..."
        bash "$apply_script" --mode "$MODE" 2>&1 | while read -r line; do
            log "  applycolor: $line"
        done
    fi
}

apply_external

# ── Step 5: Update config.json with new wallpaper path ───────────────────
update_config() {
    if ! command -v jq &>/dev/null; then return; fi
    if [[ ! -f "$SHELL_CONFIG" ]]; then return; fi

    local tmp="$TMPDIR/config_updated.json"
    jq --arg path "$IMAGE" '.background.wallpaperPath = $path' "$SHELL_CONFIG" > "$tmp" && mv "$tmp" "$SHELL_CONFIG"
    log "Updated config.json wallpaper path"
}

update_config

# ── Step 6: Notify QuickShell to reload theme ────────────────────────────
notify_shell() {
    if command -v qs &>/dev/null; then
        qs -c ano ipc call wallpapers apply "$IMAGE" 2>/dev/null || true
    fi
}

notify_shell

# ── Step 7: Set GNOME dark/light mode ────────────────────────────────────
set_gtk_mode() {
    if ! command -v gsettings &>/dev/null; then return; fi

    if [[ "$MODE" == "dark" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3' 2>/dev/null || true
    fi
}

set_gtk_mode

log "Done! Wallpaper: $IMAGE (mode: $MODE)"

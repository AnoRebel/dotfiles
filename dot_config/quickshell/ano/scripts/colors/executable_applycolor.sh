#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════
# Ano Shell — applycolor.sh
# Applies generated Material You colors to external applications.
# Called by switchwall.sh after color generation.
#
# Currently supports: kitty, ghostty, foot, cava, GTK dark/light
# Extend by adding functions below.
# ══════════════════════════════════════════════════════════════════════════

set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
COLORS_JSON="$XDG_STATE_HOME/anoshell/generated/colors.json"
MODE="dark"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode|-m) MODE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [[ ! -f "$COLORS_JSON" ]]; then
    echo "[applycolor] colors.json not found at $COLORS_JSON"
    exit 0
fi

if ! command -v jq &>/dev/null; then
    echo "[applycolor] jq not installed — cannot parse colors"
    exit 0
fi

log() { echo "[applycolor] $*"; }

# Read colors
primary=$(jq -r '.primary' "$COLORS_JSON")
onPrimary=$(jq -r '.onPrimary' "$COLORS_JSON")
background=$(jq -r '.background' "$COLORS_JSON")
onBackground=$(jq -r '.onBackground' "$COLORS_JSON")
surface=$(jq -r '.surface' "$COLORS_JSON")
onSurface=$(jq -r '.onSurface' "$COLORS_JSON")
surfaceContainer=$(jq -r '.surfaceContainer' "$COLORS_JSON")
secondary=$(jq -r '.secondary' "$COLORS_JSON")
error=$(jq -r '.error' "$COLORS_JSON")

# ── Kitty ────────────────────────────────────────────────────────────────
apply_kitty() {
    if ! command -v kitty &>/dev/null; then return; fi
    # Send OSC escape sequences to all kitty instances
    for sock in /tmp/kitty-*/; do
        [[ -d "$sock" ]] || continue
        kitty @ --to "unix:${sock}control" set-colors \
            "foreground=$onBackground" \
            "background=$background" \
            "cursor=$primary" \
            "selection_foreground=$onPrimary" \
            "selection_background=$primary" \
            2>/dev/null || true
    done
    log "Applied colors to kitty"
}

# ── Ghostty ──────────────────────────────────────────────────────────────
apply_ghostty() {
    local config="$XDG_CONFIG_HOME/ghostty/config"
    [[ -f "$config" ]] || return

    # Backup
    cp "$config" "$config.bak" 2>/dev/null || true

    # Update colors using sed
    sed -i \
        -e "s/^background = .*/background = ${background}/" \
        -e "s/^foreground = .*/foreground = ${onBackground}/" \
        -e "s/^cursor-color = .*/cursor-color = ${primary}/" \
        -e "s/^selection-foreground = .*/selection-foreground = ${onPrimary}/" \
        -e "s/^selection-background = .*/selection-background = ${primary}/" \
        "$config" 2>/dev/null || true

    log "Applied colors to ghostty config"
}

# ── Foot ─────────────────────────────────────────────────────────────────
apply_foot() {
    local config="$XDG_CONFIG_HOME/foot/foot.ini"
    [[ -f "$config" ]] || return

    cp "$config" "$config.bak" 2>/dev/null || true

    # Strip # from hex colors for foot format
    local bg="${background/#\#/}"
    local fg="${onBackground/#\#/}"

    sed -i \
        -e "s/^background=.*/background=${bg}/" \
        -e "s/^foreground=.*/foreground=${fg}/" \
        "$config" 2>/dev/null || true

    log "Applied colors to foot config"
}

# ── Cava (if pywal didn't already handle it) ─────────────────────────────
apply_cava() {
    local config="$HOME/.config/cava/config"
    [[ -f "$config" ]] || return

    # Only update if pywal didn't already
    if [[ -f "$HOME/.cache/wal/colors.sh" ]]; then return; fi

    cp "$config" "$config.bak" 2>/dev/null || true

    sed -i \
        -e "s/^background = .*/background = '${background}'/" \
        -e "s/^foreground = .*/foreground = '${primary}'/" \
        "$config" 2>/dev/null || true

    pkill -USR2 cava 2>/dev/null || true
    log "Applied colors to cava"
}

# ── Run all ──────────────────────────────────────────────────────────────
apply_kitty
apply_ghostty
apply_foot
apply_cava

log "Done applying colors to external apps"

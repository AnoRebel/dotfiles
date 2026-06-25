#!/bin/bash

# Randomly cycles through images in a directory, setting the wallpaper
# at regular intervals. Single-display variant.
# Also applies pywal theme + cava colors on each wallpaper change.
#
# Updated for awww (successor of swww)
# See: https://codeberg.org/LGFae/awww

if [[ $# -lt 1 ]] || [[ ! -d "$1" ]]; then
	printf "Usage:\n\t%s <dir containing images> [interval in seconds]\n" "$0"
	exit 1
fi

# ── Transition settings (override via env) ───────────────────────────
export AWWW_TRANSITION_FPS="${AWWW_TRANSITION_FPS:-60}"
export AWWW_TRANSITION_STEP="${AWWW_TRANSITION_STEP:-2}"

INTERVAL="${2:-300}"
RESIZE_TYPE="fit"
CAVA_CONFIG="$HOME/.config/cava/config"

# ── Helper: apply pywal theme + update cava colors ───────────────────
apply_theme() {
	local img="$1"

	wal -i "$img" 2>/dev/null
	swaync-client --reload-css 2>/dev/null

	# Source once instead of spawning 10 separate awk processes
	# shellcheck source=/dev/null
	source ~/.cache/wal/colors.sh 2>/dev/null || return

	if [ -f "$CAVA_CONFIG" ]; then
		sed -i \
			-e "s/^background = .*/background = '${background}'/" \
			-e "s/^foreground = .*/foreground = '${foreground}'/" \
			-e "s/^gradient_color_1 = .*/gradient_color_1 = '${color2}'/" \
			-e "s/^gradient_color_2 = .*/gradient_color_2 = '${color3}'/" \
			-e "s/^gradient_color_3 = .*/gradient_color_3 = '${color4}'/" \
			-e "s/^gradient_color_4 = .*/gradient_color_4 = '${color5}'/" \
			-e "s/^gradient_color_5 = .*/gradient_color_5 = '${color6}'/" \
			-e "s/^gradient_color_6 = .*/gradient_color_6 = '${color7}'/" \
			-e "s/^gradient_color_7 = .*/gradient_color_7 = '${color8}'/" \
			-e "s/^gradient_color_8 = .*/gradient_color_8 = '${color9}'/" \
			"$CAVA_CONFIG"
		# Signal cava to reload; don't launch it if it's not running
		pkill -USR2 cava 2>/dev/null || true
	fi
}

# ── Main loop ────────────────────────────────────────────────────────
while true; do
	find "$1" -type f \
	| while read -r img; do
		echo "$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 8):$img"
	done \
	| sort | cut -d':' -f2- \
	| while read -r img; do
		awww img --resize "$RESIZE_TYPE" "$img"
		apply_theme "$img"
		sleep "$INTERVAL"
	done
done

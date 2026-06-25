#!/bin/bash

# Randomly cycles through images in a directory, setting a different
# random wallpaper for each display at regular intervals.
# Also applies pywal theme + cava colors on each wallpaper change.
#
# Updated for awww (successor of swww)
# See: https://codeberg.org/LGFae/awww

if [[ $# -lt 1 ]] || [[ ! -d "$1" ]]; then
	printf "Usage:\n\t%s <dir containing images> [interval in seconds]\n" "$0"
	exit 1
fi

# ── Singleton guard ──────────────────────────────────────────────────
mkdir -p ~/.local/state
PIDFILE=~/.local/state/awww-randomize-pidfile.txt

cleanup() {
	rm -f "${PIDFILE}"
	exit 0
}
trap cleanup EXIT INT TERM HUP

if [ -e "${PIDFILE}" ]; then
	OLD_PID="$(<"${PIDFILE}")"
	if [ -n "${OLD_PID}" ] && [ -e "/proc/${OLD_PID}" ]; then
		OLD_NAME="$(</proc/${OLD_PID}/comm)"
		THIS_NAME="$(</proc/${BASHPID}/comm)"
		if [ "${OLD_NAME}" = "${THIS_NAME}" ]; then
			echo "old randomize process ${OLD_PID} is still running"
			exit 1
		else
			echo "process with same ID as old randomize is running: \"${OLD_NAME}\"@${OLD_PID}"
			echo "Replacing old process ID"
		fi
	fi
fi
echo "${BASHPID}" >"${PIDFILE}"

# ── Transition settings (override via env) ───────────────────────────
export AWWW_TRANSITION_FPS="${AWWW_TRANSITION_FPS:-60}"
export AWWW_TRANSITION_STEP="${AWWW_TRANSITION_STEP:-2}"

INTERVAL="${2:-300}"

# Possible values: no | crop | fit | stretch
RESIZE_TYPE="fit"

CAVA_CONFIG="$HOME/.config/cava/config"

# ── Helper: apply pywal theme + update cava colors ───────────────────
apply_theme() {
	local img="$1"

	wal -i "$img" 2>/dev/null
	swaync-client --reload-css 2>/dev/null

	# Source the colors file once instead of spawning 10 separate awk processes
	# shellcheck source=/dev/null
	source ~/.cache/wal/colors.sh 2>/dev/null || return

	# Update cava config in a single sed pass (avoids 10 separate file read/write cycles)
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
		# Signal cava to reload config; don't launch it if it's not already running
		pkill -USR2 cava 2>/dev/null || true
	fi

	# Generate zellij + yazi themes from pywal colors
	"$HOME/.config/awww/scripts/awww_generate_themes.sh" 2>/dev/null || true
}

# ── Main loop ────────────────────────────────────────────────────────
while true; do
	find "$1" -type f \
	| while read -r img; do
		echo "$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 8):$img"
	done \
	| sort | cut -d':' -f2- \
	| while read -r img; do
		theme_img=""
		# Set a different image for each display
		for disp in $(awww query | awk '{print $2}' | sed 's/://'); do
			# If current image was used, grab the next one (or reshuffle)
			[ -z "$img" ] && if read -r img; then true; else break 2; fi
			awww img --resize "$RESIZE_TYPE" --outputs "$disp" "$img"
			theme_img="$img"    # remember for theming
			unset -v img        # each image used only once per loop
		done

		# Apply theme ONCE per wallpaper cycle, not per-display
		if [ -n "$theme_img" ]; then
			apply_theme "$theme_img"
		fi

		sleep "$INTERVAL"
	done
done

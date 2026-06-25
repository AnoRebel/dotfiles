#!/bin/sh

# Schedule an image switch at a specific time using the 'at' command.
# Theme application is bundled INTO the scheduled job so it runs
# when the wallpaper actually changes, not when the schedule is set.
#
# Updated for awww (successor of swww)
# See: https://codeberg.org/LGFae/awww

if [ $# -lt 2 ]; then
	cat <<-USAGE
	Usage:
	  $0 <path/to/img> <time in HH:MM format> [extra awww img args...]

	This will use the 'at' command to schedule the image switch.
	You can pass extra awww options after the time:

	  $0 path/to/img 18:00 --transition-fps 60 --transition-step 5
	USAGE
	exit 1
fi

if ! type "at" >/dev/null 2>&1; then
	echo "ERROR: 'at' command doesn't exist!"
	exit 1
fi

IMG="$1"
TIME="$2"
shift 2
EXTRA_ARGS="$*"

CAVA_CONFIG="$HOME/.config/cava/config"

# Schedule the wallpaper change AND theme application together
# so colors are extracted AFTER the image is actually set.
cat <<SCHEDULED | at "$TIME"
awww img ${EXTRA_ARGS} "$IMG"
wal -i "$IMG" 2>/dev/null
swaync-client --reload-css 2>/dev/null
. ~/.cache/wal/colors.sh 2>/dev/null && [ -f "$CAVA_CONFIG" ] && sed -i \\
	-e "s/^background = .*/background = '\${background}'/" \\
	-e "s/^foreground = .*/foreground = '\${foreground}'/" \\
	-e "s/^gradient_color_1 = .*/gradient_color_1 = '\${color2}'/" \\
	-e "s/^gradient_color_2 = .*/gradient_color_2 = '\${color3}'/" \\
	-e "s/^gradient_color_3 = .*/gradient_color_3 = '\${color4}'/" \\
	-e "s/^gradient_color_4 = .*/gradient_color_4 = '\${color5}'/" \\
	-e "s/^gradient_color_5 = .*/gradient_color_5 = '\${color6}'/" \\
	-e "s/^gradient_color_6 = .*/gradient_color_6 = '\${color7}'/" \\
	-e "s/^gradient_color_7 = .*/gradient_color_7 = '\${color8}'/" \\
	-e "s/^gradient_color_8 = .*/gradient_color_8 = '\${color9}'/" \\
	"$CAVA_CONFIG"
pkill -USR2 cava 2>/dev/null || true
SCHEDULED

echo "Scheduled wallpaper change to '$IMG' at $TIME"

# NOTE: To schedule multiple images at once, create a wrapper function:
#
# awww_schedule() {
#     $0 "$@"
# }
#
# awww_schedule path/to/morning.jpg 06:00
# awww_schedule path/to/evening.jpg 18:00

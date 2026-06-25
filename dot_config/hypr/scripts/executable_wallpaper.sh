#!/bin/bash

# Interactive wallpaper picker using wofi.
# Sets the wallpaper via awww, applies pywal theme + cava colors.

WALLPAPER_DIR="$HOME/Pictures/hyprwallpapers"
CAVA_CONFIG="$HOME/.config/cava/config"

menu() {
	find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) \
		| awk '{print "img:"$0}'
}

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

main() {
	choice=$(menu | wofi -c ~/.config/wofi/config1 -s ~/.config/wofi/style1.css --show dmenu --prompt "Select Wallpaper:" -n)

	if [[ -n "$choice" ]]; then
		selected_wallpaper="${choice#img:}"
		awww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
		apply_theme "$selected_wallpaper"
		source ~/.cache/wal/colors.sh 2>/dev/null
		notify-send "Hyprland" "Wallpaper changed, hence theme changed"
	else
		notify-send "Hyprland" "No wallpaper selected."
	fi
}

main

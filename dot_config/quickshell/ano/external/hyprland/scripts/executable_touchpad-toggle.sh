#!/usr/bin/env bash
# Toggle laptop touchpad on/off
# Bind: XF86TouchpadToggle

TOUCHPAD_STATUS=$(hyprctl getoption input:touchpad:disable_while_typing -j | jq -r '.int')

if hyprctl getoption input:touchpad:tap-to-click -j 2>/dev/null | jq -e '.int == 1' > /dev/null 2>&1; then
    # Touchpad seems active, disable it
    hyprctl keyword "input:touchpad:tap-to-click" 0
    hyprctl keyword "input:touchpad:natural_scroll" 0
    notify-send -u low "Touchpad" "Disabled"
else
    hyprctl keyword "input:touchpad:tap-to-click" 1
    hyprctl keyword "input:touchpad:natural_scroll" 1
    notify-send -u low "Touchpad" "Enabled"
fi

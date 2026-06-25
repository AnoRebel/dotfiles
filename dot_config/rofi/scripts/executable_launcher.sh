#!/bin/bash

# List of numbers to choose from
numbers=(1 3 5 6 7)

# Randomly select one number from the list
selected_number=${numbers[$RANDOM % ${#numbers[@]}]}

$HOME/.config/rofi/themes/type-${selected_number}/launcher.sh

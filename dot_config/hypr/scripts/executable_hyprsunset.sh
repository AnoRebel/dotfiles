#!/bin/bash

prev_status
# Function to check if it's daytime or nighttime
check_time() {
	local current_time=$(date +%H:%M)

	# Assuming daytime is from 6 AM to 6 PM
	if [[ $current_time > "05:59" && $current_time < "19:00" ]]; then
		echo "daytime"
	else
		echo "nighttime"
	fi
}

# Main function
main() {
	local time_status=$(check_time)

	case $time_status in
	daytime)
		echo "Running command during daytime..."
		if [[ $prev_status != "$time_status" ]]; then
			killall hyprsunset
			hyprsunset -t 5700
			prev_status=$time_status
		fi
		;;
	nighttime)
		echo "Running command during nighttime..."
		if [[ $prev_status != "$time_status" ]]; then
			killall hyprsunset
			hyprsunset -t 3500
			prev_status=$time_status
		fi
		;;
	esac
	sleep 3600
}

# Run the main function
while true; do
	main
done

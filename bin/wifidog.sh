#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 IP"
	exit 1
fi
IP=$1

broken_count=0
while :; do
	echo -n "Checking airport..."
	if ping -c 1 -t 1 $IP &>/dev/null; then
		broken_count=0
		echo "OK"
	else
		broken_count=$((broken_count+1))
		echo "Broken($broken_count)"
	fi
	if [[ $broken_count -eq 0 ]]; then
		sleep 3
	elif [[ $broken_count -lt 3 ]]; then
		sleep 1
	else
		echo -n "Restarting airport..."
		networksetup -setairportpower airport off &>/dev/null
		sleep 3
		networksetup -setairportpower airport on &>/dev/null
		echo "Done"
		sleep 10
		broken_count=0
	fi
done

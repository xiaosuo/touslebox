#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 IP"
	exit 1
fi
IP=$1

while :; do
	echo -n "Checking airport..."
	if ping -c 1 -t 1 $IP &>/dev/null; then
		echo "OK"
		sleep  3
	else
		sleep 1
		echo "Broken"
		echo -n "Restarting airport..."
		networksetup -setairportpower airport off &>/dev/null
		sleep 3
		networksetup -setairportpower airport on &>/dev/null
		echo "Done"
		sleep 10
	fi
done

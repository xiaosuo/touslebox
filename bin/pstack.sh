#!/bin/bash

if [ $# -ne 1 ]; then
	echo "Usage: $0 <PID>"
	exit 1
fi
pid=$1

gdb /proc/$pid/exe $pid -ex 'thread apply all bt' -ex 'set confirm off' \
	-ex 'quit'

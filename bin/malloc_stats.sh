#!/bin/bash

set -e

if [ $# -ne 1 ]; then
	echo "Usage: $0 <PID>"
	exit 1
fi
PID=$1

if grep -q jemalloc /proc/$PID/maps; then
	gdb attach $PID \
		-ex 'call malloc_stats_print((void*)0, (void*)0, (void*)0)' \
		-batch
else
	gdb attach $1 -ex 'call malloc_stats()' -batch
fi

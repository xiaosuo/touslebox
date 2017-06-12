#!/bin/bash

set -e

if [ $# -ne 1 ]; then
	echo "Usage: $0 <PID>"
	exit 1
fi
PID=$1

SOLIB_PATH=`cat /proc/$PID/maps | awk '/\// {gsub("/[^/]*$", "", $NF); s[$NF]=1} END{ORS=":"; for(k in s){print k}}'`
SOLIB_PATH=${SOLIB_PATH%:}
if grep -q jemalloc /proc/$PID/maps; then
	gdb \
		-ex "set solib-search-path $SOLIB_PATH" \
		-ex "attach $PID" \
		-ex 'call malloc_stats_print((void*)0, (void*)0, (void*)0)' \
		-batch
else
	gdb \
		-ex "set solib-search-path $SOLIB_PATH" \
		-ex "attach $PID" \
		-ex 'call malloc_stats()' \
		-batch
fi

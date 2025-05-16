#!/bin/sh

THRESHOLD=80
PROCESS_NAME="nd"

PID="`pgrep $PROCESS_NAME`"
test -n "$PID" || continue
CPU_USAGE="`ps -p $PID -o %cpu | tail -n 1 | awk '{print int($1)}'`"
test "$CPU_USAGE" -le "$THRESHOLD" || exit 0
rcctl restart nd >/dev/null 2>&1

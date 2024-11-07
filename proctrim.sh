#!/bin/sh

THRESHOLD=90
INTERVAL=5
PROCESS_NAME="nd"

while true; do
    PID="`pgrep $PROCESS_NAME`"
    sleep $INTERVAL
    test -n "$PID" || continue
    CPU_USAGE="`ps -p $PID -o %cpu | tail -n 1 | awk '{print int($1)}'`"
    test "$CPU_USAGE" -gt "$THRESHOLD" || continue
    rcctl restart nd
done

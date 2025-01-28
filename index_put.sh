#!/bin/sh
target=index.db
test $# -lt 1 || target=$1
qhash="`pnpm root -w`/@tty-pt/qhash/qhash"
cmd="$qhash `while read line; do echo -n " -p '$line'"; done` $target"
echo "$cmd"
sh -c "$cmd"

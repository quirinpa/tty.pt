#!/bin/sh
translate() {
	iconv -f utf-8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /_/g'
}

target=index.db:s
test $# -lt 1 || target=$1:s
#qhash="`pnpm root -w`/@tty-pt/qhash/qhash"
qhash=qhash
cmd="$qhash `while read link line; do echo -n " -p '$link:$line'"; done` $target"
echo "$cmd"
sh -c "$cmd"

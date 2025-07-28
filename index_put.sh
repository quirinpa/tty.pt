#!/bin/sh
translate() {
	iconv -f utf-8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /_/g'
}

target=index.db:s
test $# -lt 1 || target=$1:s
#qhash="`pnpm root -w`/@tty-pt/qdb/qdb"
qdb=$DOCUMENT_ROOT/usr/local/bin/qdb
cmd="$qdb `while read link line; do echo -n " -p '$link:$line'"; done` $target"
echo "$cmd"
sh -c "$cmd"

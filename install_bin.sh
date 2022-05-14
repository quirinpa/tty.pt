#!/bin/ksh
path="`which $1`"
ROOT=/var/www
ldd $path | awk '{ print $7 }' | tail -n +3 | while read line; do
	target_path="`dirname $line`"
	[[ -d "$ROOT$target_path" ]] || mkdir -p $target_path
	[[ -f "$ROOT$line" ]] || cp $line $ROOT$line
done
echo $path >> .install_bin

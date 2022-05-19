#!/bin/ksh

ROOT=/var/www

install() {
	path=$1
	ldd $path | awk '{ print $7 }' | tail -n +3 | while read line; do
		target_path="`dirname $line`"
		[[ -d "$ROOT$target_path" ]] || mkdir -p $ROOT$target_path
		[[ -f "$ROOT$line" ]] || cp $line $ROOT$line
	done
}

if [[ $# -lt 1 ]]; then
	cat .install_bin | while read line; do install "`which $line`"; done
	exit
fi

install "`which $1`"
echo $1 >> .install_bin

#!/bin/ksh

ROOT=/var/www

install_extra() {
	line=$1
	target_path="`dirname $line`"
	[[ -d "$ROOT$target_path" ]] || mkdir -p $ROOT$target_path
	[[ -f "$ROOT$line" ]] || cp $line $ROOT$line
}

install_bin() {
	path=$1
	ldd $path | awk '{ print $7 }' | tail -n +3 | while read line; do
		install_extra "$line"
	done
}

if [[ $# -lt 1 ]]; then
	cat .install_bin | while read line; do install_bin "`which $line`"; done
	cat .install_extra | while read line; do install_extra "$line"; done
	exit
fi

install_bin "`which $1`"
echo $1 >> .install_bin

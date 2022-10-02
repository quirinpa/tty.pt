#!/bin/ksh

ROOT=/var/www

install_extra() {
	line=$1
	target_path="`dirname $line`"
	[[ -d "$ROOT$target_path" ]] || mkdir -p $ROOT$target_path
	if [[ ! -f "$ROOT$line" ]]; then
		cp $line $ROOT$line
		echo cp $line $ROOT$line
	fi
}

ecp() {
	mkdir -p `dirname $2` 2>/dev/null || true
	cp $1 $2
}

install_bin() {
	path=$1
	tmp=/tmp/$path
	ecp $path /tmp/$path
	ldd /tmp/$path | awk '{ print $7 }' | tail -n +4 | while read line; do
		install_extra "$line"
	done
	install_extra $path
	rm /tmp/$path
}

if [[ $# -lt 1 ]]; then
	cat .install_bin | while read line; do install_bin "`which $line`"; done
	cat .install_extra | while read line; do install_extra "$line"; done
	exit
fi

install_bin "`which $1`"
echo $1 >> .install_bin

#!/bin/ksh

. $ROOT/lib/common.sh

Image() {
	cat <<!
<img height="128" class="ofc s_k256 b0" src="/img/$1" />
!
}

Images() {
	while read line; do
		Image $line
	done
}

find_images() {
	 find $1 -type f | sed "s|$1||"
}

case "$REQUEST_METHOD" in
	GET)
		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export _TITLE="`_ Images`"
		export MENU="`Menu ./images.cgi?`"
		export IMAGES="`find_images $ROOT/htdocs/img | Images`"
		cat $ROOT/templates/images.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


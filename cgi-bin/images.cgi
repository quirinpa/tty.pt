#!/bin/ksh

. $ROOT/lib/common.sh

Image() {
	cat <<!
<img height="128" class="ofc s_k256 b0" src="https://tty.pt/img/$1" />
!
}

Images() {
	while read line; do
		Image $line
	done
}

find_images() {
	 find $1 -type f | sed "s|$1/||"
}

case "$REQUEST_METHOD" in
	GET)
		export _TITLE="`_ Images`"
		IMAGES="`find_images $ROOT/htdocs/img | Images`"
		if [[ ! -z "$IMAGES" ]]; then
			IMAGES="<div class=\"_ f fw v fcc fic\">$IMAGES</div>"
		fi
		export IMAGES
		NormalCat
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


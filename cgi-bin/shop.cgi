#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh

lsshown() {
	 find $1 -type d -mindepth 1 -maxdepth 1 -name "[!.]*" | sed "s|$1||"
}

Category() {
	CATEGORY_ID="$1"
	CATEGORY_NAME="`_ $CATEGORY_ID`"
	cat <<!
<option value="$CATEGORY_ID">$CATEGORY_NAME</option>
!
}

case "$REQUEST_METHOD" in
	GET)
		if [[ -z "$shop_id" ]]; then
			echo 'Status: 400 Bad Request'
			echo
			exit;
		fi

		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		SHOP_DIR="$ROOT/shops/$shop_id"

		export shop_id
		export _TITLE="`_ $shop_id`"

		export SHOP_CATEGORIES="`lsshown $SHOP_DIR/.categories/ | while read line; do Category $line; done`"
		export PRODUCTS="`lsshown $SHOP_DIR/ | while read line; do Product $line "y"; done`"
		export MENU="`Menu ./shop.cgi?shop_id=$shop_id\&`"
		cat $ROOT/templates/shop.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


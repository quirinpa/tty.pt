#!/bin/ksh

. $ROOT/lib/common.sh

Shop() {
	SHOPNAME="$1"
	_TITLE="`_ $SHOPNAME`"
	cat <<EOF
<h1><a href="/cgi-bin/shop.cgi?lang=$lang&shop_id=$SHOPNAME">
	$_TITLE
</a></h1>
EOF
}

shops() {
	ls $ROOT/shops | while read line; do Shop $line; done
}

case "$REQUEST_METHOD" in
	GET)
		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export _TITLE="`_ Shops`"

		export SHOPS="`shops`"
		export MENU="`Menu ./shops.cgi?`"
		cat $ROOT/templates/shops.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

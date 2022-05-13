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

Shops() {
	while read line; do Shop $line; done
}

case "$REQUEST_METHOD" in
	GET)
		export _TITLE="`_ Shops`"

		export SHOPS="`ls $ROOT/shops | Shops`"
		Normal 200 shops
		Cat shops
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

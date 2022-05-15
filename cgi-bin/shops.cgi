#!/bin/ksh

. $ROOT/lib/common.sh

Shop() {
	SHOPNAME="$1"
	_TITLE="`_ $SHOPNAME`"
	cat <<EOF
<a class="txl" href="/cgi-bin/shop.cgi?shop_id=$SHOPNAME">
	$_TITLE
</a>
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

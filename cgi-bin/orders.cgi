#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh

Order() {
	ORDER_PATH=$SHOP_PATH/.orders/$1
	ORDER_OWNER="`cat $ORDER_PATH/owner`"
	TOTAL_EXP="`process_cart $ORDER_PATH/raw`"
	TOTAL="`echo "$TOTAL_EXP" | bc -l`"
	ORDER_STATE_TEXT="`cat $ORDER_PATH/state`"
	_ORDER_STATE="`_ "$ORDER_STATE_TEXT"`"
	ORDER_STATE_COLOR="`order_state_color "$ORDER_STATE_TEXT"`"

	cat <<!
<a href="/cgi-bin/order.cgi?lang=$lang&shop_id=$shop_id&order_id=$1" class="b0 p _ f fic">
	<span class="txl fg">
		$_ORDER #$1 - $ORDER_OWNER $TOTAL€
	</span>

	<span class="dib ps cf0 c$ORDER_STATE_COLOR">
		$_ORDER_STATE
	</span>
</a>
!
}

VendorOrders() {
	ls $SHOP_PATH/.orders | while read line; do
		Order $line
	done
}

UserOrders() {
	ls $SHOP_PATH/.orders | while read line; do
		ORDER_PATH=$SHOP_PATH/.orders/$line
		ORDER_OWNER="`cat $ORDER_PATH/owner`"
		[[ "$ORDER_OWNER" == "$REMOTE_USER" ]] && Order $line
	done
}

case "$REQUEST_METHOD" in
	GET)
		if [[ -z "$shop_id" ]]; then
			echo 'Status: 400 Bad Request'
			echo
			exit 1
		fi

		SHOP_OWNER="`cat $SHOP_PATH/.owner`"

		ORDERS_PATH=$SHOP_PATH/.orders

		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export _TITLE="`_ $shop_id` - `_ Orders`"

		_ORDER="`_ Order`"

		if [[ "$REMOTE_USER" == "$SHOP_OWNER" ]]; then
			ORDERS="`VendorOrders`"
		else
			ORDERS="`UserOrders`"
		fi

		export ORDERS
		export MENU="`Menu ./orders.cgi?shop_id=$shop_id\&`"
		cat $ROOT/templates/orders.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac




#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh
. $ROOT/lib/order.sh

Order() {
	ORDER_PATH=$SHOP_PATH/.orders/$1
	ORDER_OWNER="`cat $ORDER_PATH/owner`"
	TOTAL_EXP="`process_cart $ORDER_PATH/raw`"
	TOTAL="`echo "$TOTAL_EXP" | bc -l`"
	ORDER_STATE_TEXT="`cat $ORDER_PATH/state`"
	ORDER_STATE="`OrderState -rorders "$ORDER_STATE_TEXT" $1`"

	cat <<!
<a href="/cgi-bin/order.cgi?shop_id=$shop_id&order_id=$1" class="b0 p v">
	<span>
		$_ORDER #$1 - $ORDER_OWNER $TOTAL€
	</span>

	$ORDER_STATE
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

if [[ -z "$shop_id" ]] || [[ ! -d "$SHOP_PATH" ]]; then
	Fatal 404 Shop not found
fi

case "$REQUEST_METHOD" in
	GET)
		SHOP_OWNER="`cat $SHOP_PATH/.owner`"

		ORDERS_PATH=$SHOP_PATH/.orders

		export _TITLE="`_ $shop_id` - `_ Orders`"

		_ORDER="`_ Order`"

		if [[ "$REMOTE_USER" == "$SHOP_OWNER" ]]; then
			ORDERS="`VendorOrders`"
		else
			ORDERS="`UserOrders`"
		fi

		if [[ ! -z "$ORDERS" ]]; then
			ORDERS="<div class=\"_ f fw v fcc fic\">$ORDERS</div>"
		fi

		export ORDERS
		NormalCat ?shop_id=$shop_id
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac




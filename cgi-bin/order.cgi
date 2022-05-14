#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh
. $ROOT/lib/order.sh

TransferData() {
	SHOP_OWNER="`cat $SHOP_PATH/.owner`"
	echo "<pre class=\"oa\">"
	cat $ROOT/users/$SHOP_OWNER/.transfer_data
	echo "</pre>"
}

if [[ -z "$shop_id" ]] || [[ ! -d "$SHOP_PATH" ]]; then
	Fatal 404 Shop not found
fi

case "$REQUEST_METHOD" in
	POST)
		if [[ -z "$order_id" ]]; then
			if [[ ! -f "$CART_PATH" ]] \
				|| [[ -z "`cat $CART_PATH`" ]]; then
				Fatal 404 Cart not found
			fi

			SHOP_OWNER="`cat $SHOP_PATH/.owner`"
			ORDERS_PATH=$SHOP_PATH/.orders
			ORDER_ID_PATH=$SHOP_PATH/.orders/.count
			ORDER_ID="`counter_inc $ORDER_ID_PATH`"
			ORDER_PATH=$SHOP_PATH/.orders/$ORDER_ID
			USER=$SHOP_OWNER

			fmkdir $ORDERS_PATH
			fmkdir $ORDER_PATH
			fwrite $ORDER_PATH/raw cat $CART_PATH
			fwrite $ORDER_PATH/owner echo $REMOTE_USER
			fwrite $ORDER_PATH/state echo Pending_payment

			cat $ORDER_PATH/raw | while read product_id quantity; do
				counter_dec $SHOP_PATH/$product_id/stock $quantity
			done

			rm $CART_PATH # TODO also remove unneeded directories?

			see_other order \&shop_id=$shop_id\&order_id=$ORDER_ID
		else
			ORDER_PATH=$SHOP_PATH/.orders/$order_id
			SHOP_OWNER="`cat $SHOP_PATH/.owner`"

			if [[ "$SHOP_OWNER" != "$REMOTE_USER" ]]; then
				Fatal 401 "You can not do that"
			fi

			ORDER_STATE_TEXT="`cat $ORDER_PATH/state`"
			case "$ORDER_STATE_TEXT" in
				Pending_payment)
					ORDER_STATE_TEXT=Pending_shipment
					;;
				Pending_shipment)
					ORDER_STATE_TEXT=Shipped
					;;
				Shipped)
					ORDER_STATE_TEXT=Delivered
					;;
				Delivered)
					rm -rf $ORDER_PATH
					see_other orders \&shop_id=$shop_id
					exit
					;;
			esac

			USER=$SHOP_OWNER
			fwrite $ORDER_PATH/state echo $ORDER_STATE_TEXT

			case "$return" in
				order)
					see_other order \&shop_id=$shop_id\&order_id=$order_id
					;;
				orders)
					see_other orders \&shop_id=$shop_id
					;;
			esac
		fi

		;;

	GET)
		ORDER_PATH=$SHOP_PATH/.orders/$order_id
		if [[ -z "$order_id" ]] || [[ ! -d "$ORDER_PATH" ]]; then
			Fatal 404 Order not found
		fi

		SHOP_OWNER="`cat $SHOP_PATH/.owner`"
		ORDER_OWNER="`cat $ORDER_PATH/owner`"

		if [[ "$REMOTE_USER" != "$ORDER_OWNER" ]] \
			&& [[ "$REMOTE_USER" != "$SHOP_OWNER" ]]; then

			Fatal 401 "You can not do that"
		fi

		export order_id

		export _TITLE="`_ $shop_id` - `_ Order` #$order_id"

		TOTAL_EXP="`process_cart $ORDER_PATH/raw`"
		export TOTAL="`echo "$TOTAL_EXP" | bc -l`"
		export PRODUCTS="`ProductsFromCart  $ORDER_PATH/raw`"
		ORDER_STATE_TEXT="`cat $ORDER_PATH/state`"
		export ORDER_STATE="`OrderState -rorder "$ORDER_STATE_TEXT" $order_id`"
		if [[ "$REMOTE_USER" != "$SHOP_OWNER" ]]; then
			case "$ORDER_STATE_TEXT" in
				Pending_payment)
					TRANSFER_DATA=`TransferData`
					export TRANSFER_DATA
					;;
			esac
		fi
		Normal 200 order shop_id=$shop_id\&
		Cat order
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac



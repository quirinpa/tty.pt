#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh
. $ROOT/lib/order.sh

case "$REQUEST_METHOD" in
	POST)
		if [[ -z "$order_id" ]]; then
			if [[ -z "$shop_id" ]] || [[ ! -f "$CART_PATH" ]]; then
				echo 'Status: 400 Bad Request'
				echo
				exit 1
			fi

			ORDERS_PATH=$SHOP_PATH/.orders
			[[ -d "$ORDERS_PATH" ]] || mkdir -p -m 770 $ORDERS_PATH

			ORDER_ID_PATH=$SHOP_PATH/.orders/.count
			ORDER_ID="`counter_inc $ORDER_ID_PATH`"

			ORDER_PATH=$SHOP_PATH/.orders/$ORDER_ID
			mkdir -p $ORDER_PATH

			cat $CART_PATH > $ORDER_PATH/raw
			echo $REMOTE_USER > $ORDER_PATH/owner
			echo Pending_payment > $ORDER_PATH/state

			rm $CART_PATH # TODO also remove unneeded directories?

			echo 'Status: 303 See Other'
			echo "Location: /cgi-bin/order.cgi?lang=${lang}&shop_id=${shop_id}&order_id=${ORDER_ID}"
			echo
		else
			if [[ -z "$shop_id" ]]; then
				echo 'Status: 400 Bad Request'
				echo
				exit 1
			fi

			ORDER_PATH=$SHOP_PATH/.orders/$order_id
			SHOP_OWNER="`cat $SHOP_PATH/.owner`"

			if [[ "$SHOP_OWNER" != "$REMOTE_USER" ]]; then
				echo 'Status: 401 Unauthorized'
				echo
				exit 1
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
			esac

			echo $ORDER_STATE_TEXT > $ORDER_PATH/state

			echo 'Status: 303 See Other'
			case "$return" in
				order)
					echo "Location: /cgi-bin/order.cgi?lang=${lang}&shop_id=${shop_id}&order_id=${order_id}"
					;;
				orders)
					echo "Location: /cgi-bin/orders.cgi?lang=${lang}&shop_id=${shop_id}"
					;;
			esac
			echo
		fi

		;;

	GET)
		if [[ -z "$shop_id" ]] || [[ -z "$order_id" ]]; then
			echo 'Status: 400 Bad Request'
			echo
			exit 1
		fi

		ORDER_PATH=$SHOP_PATH/.orders/$order_id
		SHOP_OWNER="`cat $SHOP_PATH/.owner`"
		ORDER_OWNER="`cat $ORDER_PATH/owner`"

		if [[ "$REMOTE_USER" != "$ORDER_OWNER" ]] \
			&& [[ "$REMOTE_USER" != "$SHOP_OWNER" ]]; then

			echo 'Status: 401 Unauthorized'
			echo
			echo 'Unauthorized'
			exit 1
		fi

		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export order_id

		export _TITLE="`_ $shop_id` - `_ Order` #$order_id"

		TOTAL_EXP="`process_cart $ORDER_PATH/raw`"
		export TOTAL="`echo "$TOTAL_EXP" | bc -l`"
		export PRODUCTS="`ProductsFromCart  $ORDER_PATH/raw`"
		export MENU="`Menu ./order.cgi?shop_id=$shop_id\&`"
		ORDER_STATE_TEXT="`cat $ORDER_PATH/state`"
		export ORDER_STATE="`OrderState -rorder "$ORDER_STATE_TEXT" $order_id`"
		cat $ROOT/templates/order.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac



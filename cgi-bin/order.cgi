#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh

case "$REQUEST_METHOD" in
	POST)
		if [[ -z "$shop_id" ]] || [[ ! -f "$CART_PATH" ]]; then
			echo 'Status: 400 Bad Request'
			echo
			exit 1
		fi

		ORDERS_PATH=$SHOP_PATH/.orders
		[[ -d "$ORDERS_PATH" ]] || mkdir -p -m 770 $ORDERS_PATH

		ORDER_ID_PATH=$SHOP_PATH/.orders/.count
		ORDER_ID="`counter_inc $ORDER_ID_PATH`"
		echo $ORDER_ID > $ORDER_ID_PATH

		ORDER_PATH=$SHOP_PATH/.orders/$ORDER_ID
		mkdir -p $ORDER_PATH

		cat $CART_PATH > $ORDER_PATH/raw
		echo $REMOTE_USER > $ORDER_PATH/owner
		echo Pending payment > $ORDER_PATH/state

		rm $CART_PATH # TODO also remove unneeded directories?

		echo 'Status: 303 See Other'
		echo "Location: /cgi-bin/order.cgi?lang=${lang}&shop_id=${shop_id}&order_id=${ORDER_ID}"
		echo
		;;

	GET)
		if [[ -z "$shop_id" ]] || [[ -z "$order_id" ]]; then
			echo 'Status: 400 Bad Request'
			echo
			exit 1
		fi

		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export order_id

		ORDER_PATH=$SHOP_PATH/.orders/$order_id

		export _TITLE="`_ $shop_id` - `_ Order` #$order_id"
		ORDER_STATE="`cat $ORDER_PATH/state`"
		export _ORDER_STATE="`_ "$ORDER_STATE"`"

		case "$ORDER_STATE" in
			Pending\ payment)
				ORDER_STATE_COLOR=11
				;;
			Pending\ shipping)
				ORDER_STATE_COLOR=9
				;;
			Shipped)
				ORDER_STATE_COLOR=10
				;;
			#Delivered)
				#ORDER_STATE_COLOR=9
				#;;
		esac

		export ORDER_STATE_COLOR

		# ignore the possible error

		TOTAL_EXP="`process_cart $ORDER_PATH/raw`"
		export TOTAL="`echo "$TOTAL_EXP" | bc -l`"
		export PRODUCTS="`ProductsFromCart  $ORDER_PATH/raw`"
		export MENU="`Menu ./order.cgi?shop_id=$shop_id\&`"
		cat $ROOT/templates/order.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac



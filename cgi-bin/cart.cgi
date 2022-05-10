#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh

Products() {
	while read product_id quantity; do
		[[ "$product_id" == "0" ]] && exit
		Product $product_id
	done
}

process_cart() {
	while read product_id quantity; do
		PRODUCT_PATH="`get_product_path $product_id`"
		PRODUCT_PRICE="`cat $PRODUCT_PATH/price`"
		echo $quantity \* $PRODUCT_PRICE
	done | sumlines
}

case "$REQUEST_METHOD" in
	POST)
		if [[ -z "$shop_id" ]]; then
			echo 'Status: 400 Bad Request'
			echo
			exit 1
		fi

		case "$action" in
			checkout)
				USER_SHOP_PATH=$ROOT/users/$REMOTE_USER/shops/$shop_id
				CART_PATH=$USER_SHOP_PATH/cart
				export TOTAL="`cat $CART_PATH | process_cart`"
				echo 'Status: 200 OK'
				echo
				CART_ID_PATH=$ROOT/shops/$shop_id/.carts
				CARD_ID="`counter_inc $CART_ID_PATH`"
				echo $CARD_ID > $CART_ID_PATH
				echo TOTAL+$TOTAL
				echo CART_ID=$CARD_ID
				;;
			*)
				if [[ $quantity -lt 0 ]]; then
					echo 'Status: 400 Bad Request'
					echo
					exit 1
				fi

				USER_SHOP_PATH=$ROOT/users/$REMOTE_USER/shops/$shop_id
				[[ -d "$USER_SHOP_PATH" ]] || mkdir -m 770 -p $USER_SHOP_PATH

				CART_PATH=$USER_SHOP_PATH/cart

				if [[ "$quantity" == "0" ]]; then
					sed -n "/^$product_id /,/^[^+]/{x;/^$/!p;}" $CART_PATH > $CART_PATH
				else
					echo $product_id $quantity >> $CART_PATH
					cat $CART_PATH | awk \
						'{a[$1]=$2} END{for (i in a) print i FS a[i]}' \
						> $CART_PATH
				fi

				echo 'Status: 303 See Other'
				if [[ -z "$return" ]]; then
					echo "Location: /cgi-bin/cart.cgi?lang=${lang}&shop_id=${shop_id}"
				else
					echo "Location: /cgi-bin/shop.cgi?lang=${lang}&shop_id=${shop_id}"
				fi
				echo
				;;
		esac
		;;

	GET)
		if [[ -z "$shop_id" ]]; then
			echo 'Status: 400 Bad Request'
			echo
			exit 1
		fi

		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export shop_id

		export _TITLE="`_ $shop_id` - `_ Cart`"

		# ignore the possible error
		USER_SHOP_PATH=$ROOT/users/$REMOTE_USER/shops/$shop_id
		CART_PATH=$USER_SHOP_PATH/cart
		export _SUBMIT="`_ Submit`"

		export TOTAL="`cat $CART_PATH | process_cart`"
		export PRODUCTS="`cat $CART_PATH | Products`"
		export MENU="`Menu ./cart.cgi?shop_id=$shop_id\&`"
		cat $ROOT/templates/cart.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


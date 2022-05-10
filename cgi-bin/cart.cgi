#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh

case "$REQUEST_METHOD" in
	POST)
		if [[ -z "$shop_id" ]] || [[ $quantity -lt 0 ]]; then
			echo 'Status: 400 Bad Request'
			echo
			exit 1
		fi

		[[ -d "$USER_SHOP_PATH" ]] || mkdir -m 770 -p $USER_SHOP_PATH

		if [[ "$quantity" == "0" ]]; then
			sed -n "/^$product_id /,/^[^+]/{x;/^$/!p;}" $CART_PATH > $CART_PATH
		else
			echo $product_id $quantity >> $CART_PATH
			cat $CART_PATH | awk \
				'{a[$1]=$2} END{for (i in a) print i FS a[i]}' \
				> $CART_PATH
		fi

		echo 'Status: 303 See Other'
		case "$return" in
			cart)
				echo "Location: /cgi-bin/cart.cgi?lang=${lang}&shop_id=${shop_id}"
				;;
			shop)
				echo "Location: /cgi-bin/shop.cgi?lang=${lang}&shop_id=${shop_id}"
				;;
		esac

		echo
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

		TOTAL_CART_EXP="`process_cart $CART_PATH`"

		export shop_id

		export _TITLE="`_ $shop_id` - `_ Cart`"

		# ignore the possible error
		export _SUBMIT="`_ Submit`"

		export TOTAL="`echo "$TOTAL_CART_EXP" | bc -l`"
		export PRODUCTS="`ProductsFromCart $CART_PATH`"
		export MENU="`Menu ./cart.cgi?shop_id=$shop_id\&`"
		cat $ROOT/templates/cart.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


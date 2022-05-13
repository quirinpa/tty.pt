#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh

EmptyContents() {
	_EMPTY="`_ "Empty"`"
	echo "<div class=\"txl tac\">$_EMPTY</div>"
}

Contents() {
	TOTAL_CART_EXP="`process_cart $CART_PATH`"
	TOTAL="`echo "$TOTAL_CART_EXP" | bc -l`"
	_SUBMIT="`_ Submit`"
	PRODUCTS="`ProductsFromCart -rcart $CART_PATH`"

	cat <<!
<div class="v">
	$PRODUCTS
</div>
<div class="tcv fic v">
	<h2>$TOTAL€</h2>
	<form action="/cgi-bin/order.cgi" method="POST">
		<input type="hidden" name="lang" value="$lang"></input>
		<input type="hidden" name="shop_id" value="$shop_id"></input>
		<button>$_SUBMIT</Button>
	</form>
</div>
!
}

case "$REQUEST_METHOD" in
	POST)
		if [[ -z "$shop_id" ]] || [[ $quantity -lt 0 ]]; then
			fatal 400
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

		case "$return" in
			cart)
				see_other cart \&shop_id=${shop_id}
				;;
			shop)
				see_other shop \&shop_id=${shop_id}
				;;
		esac

		;;

	GET)
		if [[ -z "$shop_id" ]]; then
			fatal 400
		fi

		if [[ -f "$CART_PATH" ]]; then
			CONTENTS="`Contents`"
		else
			CONTENTS="`EmptyContents`"
		fi
		export CONTENTS

		export _TITLE="`_ $shop_id` - `_ Cart`"

		# ignore the possible error

		page 200 cart shop_id=$shop_id\&
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


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

if [[ -z "$shop_id" ]] || [[ -d $SHOP_PATH ]]; then
	Fatal 404 Shop not found
fi

case "$REQUEST_METHOD" in
	POST)
		if [[ $quantity -lt 0 ]]; then
			Fatal 400 Invalid quantity
		fi

		SHOP_OWNER="`cat $SHOP_PATH/owner`"
		USER=$SHOP_OWNER
		fmkdir $USER_SHOP_PATH
		OLD_QUANTITY="`cat $CART_PATH | grep $product_id | awk '{ print $2 }'`"
		AVAILABLE_EXP="$STOCK - ($quantity - $OLD_QUANTITY) > 0"
		AVAILABLE="`echo $AVAILABLE_EXP | bc`"

		[[ "$AVAILABLE" == "0" ]] && Fatal 400 No available space

		if [[ "$quantity" == "0" ]]; then
			sed -n "/^$product_id /,/^[^+]/{x;/^$/!p;}" $CART_PATH > $CART_PATH
		else
			fwrite $CART_PATH echo $product_id $quantity
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
		if [[ -f "$CART_PATH" ]] && [[ ! -z `cat $CART_PATH` ]]; then
			CONTENTS="`Contents`"
		else
			CONTENTS="`EmptyContents`"
		fi
		export CONTENTS

		export _TITLE="`_ $shop_id` - `_ Cart`"

		Normal 200 cart
		Cat cart
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

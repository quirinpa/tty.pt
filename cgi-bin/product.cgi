#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh
. $ROOT/lib/order.sh

if [[ -z "$shop_id" ]] || [[ ! -d "$SHOP_PATH" ]]; then
	Fatal 404 Shop not found
fi

PRODUCT_PATH=$SHOP_PATH/$product_id
if [[ -z "$product_id" ]] || [[ ! -d "$PRODUCT_PATH" ]]; then
	Fatal 404 Product not found
fi

case "$REQUEST_METHOD" in
	GET)

		export _TITLE="`_ $shop_id` - `_ Product` #$product_id"

		export PRODUCT="`Product -rproduct $CART_PATH $product_id`"
		NormalCat ?shop_id=$shop_id\&product_id=$product_id
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac




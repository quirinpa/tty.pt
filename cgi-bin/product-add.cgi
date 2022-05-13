#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh

case "$REQUEST_METHOD" in
	POST)
		if [[ -z "$shop_id" ]]; then
			fatal 400
		fi

		SHOP_OWNER="`cat $SHOP_PATH/.owner`"

		if [[ "$REMOTE_USER" != "$SHOP_OWNER" ]]; then
			fatal 400
		fi

		PRODUCT_ID_PATH=$SHOP_PATH/.count
		PRODUCT_ID="`counter_inc $PRODUCT_ID_PATH`"
		PRODUCT_PATH=$SHOP_PATH/$PRODUCT_ID

		mkdir $PRODUCT_PATH
		urldecode $title > $PRODUCT_PATH/title
		urldecode $description > $PRODUCT_PATH/description
		urldecode $image > $PRODUCT_PATH/image
		echo $price > $PRODUCT_PATH/price
		echo $stock > $PRODUCT_PATH/stock

		see_other shop \&shop_id=$shop_id
		;;

	GET)
		if [[ -z "$shop_id" ]]; then
			fatal 400
		fi

		export _TITLE="`_ $shop_id` - `_ "Add product"`"
		export __TITLE="`_ Title`"
		export _DESCRIPTION="`_ Description`"
		export _IMAGE="`_ Image`"
		export _STOCK="`_ Stock`"
		export _PRICE="`_ Price`"
		export _SUBMIT="`_ Submit`"

		page 200 product-add shop_id=$shop_id\&
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh

if [[ -z "$shop_id" ]] || [[ ! -d "$SHOP_PATH" ]]; then
	fatal 404 Shop not found
fi

case "$REQUEST_METHOD" in
	POST)
		SHOP_OWNER="`cat $SHOP_PATH/.owner`"

		if [[ "$REMOTE_USER" != "$SHOP_OWNER" ]]; then
			Fatal 401 "You cannot do that"
		fi

		PRODUCT_ID_PATH=$SHOP_PATH/.count
		PRODUCT_ID="`counter_inc $PRODUCT_ID_PATH`"
		PRODUCT_PATH=$SHOP_PATH/$PRODUCT_ID
		USER=$SHOP_OWNER

		fmkdir $PRODUCT_PATH
		fwrite $PRODUCT_PATH/title urldecode $title
		fwrite $PRODUCT_PATH/description urldecode $description
		fwrite $PRODUCT_PATH/images urldecode $images
		fwrite $PRODUCT_PATH/price echo $price
		fwrite $PRODUCT_PATH/stock echo $stock

		see_other shop \&shop_id=$shop_id
		;;

	GET)
		export _TITLE="`_ $shop_id` - `_ "Add product"`"
		export __TITLE="`_ Title`"
		export _DESCRIPTION="`_ Description`"
		export _IMAGES="`_ Images`"
		export _STOCK="`_ Stock`"
		export _PRICE="`_ Price`"
		export _SUBMIT="`_ Submit`"

		Normal 200 product-add shop_id=$shop_id\&
		Cat product-add
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

#!/bin/ksh

. $ROOT/lib/common.sh
. $ROOT/lib/shop.sh

lsshown() {
	 find $1 -type d -mindepth 1 -maxdepth 1 -name "[!.]*" | sed "s|$1||"
}

Category() {
	CATEGORY_ID="$1"
	CATEGORY_NAME="`_ $CATEGORY_ID`"
	cat <<!
<option value="$CATEGORY_ID">$CATEGORY_NAME</option>
!
}

Products() {
	while read line; do
		if [[ "`cat $SHOP_PATH/$line/stock`" -gt 0 ]]; then
			Product -rshop $CART_PATH $line;
		fi
	done
}

case "$REQUEST_METHOD" in
	POST)
		[[ -z "$shop_id" ]] && fatal 400

		case "$action" in
			delete)
				[[ -z "$product_id" ]] && fatal 400

				SHOP_OWNER="`cat $SHOP_PATH/.owner`"

				[[ "$SHOP_OWNER" != "$REMOTE_USER" ]] && fatal 401

				rm -rf $SHOP_PATH/$product_id

				see_other shop \&shop_id=$shop_id
				;;
			*)
				fatal 400
				;;
		esac

		;;
	GET)
		[[ -z "$shop_id" ]] && fatal 400

		export _TITLE="`_ $shop_id`"

		export SHOP_CATEGORIES="`lsshown $SHOP_PATH/.categories/ | while read line; do Category $line; done`"
		export PRODUCTS="`lsshown $SHOP_PATH/ | Products`"
		SHOP_OWNER="`cat $SHOP_PATH/.owner`"
		if [[ "$REMOTE_USER" == "$SHOP_OWNER" ]]; then
			ADD_PRODUCT_BUTTON="<div class=\"tar\"><a class=\"txl round c0 ps tdn ch00\" href=\"/cgi-bin/product-add.cgi?lang=$lang&shop_id=$shop_id\">+</a></div>"
		fi
		export ADD_PRODUCT_BUTTON

		Normal 200 shop shop_id=$shop_id\&
		Cat shop
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

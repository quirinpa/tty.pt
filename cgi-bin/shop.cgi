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

case "$REQUEST_METHOD" in
	POST)
		if [[ -z "$shop_id" ]]; then
			echo 'Status: 400 Bad Request'
			echo
			exit
		fi

		case "$action" in
			delete)
				if [[ -z "$product_id" ]]; then
					echo 'Status: 400 Bad Request'
					echo
					exit
				fi

				SHOP_OWNER="`cat $SHOP_PATH/.owner`"

				if [[ "$SHOP_OWNER" != "$REMOTE_USER" ]]; then
					echo 'Status: 401 Unauthorized'
					echo
					exit 1
				fi

				rm -rf $SHOP_PATH/$product_id

				echo 'Status: 303 See Other'
				echo "Location: /cgi-bin/shop.cgi?lang=$lang&shop_id=$shop_id"
				echo

				;;
			*)
				echo 'Status 400 Bad Request'
				echo
				exit
				;;
		esac

		;;
	GET)
		if [[ -z "$shop_id" ]]; then
			echo 'Status: 400 Bad Request'
			echo
			exit
		fi

		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export _TITLE="`_ $shop_id`"

		export SHOP_CATEGORIES="`lsshown $SHOP_PATH/.categories/ | while read line; do Category $line; done`"
		export PRODUCTS="`lsshown $SHOP_PATH/ | while read line; do Product -rshop $CART_PATH $line; done`"
		SHOP_OWNER="`cat $SHOP_PATH/.owner`"
		if [[ "$REMOTE_USER" == "$SHOP_OWNER" ]]; then
			ADD_PRODUCT_BUTTON="<div class=\"tar\"><a class=\"txl round c0 ps tdn ch00\" href=\"/cgi-bin/product-add.cgi?lang=$lang&shop_id=$shop_id\">+</a></div>"
		fi
		export ADD_PRODUCT_BUTTON
		export MENU="`Menu ./shop.cgi?shop_id=$shop_id\&`"
		cat $ROOT/templates/shop.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

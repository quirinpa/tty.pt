#!/bin/ksh

. $ROOT/lib/common.sh

not_valid_id() {
	valid="`echo $@ | tr -cd '[a-zA-Z0-9]_'`"
	[[ "$valid" != "$@" ]]
}

case "$REQUEST_METHOD" in
	POST)
		shop_id="`urldecode $shop_id`"

		if not_valid_id $shop_id; then
			Fatal 400 Not a valid ID
		fi

		SHOP_PATH="$ROOT/shops/`urldecode $shop_id`"

		fmkdir $SHOP_PATH
		fwrite $SHOP_PATH/.owner echo $REMOTE_USER
		fmkdir $SHOP_PATH/.orders

		see_other shop ?shop_id=$shop_id
		;;

	GET)
		export _TITLE="`_ "Add shop"`"
		export _SHOP_ID="`_ "Shop ID"`"
		export _SUBMIT="`_ Submit`"

		NormalCat
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


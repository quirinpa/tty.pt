#!/bin/ksh

. $ROOT/lib/common.sh

USER_PATH=$ROOT/users/$REMOTE_USER

case "$REQUEST_METHOD" in
	POST)
		{
			echo $address_line_1
			echo $address_line_2
			echo $zip
		} > $USER_PATH/address

		see_other user
		;;
	GET)
		export _TITLE="`_ User` - $REMOTE_USER"
		export _WELCOME="`_ Welcome`"
		export LOGINLOGOUT="`LoginLogout`"
		export _ADDRESS_LINE_1="`_ "Address line 1"`"
		export _ADDRESS_LINE_2="`_ "Address line 2"`"
		export _ZIP_CODE="`_ "Zip code"`"
		export _SUBMIT="`_ Submit`"
		export _CHANGE_SHIPPING_ADDRESS="`_ change_shipping_address`"

		cat $USER_PATH/address | {
			read address_line_1
			read address_line_2
			read zip

			address_line_1="`urldecode $address_line_1`"
			address_line_2="`urldecode $address_line_2`"
			zip="`urldecode $zip`"

			export address_line_1
			export address_line_2
			export zip

			Normal 200 user
			Cat user
		}
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac



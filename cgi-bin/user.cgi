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

		echo 'Status: 303 See Other'
		echo "Location: /cgi-bin/user.cgi?lang=${lang}"
		echo
		;;
	GET)
		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export _TITLE="`_ User` - $REMOTE_USER"
		export _WELCOME="`_ Welcome`"
		export LOGINLOGOUT="`LoginLogout`"
		export _ADDRESS_LINE_1="`_ "Address line 1"`"
		export _ADDRESS_LINE_2="`_ "Address line 2"`"
		export _ZIP_CODE="`_ "Zip code"`"
		export _SUBMIT="`_ Submit`"
		export _CHANGE_SHIPPING_ADDRESS="`_ change_shipping_address`"

		export MENU="`Menu ./user.cgi?`"

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

			cat $ROOT/templates/user.html | envsubst
		}
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac



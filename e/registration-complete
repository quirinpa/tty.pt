#!/bin/ksh

. $ROOT/lib/common.sh

case "$REQUEST_METHOD" in
	GET)
		export _REGISTRATION_COMPLETE="`_ "Registration complete"`"
		export _ACCOUNT_CREATED="`_ "Please click the link sent to your e-mail to activate your account."`"
		NormalCat
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


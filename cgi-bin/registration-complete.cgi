#!/bin/ksh

. $ROOT/lib/common.sh

case "$REQUEST_METHOD" in
	GET)
		export _REGISTRATION_COMPLETE="`_ "Registration complete"`"
		export _ACCOUNT_CREATED="`_ "Please click the link sent to your e-mail to activate your account."`"

		Normal 200 registration-complete
		Cat registration-complete
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


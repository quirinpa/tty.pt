#!/bin/ksh

. $ROOT/lib/common.sh

case "$REQUEST_METHOD" in
	GET)
		USER_PATH=$ROOT/users/$username
		USER_RCODE="`cat $USER_PATH/rcode`"

		if [[ "$rcode" != "$USER_RCODE" ]]; then
			Fatal 401 "You can not do that"
		fi

		rm $USER_PATH/rcode
		see_other login
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


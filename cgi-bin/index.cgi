#!/bin/ksh

. $ROOT/lib/common.sh

case "$REQUEST_METHOD" in
	GET)
		export LOGINLOGOUT="`LoginLogout`"
		export _POEM="`_ "Programmer's poem"`"
		export _NEVERDARK="`_ "Never Dark"`"
		export _SHOPS="`_ "Shops"`"
		export _SEM="`_ "Shared Expenses Manager"`"
		export _TERMINAL="`_ "Terminal"`"
		Normal 200 index
		Cat index
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

#!/bin/ksh

. $ROOT/lib/common.sh

case "$REQUEST_METHOD" in
	GET)
		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export LOGINLOGOUT="`LoginLogout`"
		export _POEM="`_ "Programmer's poem"`"
		export _NEVERDARK="`_ "Never Dark"`"
		export _SHOPS="`_ "Shops"`"
		export _SEM="`_ "Shared Expenses Manager"`"
		export _TERMINAL="`_ "Terminal"`"

		export MENU="`Menu ./index.cgi?`"
		cat $ROOT/templates/index.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

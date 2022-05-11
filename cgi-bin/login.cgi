#!/bin/ksh

. $ROOT/lib/common.sh

error() {
	echo 'Status: 303 See Other'
	echo "Location: login.cgi?error=$1&lang=$lang"
	echo
}

case "$REQUEST_METHOD" in
	POST)
		if grep -q "^$username" $ROOT/.htpasswd; then
			echo 'Status: 303 See Other'
			echo "Location: https://$username:$password@tty.pt/cgi-bin/user.cgi"
			echo
		else
			error nouser
		fi
		;;
	GET)
		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export _TITLE="`_ Login`"
		export _ANONYMOUS_LOGIN="`_ Login` - `_ Anonymous`"
		export _REGISTER="`_ "Register"`"
		export _USERNAME="`_ "Username"`"
		export _PASSWORD="`_ "Password"`"
		export _SUBMIT="`_ "Submit"`"

		case "$error" in
			nouser)
				ERROR="`_ "No such user"`"
				;;
			*)
				;;
		esac

		export ERROR

		export MENU="`Menu ./login.cgi?`"
		cat $ROOT/templates/login.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

#!/bin/ksh

. $ROOT/lib/common.sh

error() {
	echo 'Status: 303 See Other'
	echo "Location: login.cgi?error=$1&lang=$lang"
	echo
	exit
}

case "$REQUEST_METHOD" in
	POST)
		grep -q "^$username" $ROOT/.htpasswd || error nouser
		echo 'Status: 303 See Other'
		echo "Location: https://$username:$password@tty.pt/cgi-bin/user.cgi"
		echo
		;;
	GET)
		export _TITLE="`_ Login`"
		export _ANONYMOUS_LOGIN="`_ Login` - `_ Anonymous`"
		export _REGISTER="`_ "Register"`"
		export _USERNAME="`_ "Username"`"
		export _PASSWORD="`_ "Password"`"
		export _SUBMIT="`_ "Submit"`"

		case "$error" in
			nouser) ERROR="`_ "No such user"`" ;;
		esac

		if [[ ! -z "$ERROR" ]]; then
			ERROR="<p class=\"c9\">$ERROR</p>"
		fi

		export ERROR

		Normal 200 login
		Cat login
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

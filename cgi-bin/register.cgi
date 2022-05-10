#!/bin/ksh

. $ROOT/lib/common.sh

error() {
	echo 'Status: 303 See Other'
	echo "Location: register.cgi?error=$1"
	echo
}

case "$REQUEST_METHOD" in
	POST)
		if [[ "$password" == "$password2" ]];  then
			if grep -q "^$username" $ROOT/.htpasswd; then
				error match
			else
				echo `urldecode $username`:`urldecode $password` | htpasswd -I $ROOT/.htpasswd
				echo 'Status: 303 See Other'
				echo "Location: https://$username:$password@tty.pt/cgi-bin/poem.cgi"
				echo
			fi
		else
			error nomatch
		fi
		;;
	GET)
		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export _REGISTER="`_ "Register"`"
		export _USERNAME="`_ "Username"`"
		export _PASSWORD="`_ "Password"`"
		export _REPEAT_PASSWORD="`_ "Repeat password"`"
		export _EMAIL="`_ "Email"`"
		export _SUBMIT="`_ "Submit"`"

		case "$error" in
			nomatch)
				ERROR="`_ "Passwords don't match"`"
				;;
			match)
				ERROR="`_ "User already exists"`"
				;;
			*)
				;;
		esac

		export ERROR

		export MENU="`Menu ./register.cgi?`"
		cat $ROOT/templates/register.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

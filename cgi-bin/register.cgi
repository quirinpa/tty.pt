#!/bin/ksh

. $ROOT/lib/common.sh

error() {
	see_other register ?error=$1
}

case "$REQUEST_METHOD" in
	POST)
		if [[ "$password" == "$password2" ]];  then
			if grep -q "^$username" $ROOT/.htpasswd; then
				error match
			else
				echo `urldecode $username`:`urldecode $password` | htpasswd -I $ROOT/.htpasswd
				see_other login
				echo
			fi
		else
			error nomatch
		fi
		;;
	GET)
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

		Normal 200 register
		Cat register
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

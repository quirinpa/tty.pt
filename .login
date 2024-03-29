#!/bin/ksh

case "$REQUEST_METHOD" in
	POST) ;;
	GET)
		export _TITLE="`_ Login`"
		export _REGISTER="`_ "Register"`"
		export _USERNAME="`_ "Username"`"
		export _PASSWORD="`_ "Password"`"
		export _SUBMIT="`_ "Submit"`"

		Normal 200 login
		Scat template/login
		exit
		;;
	*) NotAllowed ;;
esac

username="`urldecode $username`"
password="`urldecode $password`"

hash="`grep "^$username:" $ROOT/.htpasswd | awk 'BEGIN{FS=":"} {print $2}'`"
[[ -z "$REMOTE_USER" ]] || rm $ROOT/sessions/$cookie
[[ ! -z "$hash" ]] || Fatal 400 No such user

if crypt_checkpass "$password" "$hash"; then
	Unauthorized
fi

[[ ! -f $ROOT/users/$username/rcode ]] \
	|| Fatal 400 The account was not activated

TOKEN="`rand_str_1`"
#[[ -d $ROOT/sessions ]] || mkdir $ROOT/sessions
echo $username > $ROOT/sessions/$TOKEN
echo 'Status: 303 See Other'
echo "Set-Cookie: QSESSION=$TOKEN; SameSite=Lax"
echo "Location: user"
#echo "Location: http://$username:$password@$HTTP_HOST/e/user"
echo

#!/bin/sh

content() {
	cat <<!
<form action="login" method="POST" class="v f fic">
	<label>
		`_ Username`: <input required name="username"></input>
	</label>
	<label>
		`_ Password`: <input required type="password" name="password"></input>
	</label>

	<button>`_ Submit`</button>
</form>

<a class="btn" href="register">
	`_ Register`
</a>
!
}

_TITLE="`_ Login`"
SubIndex $@
MustPost

username="`urldecode $username`"
password="`urldecode $password`"

hash="`grep "^$username:" $ROOT/.htpasswd | awk 'BEGIN{FS=":"} {print $2}'`"
test -z "$REMOTE_USER" || rm $ROOT/sessions/$cookie
test ! -z "$hash" || Fatal 400 No such user

if crypt_checkpass "$password" "$hash"; then
	Unauthorized
fi

test ! -f $ROOT/users/$username/rcode \
	|| Fatal 400 The account was not activated

TOKEN="`rand_str_1`"
#test -d $ROOT/sessions || mkdir $ROOT/sessions
echo $username > $ROOT/sessions/$TOKEN
echo 'Status: 303 See Other'
echo "Set-Cookie: QSESSION=$TOKEN; SameSite=Lax"
echo "Location: /user"
#echo "Location: http://$username:$password@$HTTP_HOST/e/user"
echo

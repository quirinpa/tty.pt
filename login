#!/bin/sh

if test $REQUEST_METHOD = GET; then
	cat <<!
<form action="login" method="POST" class="v f fic">
	<input type="hidden" name="ret" value="$ret"></input>
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
	exit 0
fi

_TITLE="`_ Login`"

username="`urldecode $username`"
password="`urldecode $password`"

hash="`grep "^$username:" $DOCUMENT_ROOT/.htpasswd | awk 'BEGIN{FS=":"} {print $2}'`"
test -z "$REMOTE_USER" || rm $DOCUMENT_ROOT/sessions/$cookie
test ! -z "$hash" || Fatal 400 No such user

if ! htpasswd -v $DOCUMENT_ROOT/.htpasswd "$username" "$password"; then
	Unauthorized
fi

test ! -f $DOCUMENT_ROOT/users/$username/rcode \
	|| Fatal 400 The account was not activated

test ! -z "$ret" && ret="`urldecode $ret`" || ret=/user
TOKEN="`rand_str_1`"
#test -d $DOCUMENT_ROOT/sessions || mkdir $DOCUMENT_ROOT/sessions
echo $username > $DOCUMENT_ROOT/sessions/$TOKEN
Fin <<!
${STATUS_STR}303 See Other
Set-Cookie: QSESSION=$TOKEN; SameSite=Lax
Location: $ret

!

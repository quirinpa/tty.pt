#!/bin/sh

if test $REQUEST_METHOD = GET; then
	cat <<!
<form action="login" method="POST" class="v f fic">
	<input type="hidden" name="ret" value="$HTTP_PARAM_ret"></input>
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

username="`urldecode $HTTP_PARAM_username`"
password="`urldecode $HTTP_PARAM_password`"

hash="`grep "^$username:" $DOCUMENT_ROOT/etc/$shadow | awk 'BEGIN{FS=":"} {print $2}'`"
test -z "$REMOTE_USER" || \
	rm $DOCUMENT_ROOT/sessions/$cookie
test ! -z "$hash" \
	|| Fatal 400 No such user
htpasswd -v $DOCUMENT_ROOT/etc/$shadow "$username" "$password" \
	|| Unauthorized
test ! -f $DOCUMENT_ROOT/users/$username/rcode \
	|| Fatal 400 The account was not activated

test ! -z "$HTTP_PARAM_ret" \
	&& ret="`urldecode $HTTP_PARAM_ret`" || ret=/user
TOKEN="`rand_str_1`"
echo $username > $DOCUMENT_ROOT/sessions/$TOKEN
header "Set-Cookie: QSESSION=$TOKEN; SameSite=Lax"
SeeOther $ret

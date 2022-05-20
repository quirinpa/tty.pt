#!/bin/ksh

. $ROOT/lib/very-common.sh

if [[ ! -z "$cookie" ]] && [[ -f "$ROOT/sessionts/$cookie" ]]; then
	cookie="`echo $cookie | awk 'BEGIN { FS = "=" } { print $2 }'`"
	user="`cat $ROOT/sessions/$cookie`"
	REMOTE_USER=$user
else
	Unauthorized
fi

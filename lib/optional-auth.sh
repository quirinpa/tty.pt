#!/bin/ksh

. $ROOT/lib/very-common.sh

if [[ ! -z "$cookie" ]]; then
	cookie="`echo $cookie | awk 'BEGIN { FS = "=" } { print $2 }'`"
	user="`cat $ROOT/sessions/$cookie || true`"
	REMOTE_USER=$user
fi


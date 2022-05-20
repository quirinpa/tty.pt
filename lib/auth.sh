#!/bin/ksh

. $ROOT/lib/very-common.sh

if [[ -z "$cookie" ]] || [[ ! -f "$ROOT/sessions/$cookie" ]]; then
	Unauthorized
fi

user="`cat $ROOT/sessions/$cookie`"
REMOTE_USER=$user

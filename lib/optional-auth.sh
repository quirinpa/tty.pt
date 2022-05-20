#!/bin/ksh

. $ROOT/lib/very-common.sh

if [[ -f "$ROOT/sessions/$cookie" ]]; then
	user="`cat $ROOT/sessions/$cookie`"
	REMOTE_USER=$user
fi

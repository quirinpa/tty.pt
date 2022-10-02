#!/bin/ksh

. $DOCUMENT_ROOT/lib/very-common.sh

if [[ -z "$cookie" ]] || [[ ! -f "$DOCUMENT_ROOT/sessions/$cookie" ]]; then
	Unauthorized
fi

user="`cat $DOCUMENT_ROOT/sessions/$cookie`"
REMOTE_USER=$user

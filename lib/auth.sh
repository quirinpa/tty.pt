#!/bin/sh

. $DOCUMENT_ROOT/lib/very-common.sh

if test -z "$cookie" || test ! -f "$DOCUMENT_ROOT/sessions/$cookie"; then
	Unauthorized
fi

user="`cat $DOCUMENT_ROOT/sessions/$cookie`"
REMOTE_USER=$user

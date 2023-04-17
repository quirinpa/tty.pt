#!/bin/ksh

. $DOCUMENT_ROOT/lib/very-common.sh

if [[ -f "$DOCUMENT_ROOT/sessions/$cookie" ]]; then
	user="`cat $DOCUMENT_ROOT/sessions/$cookie`"
	REMOTE_USER=$user
fi

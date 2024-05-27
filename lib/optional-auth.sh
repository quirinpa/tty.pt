#!/bin/sh

. $DOCUMENT_ROOT/lib/very-common.sh

if test -f "$DOCUMENT_ROOT/sessions/$cookie"; then
	user="`cat $DOCUMENT_ROOT/sessions/$cookie`"
	REMOTE_USER=$user
elif ! test -z "$HTTP_AUTHORIZATION"; then
	AUTH="`echo $HTTP_AUTHORIZATION | awk '{print $2}' | openssl base64 -d | tr ':' ' '`"
	username="`echo $AUTH | awk '{print $1}'`"
	password="`echo $AUTH | awk '{print $2}'`"
	auth $username $password 2>&1
	REMOTE_USER=$username
fi

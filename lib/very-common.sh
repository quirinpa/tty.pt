#!/bin/sh

umask 002
set -e

test -z "$VERY_COMMON" || return 0
VERY_COMMON=y
RES_CONTENT_TYPE="text/html; charset=utf-8"
HEADERS=""

header() {
	HEADERS="$HEADERS$1\n"
}

debug() {
	echo Status: 500 Internal Error
	echo "Content-Type: text/plain; charset=utf-8"
	echo
	echo Sorry, I\'m currently debugging. Please wait.
}

zcat() {
	if test -f "$@"; then
		cat "$@"
		true
	else
		false
	fi
}

NormalHead() {
	case "$1" in
		200) STATUS_TEXT="OK";;
		400) STATUS_TEXT="Bad Request";;
		401) STATUS_TEXT="Unauthorized";;
		404) STATUS_TEXT="Not Found";;
		409) STATUS_TEXT="Conflict";;
	esac
	export STATUS_TEXT
	export STATUS_CODE=$1
	echo "Status: $1 $STATUS_TEXT"
	echo "Content-Type: $RES_CONTENT_TYPE"
	test -z "$HEADERS" || echo -n $HEADERS
}

Head() {
	cat<<!
<!DOCTYPE html>
<html>
	<head>
		<meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes">
		<link rel="stylesheet" href="/vim.css" />
		<title>$_TITLE</title>
	</head>
!
}

_Cat() {
	if test $# -lt 1; then
		htmlsh | envsubst
	elif test -f $1.html; then
		cat $1.html | htmlsh '. /lib/very-common.sh; ' | envsubst
	fi
	echo "</html>"
}

Cat() {
	_Cat template/$1
}

CCat() {
	_Cat $DOCUMENT_ROOT/components/$1
}

_Fatal() {
	local status_code=$1
	shift 1
	NormalHead $status_code
	echo
	export _TITLE="$status_code: `_ "$@"`"
	if test "$HTTP_ACCEPT" = "text/plain"; then
		echo $_TITLE
		return 1
		# exit 1
	fi
	export _TITLE
	Head
	export MENU="`Menu`"
	CCat fatal
}

Fin() {
	cat - > $DOCUMENT_ROOT/tmp/post
	kill -2 $REQ_PID
	exit 1
}

Fatal() {
	_Fatal $@ | Fin
}

get_lang() {
	echo $HTTP_ACCEPT_LANGUAGE | tr ',' '\n' | tr '-' '_' | tr ';' ' ' | \
		while read alang qlang; do \
			if grep "$alang" $DOCUMENT_ROOT/locale/langs; then
				break
			fi
		done
}

lang="`get_lang`"
export lang
export LANG=$lang
if test -z "$LANG"; then
	LANG=pt_PT
fi
ILANG=$LANG

_() {
	arg="$@"
	IFS='$'
	TEXTDOMAIN=site
	value="`cat $DOCUMENT_ROOT/locale/$TEXTDOMAIN-$lang.txt | sed -n "s|^$arg\|||p"`"
	test -z "$value" && echo $arg || echo $value
}

export RB="btn round p16 ts20"
export RBS="btn round p8 ts17"
export RBXS="btn round p4 tss"
export SRB="btn round ps tsl"

Menu() {
	local user_name
	local user_icon
	if test ! -z "$REMOTE_USER"; then
		user_name="<span class=\"ts\">$REMOTE_USER</span>"
		user_icon="<a class=\"tsxl f h fic btn p8\" href=\"/user\"><span role=\"img\" aria-label=\"user\">🔑 </span><span> $user_name</span></a>"
	else
		user_icon="<a class=\"$RB\" href=\"/login?ret=$DOCUMENT_URI\"><span role=\"img\" aria-label=\"login\">🔑 </span></a>"
	fi
	echo $user_icon
}

Unauthorized() {
	header "Date: `TZ=GMT date '+%a, %d %b %Y %T %Z'`"
	header "WWW-Authenticate: Basic realm='tty-pt'"
	Fatal 401 Unauthorized
}

cookie=$HTTP_COOKIE
cookie="`echo $cookie | tr ' ' '\n' | head -n 1`"
cookie="`echo $cookie | awk 'BEGIN { FS = "=" } { print $2 }'`"

rand_str_1() {
	# TODO maybe remove lowercase conversion
	xxd -l32 -ps $DOCUMENT_ROOT/dev/urandom | xxd -r -ps | openssl base64 \
		    | tr -d = | tr + - | tr / _ | tr '[A-Z]' '[a-z]'
}

auth() {
	username=$1
	password=$2
	hash="`grep "^$username:" $DOCUMENT_ROOT/.htpasswd | awk 'BEGIN{FS=":"} {print $2}'`"
	test ! -z "$hash" || Fatal 400 No such user
	if crypt_checkpass "$password" "$hash"; then
		Unauthorized
	fi
	test ! -f $DOCUMENT_ROOT/users/$username/rcode || Fatal 400 The account was not activated

	TOKEN="`rand_str_1`"
	#test -d $DOCUMENT_ROOT/sessions || mkdir $DOCUMENT_ROOT/sessions
	echo $username > $DOCUMENT_ROOT/sessions/$TOKEN
	header "Set-Cookie: QSESSION=$TOKEN; SameSite=Lax"
}

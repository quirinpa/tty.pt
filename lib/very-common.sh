#!/bin/ksh

umask 002
set -e

[[ -z "$VERY_COMMON" ]] || return 0
VERY_COMMON=y
RES_CONTENT_TYPE="text/html; charset=utf-8"

debug() {
	echo Status: 500 Internal Error
	echo "Content-Type: text/plain; charset=utf-8"
	echo
	echo Sorry, I\'m currently debugging. Please wait.
}

zcat() {
	[[ -f "$@" ]] && cat $@ || true
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
	[[ -z "$HEADERS" ]] || echo -n $HEADERS
}

Head() {
	cat<<!
<html>
	<head>
		<meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="/vim.css" />
		<title>$_TITLE</title>
	</head>
!
}

Scat() {
	cat $1.html | envsubst
	echo "</html>"
	exit
}

Cat() {
	if [[ $# -lt 1 ]]; then
		envsubst
	else
		cat $DOCUMENT_ROOT/templates/$1.html | envsubst
	fi
	echo "</html>"
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
if [[ -z "$LANG" ]]; then
	LANG=pt_PT
fi
ILANG=$LANG

_() {
	arg="$@"
	IFS='$'
	TEXTDOMAIN=site
	value="`cat $DOCUMENT_ROOT/locale/$TEXTDOMAIN-$lang.txt | sed -n "s|^$arg\|||p"`"
	[[ -z "$value" ]] && echo $arg || echo $value
}

export RB="btn round p8 ts64"
export RBS="btn round p8 ts17"
export RBXS="btn round p4 tss"
export SRB="btn round ps tsl"

Menu() {
	local user_name
	local user_icon
	if [[ ! -z "$REMOTE_USER" ]]; then
		user_name="<span class=\"ts\">$REMOTE_USER</span>"
		user_icon="<a class=\"tsxl f h fic btn p8\" href=\"/user\"><span role=\"img\" aria-label=\"user\">🔑 </span><span> $user_name</span></a>"
	else
		user_icon="<a class=\"$RB\" href=\"/login\"><span role=\"img\" aria-label=\"login\">🔑 </span></a>"
	fi
	echo $user_icon
}

Unauthorized() {
	NormalHead 401
	echo "Date: `TZ=GMT date '+%a, %d %b %Y %T %Z'`"
	echo WWW-Authenticate: Basic realm="tty-pt"
	export _TITLE="`_ Unauthorized`"
	echo
	Head
	export MENU="`Menu`"
	Cat fatal
	exit
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
	[[ ! -z "$hash" ]] || Fatal 400 No such user
	if crypt_checkpass "$password" "$hash"; then
		Unauthorized
	fi
	[[ ! -f $ROOT/users/$username/rcode ]] || Fatal 400 The account was not activated

	TOKEN="`rand_str_1`"
	#[[ -d $ROOT/sessions ]] || mkdir $ROOT/sessions
	echo $username > $DOCUMENT_ROOT/sessions/$TOKEN
	HEADERS=$HEADERS"Set-Cookie: QSESSION=$TOKEN; SameSite=Lax\n"
}

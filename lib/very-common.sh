#!/bin/sh

umask 002
set -e

test -z "$VERY_COMMON" || return 0
VERY_COMMON=y
RES_CONTENT_TYPE="text/html; charset=UTF-8"
HEADERS=""
STATUS_STR=""
STATUS_CODE=200
export LD_LIBRARY_PATH=/usr/local/lib
test "$SERVER_SOFTWARE" != "OpenBSD httpd" || \
	STATUS_STR="Status: "

public() {
	chmod g+w $1
	chgrp www $1
}

header() {
	echo "$@" >> $DOCUMENT_ROOT/tmp/headers
	public $DOCUMENT_ROOT/tmp/headers
}

debug() {
	echo "$STATUS_STR"500 Internal Error
	echo "Content-Type: text/plain; charset=UTF-8"
	echo
	echo Sorry, I\'m currently debugging. Please wait.
}

dcmd() {
	sh -c "$@" 2>/tmp/debug
	public $DOCUMENT_ROOT/tmp/debug
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
	local status_code=$1
	echo "$STATUS_STR$1 $STATUS_TEXT"
	echo "Content-Type: $RES_CONTENT_TYPE"
	test ! -f $DOCUMENT_ROOT/tmp/headers || \
		cat $DOCUMENT_ROOT/tmp/headers
}

Head() {
	cat<<!
<!DOCTYPE html>
<html lang="$htmllang">
	<head>
		<meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes">
		<link rel="stylesheet" href="/vim.css" />
		<link rel="preconnect" href="https://fonts.googleapis.com">
		<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
		<link href="https://fonts.googleapis.com/css2?family=Noto+Sans:ital,wght@0,100..900;1,100..900&display=swap" rel="stylesheet">
		<link href="https://fonts.googleapis.com/css2?family=Noto+Color+Emoji&display=swap" rel="stylesheet">
		<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Mono:wght@100..900&display=swap" rel="stylesheet">
		<link rel='canonical' href='https://tty.pt$DOCUMENT_URI' />
		<title>$PINDEX_ICON $_TITLE</title>
	</head>
!
}

_Cat() {
	cat $DOCUMENT_ROOT/tmp/normal
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

SeeOther() {
	header "Location: $1"
	Fatal 303 "See Other"
}

RB() {
	echo "<a class='$RBS' href='$2'>$1</a>"
}

Immediate() {
	content="$1"
	shift

	SUBINDEX_ICON=""
	test ! -z "$_TITLE" || _TITLE="$content"
	# rm $DOCUMENT_ROOT/tmp/fun $DOCUMENT_ROOT/tmp/bottom || true
	if test -f $content; then
		CONTENT="`INCEPTION=true . ./$content $@`"
	else
		CONTENT="`cat -`"
	fi
	test -f $DOCUMENT_ROOT/tmp/post \
		&& cat $DOCUMENT_ROOT/tmp/post \
		&& return 0 || true
	test ! -z "$PRECLASS" || PRECLASS="v f fic"
	FUNCTIONS="`test -f $DOCUMENT_ROOT/tmp/fun && cat $DOCUMENT_ROOT/tmp/fun || echo " "`"
	BOTTOM_CONTENT="`test ! -f $DOCUMENT_ROOT/tmp/bottom || cat $DOCUMENT_ROOT/tmp/bottom`"

	test -z "$INDEX_ICON" \
		|| INDEX_ICON="`RB $INDEX_ICON ./..`"

	export MENU="`Menu`"
	export INDEX_ICON
	export SUBINDEX_ICON
	export FUNCTIONS
	export CONTENT
	export MENU_LEFT
	export BOTTOM_CONTENT
	export _TITLE
	export PRECLASS

	test -f "$DOCUMENT_ROOT/tmp/normal" || \
		Normal $STATUS_CODE "./$content"
	CCat common
	exit 0
}

INCEPTION=false
_Fatal() {
	local status_code=$1
	shift 1
	export _TITLE="$status_code: `_ "$@"`"
	if test "$HTTP_ACCEPT" = "text/plain"; then
		NormalHead $status_code
		echo
		echo $_TITLE
		return 1
	fi
	export _TITLE
	STATUS_CODE=$status_code
	Normal "$STATUS_CODE" $DOCUMENT_URI
	$INCEPTION && echo $_TITLE || Immediate - $@
}

Fin() {
	cat - > $DOCUMENT_ROOT/tmp/post
	exit 0
}

Fatal() {
	_Fatal $@
	exit 0
}

get_lang() {
	echo $HTTP_ACCEPT_LANGUAGE | tr ',' '\n' | tr '-' '_' | tr ';' ' ' | \
		while read alang qlang; do \
			if grep "$alang" $DOCUMENT_ROOT/locale/langs; then
				break
			fi
		done | head -n 1
}

lang="`get_lang`"
htmllang="`echo $lang | tr '_' ' ' | awk '{print $1}'`"
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
		user_icon="`RB 👤 /user`"
	else
		user_icon="`RB 🔑 /login?ret=$DOCUMENT_URI`"
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

no_html() {
	sed -e 's/</\&lt\;/g' -e 's/>/\&gt\;/g' 
}

Whisper() {
	WHISPER_PATH=$DOCUMENT_ROOT/users/$REMOTE_USER/.whisper
	WHISPER="`zcat $WHISPER_PATH | no_html`"
	if test -z "$WHISPER"; then
		return
	fi

	echo "<pre>$WHISPER</pre>"
	rm $WHISPER_PATH
}

UserNormal() {
	NormalHead "$1"
	echo "Link: <http://$HTTP_HOST/e/$2$3>; rel=\"alternate\"; hreflang=\"x-default\""
	echo
	export HEAD="`Head`"
	export WHISPER="`Whisper`"
	export MENU="`Menu`"
}

_Normal() {
	UserNormal $@
	echo "$HEAD"
	echo "$WHISPER"
}

Normal() {
	_Normal $@ > $DOCUMENT_ROOT/tmp/normal
	public $DOCUMENT_ROOT/tmp/normal
}

uname=`uname`
shadow=shadow
test "$uname" != "OpenBSD" || shadow=master.passwd

auth() {
	username=$1
	password=$2
	REMOTE_USER=""
	hash="`grep "^$username:" $DOCUMENT_ROOT/etc/$shadow | awk 'BEGIN{FS=":"} {print $2}'`"
	test ! -z "$hash" || return 0
	htpasswd -v $DOCUMENT_ROOT/etc/$shadow "$username" "$password" || return 0
	test ! -f $DOCUMENT_ROOT/users/$username/rcode || return 0

	REMOTE_USER="$username"
}

#!/bin/ksh

umask 002
set -e

[[ -z "$VERY_COMMON" ]] || return 0
VERY_COMMON=y

debug() {
	echo Status: 500 Internal Error
	echo
	echo Sorry, I\'m currently debugging. Please wait.
}

NormalHead() {
	case "$1" in
		200) STATUS_TEXT="OK";;
		400) STATUS_TEXT="Bad Request";;
		401) STATUS_TEXT="Unauthorized";;
		404) STATUS_TEXT="Not Found";;
	esac
	export STATUS_TEXT
	export STATUS_CODE=$1
	echo "Status: $1 $STATUS_TEXT"
	echo 'Content-Type: text/html; charset=utf-8'
}

Head() {
	cat<<!
<html>
	<head>
		<meta content="text/html; charset=utf-8" http-equiv="Content-Type">
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
		<link rel="stylesheet" href="/vim.css" />
		<title>$_TITLE</title>
	</head>
!
}

Cat() {
	if [[ $# -lt 1 ]]; then
		envsubst
	else
		cat $ROOT/templates/$1.html | envsubst
	fi
	echo "</html>"
}


get_lang() {
	IFS=";"
	echo $HTTP_ACCEPT_LANGUAGE | tr ',' '\n' | tr '-' '_' | \
		while read alang qlang; do \
			if grep "$alang" $ROOT/locale/langs; then
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
	IFS='$'
	TEXTDOMAIN=site
	value="`cat $ROOT/locale/$TEXTDOMAIN-$lang.txt | sed -n "s|^$@\|||p"`"
	[[ -z "$value" ]] && echo $@ || echo $value
}

export RB="btn round ps tsxl"
export SRB="btn round ps tsl"

Menu() {
	if [[ ! -z "$REMOTE_USER" ]]; then
		USER_NAME="<span class=\"ts\">$REMOTE_USER</span>"
		USER_ICON="<a class=\"tsxl f _ fic btn ps\" href=\"/e/user\"><span>🔑 </span><span> $USER_NAME</span></a>"
	else
		USER_ICON="<a class=\"$RB\" href=\"/e/login\">🔑 </a>"
	fi
	export USER_ICON
	cat $ROOT/components/menu.html | envsubst
}

Unauthorized() {
	NormalHead 401
	export _TITLE="`_ Unauthorized`"
	echo
	Head
	export MENU="`Menu`"
	Cat fatal
	exit
}

cookie=$HTTP_COOKIE
cookie="`echo $cookie | tr ' ' '\n' | head -n 1`"

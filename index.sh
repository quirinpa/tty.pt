#!/bin/sh

export REQ_PID=$$
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=$DOCUMENT_ROOT/usr/bin:$DOCUMENT_ROOT/usr/local/bin:$DOCUMENT_ROOT/bin:$PATH:$DOCUMENT_ROOT/usr/sbin:$DOCUMENT_ROOT/usr/local/sbin

rmtmp() {
	rm -rf $headers $normal $post $fun \
		$bottom $ncat $settings $notitle \
		$full_size || true
}

trap 'rmtmp' EXIT
trap 'echo "ERROR! $0:$LINENO" >&2; exit 1' ERR

# env >&2
# echo METHOD: $REQUEST_METHOD URI: $DOCUMENT_URI QS: $QUERY_STRING >&2

if ! echo $DOCUMENT_URI | grep -q '/$'; then
	echo $DOCUMENT_URI | tr ' ' '\n' | tail -n 1 | grep -q '.' \
		|| DOCUMENT_URI="$DOCUMENT_URI/"
fi

export rid="`openssl rand -base64 10 | cut -c1-13 | tr -d '/'`"
export headers="$DOCUMENT_ROOT/tmp/headers$rid"
export normal="$DOCUMENT_ROOT/tmp/normal$rid"
export post="$DOCUMENT_ROOT/tmp/post$rid"
export fun="$DOCUMENT_ROOT/tmp/fun$rid"
export bottom="$DOCUMENT_ROOT/tmp/bottom$rid"
export ncat="$DOCUMENT_ROOT/tmp/ncat$rid"
export settings="$DOCUMENT_ROOT/tmp/settings$rid.db"
export notitle="$DOCUMENT_ROOT/tmp/notitle$rid.db"
export full_size="$DOCUMENT_ROOT/tmp/full_size$rid.db"

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

___() {
	local res
	local query
	read res query
	test "$res" = "-1" && echo "$@" || echo "$res"
}

export qdb=qdb
# export qdb=$DOCUMENT_ROOT/usr/local/bin/qdb

__() {
	$qdb -g"$@" $DOCUMENT_ROOT/items/i18n-$lang.db:s | ___ "$@" || echo "$@"
}

public() {
	chmod g+w $1
	chgrp www $1
}

header() {
	echo "$@" >> $headers
	public $headers
}

debug() {
	echo "$STATUS_STR"500 Internal Error
	echo "Content-Type: text/plain; charset=UTF-8"
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
	local status_code=$1
	echo "$STATUS_STR$1 $STATUS_TEXT"
	echo "Content-Type: $RES_CONTENT_TYPE"
	test ! -f $headers || cat $headers
}

Head() {
	cat<<!
<!DOCTYPE html>
<html lang="$htmllang">
	<head>
		<meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes">
		<meta name="description" content="tty.pt $_TITLE">
		`#<link rel="stylesheet" href="/basics.css">
		#<link rel="stylesheet" href="/vim.css">`
		<link rel="stylesheet" href="/vim.css">
		<link rel='canonical' href='https://tty.pt$DOCUMENT_URI' />
		<title>$PINDEX_ICON $_TITLE</title>
		<style>`cat $DOCUMENT_ROOT/htdocs/basics.css`</style>
	</head>
!
}

_Cat() {
	cat $normal
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
	test ! -f $notitle || _TITLE=
	test -z "$_TITLE" || \
		_TITLE="<h2 id='title' class='ttc tac'>$_TITLE $SUBINDEX_ICON</h2>"
	export _TITLE
	_Cat $DOCUMENT_ROOT/components/$1
}

SeeOther() {
	header "Location: $1"
	Fatal 303 "See Other"
}

env > $DOCUMENT_ROOT/tmp/env

RB() {
	test -z "$2" || label="<label>`__ "$2"`</label>"
	echo "<a href='$3'><span>$1</span>$label</a>"
}

JSB() {
	test -z "$2" || label="<label>`__ "$2"`</label>"
	echo "<div onclick=\"$3\"><span>$1</span>$label</div>"
}

hidparams() {
	echo "$QUERY_STRING" | tr '&' '\n' | \
		while IFS='=' read param value; do
			test "$param" != "$1" || continue
			echo "<input name='$param' type='hidden' value='$value'></input>"
		done
}

IFB() {
	test -z "$2" || label="<label>`__ "$2"`</label>"
	cat <<!
<form action='$3' method='POST'>
<button class="h8"><span>$1</span>$label</button>
</form>
!
}

FB() {
	test -z "$2" || label="`__ "$2"`"
	cat <<!
<form action='$3' method='$4' class='h8 f p8 fic'>
<span>$1</span>
<label><div>$label</div>`cat`</label>
`hidparams $5`
<noscript><button class="$RBS">✔</button></noscript>
</form>
!
}

QB() {
	local icon="$1"
	local label="$2"
	local param="$3"
	local value="$4"
	local qs="`echo $QUERY_STRING | sed "s/$param=[^&]*&*//"`"
	RB "$icon" "$label" "?$param=$value&$qs"
}

qs_get() {
	local qs="`env | grep 'HTTP_PARAM_' | sed 's/HTTP_PARAM_//' | tr '\n' '&'`"
	test -z "$qs" || echo "?$qs"
}

TB() {
	local val="`eval 'echo $HTTP_PARAM_'$1`"
	local invert
	local tty="$DOCUMENT_ROOT/home/$REMOTE_USER/.tty"
	unset HTTP_PARAM_
	eval 'unset HTTP_PARAM_'$1

	if test -f $tty/$MOD-$1; then
		invert=true
		if test ! -z "$val" && test ! -z "$REMOTE_USER"; then
			rm $tty/$MOD-$1
			SeeOther "$DOCUMENT_URI`qs_get`"
		fi
	else
		invert=false
		if test ! -z "$val" && test ! -z "$REMOTE_USER"; then
			touch $tty/$MOD-$1
			SeeOther "$DOCUMENT_URI`qs_get`"
		fi
	fi

	if test -z "$6"; then
		$invert && invert=false || invert=true
	else
		$invert && invert=true || invert=false
	fi

	if $invert; then
		if test -z "$val"; then
			buttons="$buttons`QB "$2" "$3" $1 1`"
			true
		else
			buttons="$buttons`QB "$4" "$5" $1`"
			false
		fi
	else
		if test -z "$val"; then
			buttons="$buttons`QB "$4" "$5" $1 1`"
			false
		else
			buttons="$buttons`QB "$2" "$3" $1`"
			true
		fi
	fi
}

Immediate() {
	content="$1"
	shift

	SUBINDEX_ICON=""
	if test -f $content; then
		CONTENT="`INCEPTION=true . $content $@`"
	else
		CONTENT="`cat -`"
	fi
	if test -f $post ; then
		echo IMM POST "$DOCUMENT_URI" >&2
		cat $post
		return 0
	fi
	test ! -z "$PRECLASS" || PRECLASS="v f fic"
	FUNCTIONS="`test -f $fun && cat $fun || echo " "`"
	BOTTOM_CONTENT="`test ! -f $bottom || cat $bottom`"

	test -z "$INDEX_ICON" \
		|| INDEX_ICON="`RB $INDEX_ICON "go up"  ./..`"

	export MENU="`Menu`"
	export INDEX_ICON
	export SUBINDEX_ICON
	export FUNCTIONS
	export CONTENT
	export MENU_LEFT
	export BOTTOM_CONTENT
	export _TITLE
	export PRECLASS

	test -f "$normal" || \
		Normal $STATUS_CODE "$content"
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
	cat - > $post
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
if test "$lang" = "pt_BR" || test "$lang" = "pt" || test "$lang" = "pt_PT"; then
	lang=pt_PT
else
	lang=en
fi
htmllang="`echo $lang | tr '_' ' ' | awk '{print $1}'`"
export lang
export LANG=$lang
ILANG=$LANG

_() {
	arg="$@"
	IFS='$'
	TEXTDOMAIN=site
	value="`cat $DOCUMENT_ROOT/locale/$TEXTDOMAIN-$lang.txt | sed -n "s|^$arg\|||p"`"
	test -z "$value" && echo $arg || echo $value
}

export RB="btn round p16 ts20"
export RBS="btn round p8"
export RBXS="btn round p4 tss"
export SRB="btn round ps tsl"

Menu() {
	local user_name
	local user_icon
	if test ! -z "$REMOTE_USER"; then
		user_icon="`RB 😊 "me" /$REMOTE_USER`"
	else
		user_icon="`RB 🔑 "login" /login?ret=$DOCUMENT_URI`"
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
	echo "Link: <http://$HTTP_HOST/$DOCUMENT_URI$3>; rel=\"alternate\"; hreflang=\"x-default\""
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
	# test using non logged in nd
	if test -f $post ; then
		cat $post
		exit 0
	fi

	_Normal $@ > $normal
	public $normal
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

if test ! -z "$cookie" && test -f "$DOCUMENT_ROOT/sessions/$cookie"; then
	user="`cat $DOCUMENT_ROOT/sessions/$cookie`"
	REMOTE_USER=$user
elif ! test -z "$HTTP_AUTHORIZATION"; then
	AUTH="`echo $HTTP_AUTHORIZATION | awk '{print $2}' | openssl base64 -d | tr ':' ' '`"
	username="`echo $AUTH | awk '{print $1}'`"
	password="`echo $AUTH | awk '{print $2}'`"
	auth $username $password || true
fi

Forbidden() {
	Fatal 403 Forbidden
}

NotAllowed() {
	Fatal 405 "Method Not Allowed"
}

MustPost() {
	test "$REQUEST_METHOD" = "POST" || NotAllowed
}

NotFound() {
	Fatal 404 "Not Found"
}

_bc() {
	read exp
	echo "$exp" | bc -l
}

math() {
	echo "$@" | _bc
}

san_param() {
	echo "$@" | tr '&' '\n' | awk 'BEGIN{FS="="; OFS="="} NF>1 {$1=tolower($1)}1' | while IFS='=' read name value; do
		echo export HTTP_PARAM_$name=\"`urldecode "$value"`\"
	done
}

fd() {
	test ! -f $DOCUMENT_ROOT/tmp/mpfd/$1 || \
		cat $DOCUMENT_ROOT/tmp/mpfd/$1
}

case "$REQUEST_METHOD" in
	POST)
		case "$CONTENT_TYPE" in
			multipart/form-data*)
				# grep -q "^$REMOTE_USER$" $DOCUMENT_ROOT/.uploaders || Forbidden "`_ "You don't have upload permissions"`"
				boundary="`echo $CONTENT_TYPE | sed 's/.*=//'`"
				rm $DOCUMENT_ROOT/tmp/mpfd/* 2>/dev/null || true
				mpfd "$boundary"
				;;
			application/x-www-form-urlencoded*)
				read line1 || true
				eval "`san_param "$line1"`"
				;;
		esac
		;;
	GET)
		eval "`san_param "$QUERY_STRING"`"
		;;
	*)
		;;
esac

counter_inc() {
	current="`zcat $1 || echo 0`"
	local existed="`test -f "$1" && echo true || echo false`"
	math $current + 1 | tee $1
	$existed || public $1
}

counter_dec() {
	current="`zcat $1 || echo 0`"
	local existed="`test -f "$1" && echo true || echo false`"
	math $current - $2 | tee $1
	$existed || public $1
}

sum_lines_exp() {
	echo -n '(0'
	sed 's/$/ +/' | tr '\n' ' ' | sed 's/ + $//'
	echo -n ')'
}

# poem only
revlines() {
	rev | tr '\n' '~' | rev | tr '~' '\n'
}

_see_other() {
	Fin <<!
${STATUS_STR}303 See Other
Location: $1

!
}

see_other() {
	Fin <<!
${STATUS_STR}303 See Other
Location: /e/$1$2

!
}

if test "$uname" = "Linux"; then
	fsize() {
		stat --format %s $1
	}

else
	fsize() {
		stat -f%z $1
	}
fi

id_query() {
	awk '{print $1}' | while read line; do
		echo "-$1$line$2"
	done
}

## COMPONENTS

NormalCat() {
	Normal 200 $SCRIPT $1
	Cat $SCRIPT
}

SCRIPT="`echo $DOCUMENT_URI | awk -F '/' '{print $2}'`"
ARG="`echo $DOCUMENT_URI | awk -F '/' '{print $3}'`"
set -- `echo $DOCUMENT_URI | tr '/' ' '`
case "$DOCUMENT_URI" in
	*/) dot=. ;;
	*) eval dot="\$$#" ;;
esac
export dot
if test "$SCRIPT" = "e"; then
	SCRIPT="`echo $DOCUMENT_URI | awk -F '/' '{print $3}'`"
	ARG="`echo $DOCUMENT_URI | awk -F '/' '{print $4}'`"
	e_mode=1
fi

fw() {
	csurround div "class=\"h$1 v$1 f fw fcc fic\""
}

invalid_id() {
	valid="`echo $@ | tr -cd '[a-zA-Z0-9]_'`"
	count="`echo $@ | wc -c`"
	test "$valid" != "$@" || test "$count" -le 0
}

invalid_password() {
	count="`echo $@ | wc -c`"
	test "$count" -le 8
}

invalid_lang() {
	lang="$@"
	! grep -q "$lang" $DOCUMENT_ROOT/locale/langs
}

urlencode() {
	echo -n "$1" | od -t d1 | awk '{
	for (i = 2; i <= NF; i++) {
		printf(($i>=48 && $i<=57) || ($i>=65 && $i<=90) || ($i>=97 && $i<=122) || $i==45 || $i==46 || $i==95 || $i==126 ?  "%c" : "%%%02x", $i)
	}
}'
}

ilang() {
	test -f ./index-$LANG.db && echo -$LANG
}

filter_one() {
	while read id0 rest; do
		echo $rest
	done
}

Buttons() {
	local cla="$1"
	local where="$3"
	local extra="$4"
	local aflags="$5"
	test ! -z "$aflags" || aflags="1"
	local link
	local flags
	local title
	echo "<div class='f fic v8'>"
	while read link flags title; do
		cat <<!
<a class="btn wsnw h $cla" href="$where$link/$extra">
	$title
</a>
!
	done
	echo "</div>"
}

Buttons3() {
	local db="`test -f ./index-$LANG.db && echo -$LANG`"
	local cla="$1"
	local path="$2"
	local where="$3"
	local extra="$4"
	local aflags="$5"
	test ! -z "$aflags" || aflags="1"
	local title
	$qdb -l ./index`ilang`.db:s | while read link flags title; do
	test $link != "-1" && test "$(($flags & $aflags))" = "$aflags" || continue;
		cat <<!
<div><a class="btn wsnw h $cla" href="$where$link/$extra">
	$title
</a></div>
!
	done
}

imin() {
	test ! -z "$2" || return 1
	groups | tr ' ' '\n' | grep -q "$2"
}

im() {
	if test "$REMOTE_USER" = "$1"; then
		return 0
	elif test ! -z "$2" && imin "$2"; then
		return 0
	else
		return 1
	fi
}

contents=$DOCUMENT_ROOT/tmp/contents

cond() {
	# tee $contents$1
	cat - > $contents$1
	public $contents$1
	test -z "`cat $contents$1`"
}

# shop only
surround() {
	echo "<$@>"
	cat -
	echo "</$1>"
}

csurround() {
	local contents="`cat -`"

	test -z "$contents" || {
		echo $contents | surround $@
	}

}

Field() {
	cat <<!
<div class="_">
	<span class="tsxs">$1</span>
	<span>$2</span>
</div>
!
}

_Functions() {
	read icon label params
	RB $icon label $DOCUMENT_URI?$params
}

Functions() {
	while test $# -ge 1; do
		echo $1 | _Functions
		shift
	done >> $fun
}

IsAllowedItemFound() {
	set -- `echo $REQUEST_URI | tr '/' ' '`
	test -d $iid || NotFound
}

AddBtn() {
	RB + "add" ./add/
}

valid_cgi() {
	test -f "$1" || return 1
	echo "$1" | grep -q '\.' || return 0
	return 1
}

Index() {
	typ=$1
	test $# -lt 1 || shift
	MOD="$typ"
	MOD_PATH="$DOCUMENT_ROOT/items/$typ"

	if test -z "$SUBINDEX_ICON"; then
		SUBINDEX_ICON="`zcat $MOD_PATH/icon || echo "🗂"`"
	fi
	test ! -z "$PINDEX_ICON" || PINDEX_ICON="`zcat $MOD_PATH/icon`"

	test ! -f $MOD_PATH/.lib/index.sh || . $MOD_PATH/.lib/index.sh

	case "$1" in
		"") ;;
		add) shift; Add $MOD_PATH/add $@ ; exit 0;;
		*)
			if valid_cgi $MOD_PATH/$1; then
				Immediate $MOD_PATH/$1 $@
				exit 0
			elif test ! -f "$MOD_PATH/over-index" || test -f "$MOD_PATH/index"; then
				INDEX_ICON="$SUBINDEX_ICON"
				SUBINDEX_ICON=" "
				_TITLE=
				SubIndex $typ $@
				exit 0
			fi
			;;
	esac

	test "$REQUEST_METHOD" = "GET" || return 0

	if test -z "$_TITLE"; then
		TITLE="`zcat $MOD_PATH/title || echo $typ`"
		_TITLE="`__ "$TITLE"`"
	fi

	test ! -z "$INDEX_ICON" || INDEX_ICON="🏠"
	INDEX_ICON="`RB $INDEX_ICON "home" ./..`"

	if test -z "$FUNCTIONS"; then
		FUNCTIONS="`test -z "$REMOTE_USER" || test ! -f $MOD_PATH/add || AddBtn`"
	fi

	if test -z "$CONTENT"; then
		if test -f "$MOD_PATH/over-index"; then
			CONTENT="`. "$MOD_PATH/over-index"`"
			test ! -f $full_size || \
				export FULL_SIXE="svfv"
		else
			CONTENT="`zcat template/index.html || Buttons3 'tsxl cap' items /$typ/`"
		fi
	fi

	if test -f $normal ; then
		cat $normal
		exit 0
	fi

	FUNCTIONS="$FUNCTIONS`test -f $fun && cat $fun || echo " "`"

	export _TITLE
	export INDEX_ICON
	export SUBINDEX_ICON
	export BOTTOM_CONTENT
	export CONTENT
	export FUNCTIONS
	Normal 200 $typ
	CCat common
	exit 0
}

owner_get() {
	local path="$1"
	if test -f $path/.owner; then
		cat $path/.owner
	else
		ls -al $path | head -n 2 | tail -n 1 | awk '{print $3}'
	fi
}

SubIndex() {
	typ=$1
	shift
	iid="$1"
	IsAllowedItemFound $@
	OWNER=`owner_get $iid`
	ORIG_OWNER=`owner_get $DOCUMENT_ROOT/items/$typ/items/$iid`

	content="index"
	cd $1
	shift

	case "$1" in
		"") ;;
		add) shift; _TITLE= Add sub-add $@ ; exit 0;;
		delete) shift; _TITLE= Delete delete $@ ; exit 0;;
		*)
			if test -f $DOCUMENT_ROOT/items/$typ/$1; then
				_TITLE="`_ $1`"
				Immediate $DOCUMENT_ROOT/items/$typ/$1 $@
				exit 0
			else
				NotFound
			fi
			;;
	esac

	if test -z "$_TITLE"; then
		_TITLE="`zcat title || true`"
	fi

	if im $OWNER $typ; then
	cat > $fun <<!
`RB 📝 edit $dot/edit/`
`RB "🗑" delete $dot/delete/`
!
	fi

	Immediate $DOCUMENT_ROOT/items/$typ/$content $@
}

is_main() {
	set -- `echo $DOCUMENT_URI | tr '/' ' '`
	test $# -ge 4 && return 1
	return 0
}

reindex() {
	case "$DOCUMENT_URI" in
		/$REMOTE_USER*) return 0;;
	esac
	. $DOCUMENT_ROOT/items/$1/reindex "$2"
}

InvalidItem() {
	rm -rf "$ITEM_PATH"
	Fatal 400 Invalid item
}

translate() {
	iconv -f utf-8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /_/g'
}

Add() {
	local template=$1
	shift
	test ! -z "$REMOTE_USER" || Forbidden

	if test "$REQUEST_METHOD" = "GET"; then
		test ! -z "$_TITLE" || _TITLE="`_ "Add item"`"
		test ! -z "$INDEX_ICON" || INDEX_ICON="🗂"

		export FILES="<label>`__ files`<input required type='file' name='file[]' multiple></input></label>"
		export FILE="<label>`__ file`<input required type='file' name='file'></input></label>"

		Immediate - <<!
<form action="/$MOD/add" method="POST" class="v f fic" enctype="multipart/form-data">
	<label>
		`__ title`
		<input required name="title" value="$HTTP_PARAM_title"></input>
	</label>
	`. $template`
	<div>$_DESCRIPTION</div>
	<button>`__ submit`</button>
</form>
!
		exit 0
	fi

	test "$REQUEST_METHOD" = "POST" || NotAllowed

	title="`fd title`"
	link="`echo "$title" | translate`"
	item_id="`$qdb -p "$link:1 $title" index.db:s`"

	mkdir -p $item_id
	cd $item_id
	echo $REMOTE_USER > .owner
	echo "$title" > title

	. $template
	SeeOther /$MOD/$link/edit/ | Immediate - $@
}

Delete() {
	shift
	test ! -z "$REMOTE_USER" || Forbidden

	if test "$REQUEST_METHOD" = "GET"; then
		test ! -z "$_TITLE" || _TITLE="`__ delete`"
		test ! -z "$INDEX_ICON" || INDEX_ICON="🗂"

		Immediate - <<!
<form action="." method="POST" class="v f fic">
	<div class="f v fic">
		<div>Are you sure you wish to delete this item?</div>
		<div class="h tac">
			<button class='cf15 c9'>`__ yes`</button>
			<a href="./.."><button type='button'>`__ no`</button></a>
		</div>
	</div>
</form>
!
		exit 0
	fi

	test "$REQUEST_METHOD" = "POST" || NotAllowed

	if ! is_main; then
		rm -rf ../$iid
		SeeOther /$REMOTE_USER
		exit 0
	fi

	im $OWNER || Forbidden

	test ! -f delete || . ./delete

	$qdb -rd "$iid" ./../index.db:s >/dev/null || true
	rm -rf ./../$iid
	SeeOther ../../
}

nfiles() {
	urldecode "$@" | sed '/^$/d' | tr -d '\r'
}

a2l() {
	while test $# -ge 1; do
		echo $1
		shift;
	done
}

noslash() {
	sed -e 's:/:\\/:g' $1
}

cslash() {
	if grep -q "^$REMOTE_USER$" $DOCUMENT_ROOT/.slash; then
		cat -
	else
		noslash -
	fi
}

mpfd_ls() {
	local file_count="`cat $DOCUMENT_ROOT/tmp/mpfd/file-count`"
	for i in `seq 0 $file_count`; do
		local FILE_PATH=$DOCUMENT_ROOT/tmp/mpfd/file$i
		filename="`cat $FILE_PATH-name`"
		echo $FILE_PATH $filename
	done
}

literal() {
	sed 's/</\&lt\;/g'
}

export GIT_HTTP_EXPORT_ALL=1
export REQUEST_METHOD

git_backend() {
	export GIT_PROJECT_ROOT="/"
	export PATH_INFO="`echo $DOCUMENT_URI | sed 's|^/~|/home/|'`"
	$DOCUMENT_ROOT/usr/local/libexec/git/git-http-backend 2>&1
	exit
}

# counter_inc $DOCUMENT_ROOT/counter.txt >/dev/null

if test ! -z "$1"; then
	INDEX_ICON="🏠"
	case "$1" in
		1.txt)
			cd ./items/poem/items
			export DOCUMENT_URI="/poem/1/"
			Index poem 1
			;;
		~*)
			. ./tilde $@ ;;
		*)
			if test -d ./items/$1; then
				cd ./items/$1
				test ! -d ./items || cd items
				Index $@
			elif test -d  ./home/$1; then
				_TITLE="$1"
				. ./me/index $@
				exit 0
			elif test -d  ./$1; then
				_TITLE="$1"
				. ./$1/index $@
				exit 0
			elif test -f  ./$1; then
				_TITLE="$1"
				Immediate ./$1 $@
				# . ./.$1 $@
			else
				path="$DOCUMENT_ROOT/htdocs/$DOCUMENT_URI"
				if test ! -f "$path"; then
					test ! -z "$REMOTE_USER" || NotFound
					path="$DOCUMENT_ROOT/home/$REMOTE_USER/$DOCUMENT_URI"
					# check perms (not applicable, for now)
					# ls -al $path  | awk '{print $1}' | tail -c 4 | grep -q r
					test -f "$path" || NotFound
				fi
				echo "$STATUS_STR"200 Ok
				echo "Cache-Control: max-age=7200"
				echo
				cat "$path"
			fi
			;;
	esac
	exit 0
fi

test "$REQUEST_METHOD" = "GET" || NotAllowed

_TITLE=$HTTP_HOST
ttyf="`test $HTTP_HOST = tty.pt && echo 1 || echo 2`"
cd items
Buttons3 'f jcsb cap tsxl' items "/" "" "$ttyf" | Immediate -

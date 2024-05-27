#!/bin/ksh

. $DOCUMENT_ROOT/lib/very-common.sh

Forbidden() {
	NormalHead 403
	_TITLE="`_ Forbidden`"
	if [[ $# -ge 1 ]]; then
		_TITLE="$_TITLE - $@"
	fi
	export _TITLE
	echo
	Head
	export MENU="`Menu`"
	Cat fatal
	exit
}

NotAllowed() {
	NormalHead 405 Method Not Allowed
	_TITLE="`_ Method Not Allowed`"
	if [[ $# -ge 1 ]]; then
		_TITLE="$_TITLE - $@"
	fi
	export _TITLE
	echo
	Head
	export MENU="`Menu`"
	Cat fatal
	exit
}

MustPost() {
	test "$REQUEST_METHOD" == "POST" || NotAllowed
}

NotFound() {
	NormalHead 404 Not Found
	_TITLE="`_ Not Found`"
	if [[ $# -ge 1 ]]; then
		_TITLE="$_TITLE - $@"
	fi
	export _TITLE
	echo
	Head
	export MENU="`Menu`"
	Cat fatal
	exit
}

bc() {
	read exp
	#echo "BC='$exp'" >&2
	echo "$exp" | $DOCUMENT_ROOT/usr/bin/bc "$@"
}

math() {
	echo "$@" | bc
}

_urldecode() {
	sed 's@+@ @g;s@%@\\x@g' | xargs -0 printf "%b"
}

urldecode() {
	echo $@ | _urldecode
}

url2vars() {
	# lowercase keys
	exp="`echo $1 | tr '&' '\n' | awk 'BEGIN{FS="="; OFS="="} NF>1 {$1=tolower($1)}1'`"
	#exp="`echo $1 | tr '[A-Z]' '[a-z]'| tr '&' '\n'`"
	eval "$exp"
}

case "$REQUEST_METHOD" in
	POST)
		case "$CONTENT_TYPE" in
			multipart/form-data*)
				grep -q "^$REMOTE_USER$" $DOCUMENT_ROOT/.uploaders || Forbidden "`_ "You don't have upload permissions"`"
				boundary="`echo $CONTENT_TYPE | sed 's/.*=//'`"
				$DOCUMENT_ROOT/usr/bin/mpfd "$boundary" 2>&1
				;;
			application/x-www-form-urlencoded*)
				read line1 || true
				url2vars $line1
				;;
		esac
		;;
	GET)
		url2vars $QUERY_STRING
		;;
	*)
		;;
esac


# export $lang

#. gettext.sh

#alias _=eval_gettext

counter_inc() {
	current="`zcat $1`"
	if [[ ! -z "$current" ]]; then
		next="`echo $current + 1 | bc`"
		echo $next | tee $1
	else
		touch $1
		echo 1 | tee $1
	fi
}

counter_dec() {
	if [[ -f $1 ]]; then
		current="`cat $1`"
		next="`echo $current - $2 | bc`"
		echo $next | tee $1
	else
		touch $1
		echo -1 | tee $1
	fi
}

sum_lines_exp() {
	echo -n '(0'
	sed 's/$/ +/' | tr '\n' ' ' | sed 's/ + $//'
	echo -n ')'
}

revlines() {
	rev | tr '\n' '~' | rev | tr '~' '\n'
}

_see_other() {
	echo 'Status: 303 See Other'
	echo "Location: $1"
	echo
	exit
}

see_other() {
	echo 'Status: 303 See Other'
	echo "Location: /e/$1$2"
	echo
	exit
}

no_html() {
	sed -e 's/</\&lt\;/g' -e 's/>/\&gt\;/g' 
}

format_df() {
	#printf "%-40.40s %s\n" "$1" "$2"
	echo "$1 $2"
}

df_dir() {
	if [[ ! -d $DOCUMENT_ROOT/$1 ]]; then
		return
	fi
	du_user="`du -c $DOCUMENT_ROOT/$1 | tail -1 | awk '{print $1}'`"
	format_df $1 `calcround "$du_user * 1024"`
}

dir_df() {
	ls $DOCUMENT_ROOT/$1 | \
		while read line; do
			path=$DOCUMENT_ROOT/$1/$line
			OWNER="`cat $path/.owner`"
			[[ "$OWNER" != "$DF_USER" ]] || df_dir $1/$line
		done
}

df() {
	df_dir users/$DF_USER
	df_dir htdocs/img/$DF_USER
	dir_df shops
	dir_df poems
	dir_df sems
	dir_df schools
}

df_total_exp() {
	df | awk '{ print $2 }' | sum_lines_exp
}

df_total() {
	# echo DF_TOTAL_EXP="`df_total_exp`" >&2
	echo "`df_total_exp`" | bc
}

calcround() {
	exp="`echo "$@" | tr -d '\'`"
	#echo "CALCROUND=$exp" >&2
	echo "$exp" | bc -l | xargs printf "%.0f"
}

free_space() {
	N_USERS="`cat $DOCUMENT_ROOT/.htpasswd | wc -l | sed 's/ //g'`"
	FREE_SPACE_EXP="(20000000000 / $N_USERS)"
	calcround "$FREE_SPACE_EXP"
}

FREE_SPACE="`free_space`"

__fbytes() {
	[[ -z "$DF_USER" ]] && Fatal 400 Checking bytes of unknown user
	OCCUPIED_SPACE="`df_total`"
	CAN_EXP="($FREE_SPACE - $OCCUPIED_SPACE) >= $1"
	CAN="`echo $CAN_EXP | bc -l`"
	[[ "$CAN" == "0" ]]
}

_fbytes() {
	if __fbytes $1; then
		Fatal 400 No available space
	fi
}

fbytes() {
	STAT="`stat -f%z $1`"
	_fbytes $STAT
}

fmkdir() {
	if [[ ! -d "$1" ]]; then
		fbytes $DOCUMENT_ROOT/empty
		mkdir -p "$1"
	fi
}

fwrite() {
	cat - > $1
	local count="`cat $1 | wc | awk '{print $3}'`"
	if __fbytes $count; then
		rm $1
		Fatal 400 No available space
	fi
}

fappend() {
	cat - > $DOCUMENT_ROOT/tmp/append
	local count="`cat $DOCUMENT_ROOT/tmp/append | wc | awk '{print $3}'`"
	if __fbytes $count; then
		rm $DOCUMENT_ROOT/tmp/append
		Fatal 400 No available space
	else
		cat $DOCUMENT_ROOT/tmp/append >> $1
		rm $DOCUMENT_ROOT/tmp/append
	fi
}

## COMPONENTS

Whisper() {
	WHISPER_PATH=$DOCUMENT_ROOT/users/$REMOTE_USER/.whisper
	WHISPER="`zcat $WHISPER_PATH | no_html`"
	if [[ -z "$WHISPER" ]]; then
		return
	fi

	echo "<pre>$WHISPER</pre>"
	rm $WHISPER_PATH
}

NotNormal() {
	NormalHead "$1"
	shift
	echo "Link: <http://$HTTP_HOST$@>; rel=\"alternate\"; hreflang=\"x-default\""
	echo
	Head
	Whisper
	export MENU="`Menu`"
}

Normal() {
	NormalHead "$1"
	echo "Link: <http://$HTTP_HOST/e/$2$3>; rel=\"alternate\"; hreflang=\"x-default\""
	echo
	Head
	Whisper
	export MENU="`Menu`"
}

UserNormal() {
	NormalHead "$1"
	echo "Link: <http://$HTTP_HOST/e/$2$3>; rel=\"alternate\"; hreflang=\"x-default\""
	echo
	export HEAD="`Head`"
	export WHISPER="`Whisper`"
	export MENU="`Menu`"
}

NormalCat() {
	Normal 200 $SCRIPT $1
	Cat $SCRIPT
}

Fatal() {
	SC=$1
	shift
	allargs="$@"
	export _TITLE="`_ "$allargs"`"

	if [[ "$HTTP_ACCEPT" == "text/plain" ]]; then
		NormalHead $SC
		echo
		echo $_TITLE
		exit 1
	else
		export _HEAD_TITLE="tty.pt - $SC - $_TITLE"
		Normal $SC
		Cat fatal
		exit 1
	fi
}

DF_USER=$REMOTE_USER
SCRIPT="`echo $DOCUMENT_URI | awk -F '/' '{print $2}'`"
ARG="`echo $DOCUMENT_URI | awk -F '/' '{print $3}'`"
set -- `echo $DOCUMENT_URI | tr '/' ' '`
if [[ "$SCRIPT" == "e" ]]; then
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
	[[ "$valid" != "$@" ]] || [[ "$count" -le 0 ]]
}

invalid_password() {
	count="`echo $@ | wc -c`"
	[[ "$count" -le 8 ]]
}

invalid_lang() {
	lang="$@"
	! grep -q "$lang" $DOCUMENT_ROOT/locale/langs
}

urlencode () {
	echo -n "$1" | od -t d1 | awk '{
	for (i = 2; i <= NF; i++) {
		printf(($i>=48 && $i<=57) || ($i>=65 && $i<=90) || ($i>=97 && $i<=122) || $i==45 || $i==46 || $i==95 || $i==126 ?  "%c" : "%%%02x", $i)
	}
}'
}

Buttons() {
	if [[ $e_mode == 1 ]]; then
		while read id; do
			_TITLE="`_ $id`"
			where="$2"
			extra="$3"
			urlid="`urlencode "$id"`"
			cat <<!
<div><a class="btn $1" href="/e/$where?${where}_id=$urlid/$extra">
	$_TITLE
</a></div>
!
		done
	else
		while read id; do
			_TITLE="`_ $id`"
			where="$2"
			extra="$3"
			urlid="`urlencode "$id"`"
			cat <<!
<div><a class="btn $1" href="/$where/$urlid/$extra">
	$_TITLE
</a></div>
!
		done
	fi
}

BigButtons() {
	Buttons "tsxl" "$1" "$2"
}

SmallButtons() {
	Buttons "c0 ps rs" "$1" "$2"
}

for_each_in() {
	path="$1"
	target="$2"
	find_id="$3"

	ls $path | while read id; do
		if grep -q "$find_id" "$path/$id/$target"; then
			echo $id
		fi
	done
}

im() {
	ret=""
	while [[ $# -ge 1 ]]; do
		if [[ "$REMOTE_USER" == "$1" ]]; then
			ret="1"
			break;
		fi
		shift
	done

	[[ "$ret" == "1" ]]
}

contents=$DOCUMENT_ROOT/tmp/contents

cond() {
	# tee $contents$1
	cat - > $contents$1
	[[ -z "`cat $contents$1`" ]]
}

surround() {
	echo "<$@>"
	cat -
	echo "</$1>"
}

csurround() {
	local contents="`cat -`"

	[[ -z "$contents" ]] || {
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

EditBtn() {
	im $OWNER || return 0
	echo "<a class='$RB' href='./edit/'>📝</a>"
	# local i_edit="✎"
	# echo $i_edit | surround a "href=\"$1/\"" "class=\"$RB\""
}

_Functions() {
	read icon params
	echo "<a class=\"$RBS\" href=\"$DOCUMENT_URI?$params\">$icon</a>"
}

Functions() {
	while test $# -ge 1; do
		echo $1 | _Functions
		shift
	done
}

IsAllowedItemFound() {
	set -- `echo $REQUEST_URI | tr '/' ' '`
	local item_path="$ROOT/$1/$iid"
	test ! -z "$ITEM_PATH" \
		|| ITEM_PATH="$item_path"

	if test -z "$iid" || test ! -f "$ITEM_PATH" && test ! -d "$ITEM_PATH"; then
		Fatal 404 Item not found
	fi
}

AddBtn() {
	echo "<a class='$RB' href='./add'>+</a>"
}

Index() {
	typ=$1
	test $# -lt 1 || shift
	case "$1" in
		"") ;;
		add) shift; . ./.add $@ ; exit 0;;
		*)
			INDEX_ICON="$SUBINDEX_ICON"
			SUBINDEX_ICON=" "
			_TITLE= . ./.sub-index $@
			exit 0
			;;
	esac

	test "$REQUEST_METHOD" == "GET" || return 0

	export _TITLE

	test ! -z "$INDEX_ICON" || INDEX_ICON="🏠"
	test ! -z "$SUBINDEX_ICON" || SUBINDEX_ICON="🗂"

	test ! -z "$FUNCTIONS" || \
		FUNCTIONS="`fun || test -z "$REMOTE_USER" || AddBtn`"
	test ! -z "$CONTENT" || \
		CONTENT="`content || ls_shown . | BigButtons $typ`"

	export INDEX_ICON
	export SUBINDEX_ICON
	export BOTTOM_CONTENT
	export CONTENT
	export FUNCTIONS
	Normal 200 $typ
	Scat $ROOT/components/common
	exit 0
}

SubIndex() {
	test "$REQUEST_METHOD" == "GET" || return 0
	SUBINDEX_ICON=""
	test ! -z "$_TITLE" || _TITLE="$iid"
	test ! -z "$PRECLASS" || PRECLASS="v f fic"
	test ! -z "$CONTENT" || CONTENT=`content || true`
	test ! -z "$FUNCTIONS" || FUNCTIONS=`fun || true`

	export iid
	export INDEX_ICON
	export SUBINDEX_ICON
	export FUNCTIONS
	export CONTENT
	export MENU_LEFT
	export BOTTOM_CONTENT
	export _TITLE
	export PRECLASS

	Normal 200 ./$iid
	Scat $ROOT/components/common
	exit 0
}

Add() {
	[[ ! -z "$REMOTE_USER" ]] || Forbidden

	if test "$REQUEST_METHOD" == "GET"; then
		test ! -z "$_TITLE" || _TITLE="`_ "Add item"`"
		test ! -z "$SUBINDEX_ICON" || SUBINDEX_ICON="🗂"

		export _ID="`_ "ID"`"
		export _DESCRIPTION
		export _SUBMIT="`_ Submit`"
		export ENCTYPE
		export FORM_CONTENT
		export SUBINDEX_ICON

		Normal 200 ./add
		Scat ../components/add
		return
	fi

	test "$REQUEST_METHOD" == "POST" || NotAllowed

	iid="`cat $ROOT/tmp/mpfd/iid`"

	if invalid_id $iid; then
		Fatal 400 Not a valid ID
	fi

	ITEM_PATH="`pwd`/$iid"

	fmkdir $ITEM_PATH
	echo $REMOTE_USER | fwrite $ITEM_PATH/.owner

	process_post

	if invalid_item; then
		rm -rf $ITEM_PATH
		Fatal 400 Invalid item
	fi

	_see_other ./$iid
}

nfiles() {
	urldecode "$@" | sed '/^$/d' | tr -d '\r'
}

a2l() {
	while [[ $# -ge 1 ]]; do
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

mpfd-ls() {
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

ls_shown() {
	ls $1 | while read line; do
		if [[ ! -f "$1/$line/.hidden" ]]; then
			echo $line
		fi
	done
}

export GIT_HTTP_EXPORT_ALL=1
export REQUEST_METHOD

git_backend() {
	export GIT_PROJECT_ROOT="/"
	export PATH_INFO="`echo $DOCUMENT_URI | sed 's|^/~|/home/|'`"
	# echo PATH_INFO$PATH_INFO
	$DOCUMENT_ROOT/usr/local/libexec/git/git-http-backend 2>&1
	exit
}

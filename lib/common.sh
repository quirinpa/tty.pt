#!/bin/sh

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

_urldecode() {
	sed 's@+@ @g;s@%@\\x@g' | xargs -0 printf "%b"
}

urldecode() {
	echo $@ | _urldecode
}

san_param() {
	echo $1 | tr '&' '\n' | awk 'BEGIN{FS="="; OFS="="} NF>1 {$1=tolower($1)}1' | while IFS='=' read name value; do
		echo HTTP_PARAM_$name=$value
	done
}

url2vars() {
	eval "`san_param $@`"
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
				url2vars $line1
				;;
		esac
		;;
	GET)
		url2vars "$QUERY_STRING"
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

Buttons3() {
	local db="`test -f items/index-$LANG.db && echo -$LANG`"
	local cla="$1"
	local path="$2"
	local where="$3"
	local extra="$4"
	local aflags="$5"
	test ! -z "$aflags" || aflags="1"
	local sub
	local title
	qhash -l items/index$db.db | sort -Vk1 | while read sub link flags title; do
	test $sub != "-1" && test $(($flags & ~$aflags)) = 0 || continue;
		cat <<!
<div><a class="btn wsnw h $cla" href="$where$link/$extra">
	$title
</a></div>
!
	done
}

im() {
	ret=""
	while test $# -ge 1; do
		if test "$REMOTE_USER" = "$1"; then
			ret="1"
			break;
		fi
		shift
	done

	test "$ret" = "1"
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

EditBtn() {
	im $OWNER || return 0
	RB 📝 ./edit/
}

_Functions() {
	read icon params
	RB $icon $DOCUMENT_URI?$params
}

Functions() {
	while test $# -ge 1; do
		echo $1 | _Functions
		shift
	done >> $DOCUMENT_ROOT/tmp/fun
}

IsAllowedItemFound() {
	set -- `echo $REQUEST_URI | tr '/' ' '`
	local item_path="`pwd`/items/$iid"
	test ! -z "$ITEM_PATH" \
		|| ITEM_PATH="$item_path"

	if test ! -f "$ITEM_PATH" && test ! -d "$ITEM_PATH"; then
		Fatal 404 Item not found
	fi
}

AddBtn() {
	RB + ./add/
}

Index() {
	typ=$1
	test $# -lt 1 || shift

	INDEX_PATH="`pwd`"
	if test -z "$SUBINDEX_ICON"; then
		SUBINDEX_ICON="`zcat icon || echo "🗂"`"
	fi
	test ! -z "$PINDEX_ICON" || PINDEX_ICON="`zcat icon`"

	test ! -f .lib/index.sh || . .lib/index.sh

	if test -f "$PWD/over-index"; then
		if test -z "$_TITLE"; then
			TITLE="`zcat title || echo $typ`"
			_TITLE="`_ "$TITLE"`"
		fi
		Immediate over-index $@
		exit 0
	fi

	case "$1" in
		"") ;;
		add) shift; Add add $@ ; exit 0;;
		*)
			ITEM_PATH="`pwd`/items/$1"
			INDEX_ICON="$SUBINDEX_ICON"
			SUBINDEX_ICON=" "
			_TITLE=
			SubIndex $@
			exit 0
			;;
	esac

	test "$REQUEST_METHOD" = "GET" || return 0

	if test -z "$_TITLE"; then
		TITLE="`zcat title || echo $typ`"
		_TITLE="`_ "$TITLE"`"
	fi

	test ! -z "$INDEX_ICON" || INDEX_ICON="🏠"
	INDEX_ICON="`RB $INDEX_ICON ./..`"

	test ! -z "$FUNCTIONS" || \
		FUNCTIONS="`test -z "$REMOTE_USER" || test ! -f add || AddBtn`"
	test ! -z "$CONTENT" || \
		CONTENT="`zcat template/index.html || Buttons3 'tsxl cap' items $DOCUMENT_URI`"

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
	local path=items/$iid
	if test -f $path/.owner; then
		cat $path/.owner
	else
		ls -al $path | awk '{print $3}'
	fi
}

SubIndex() {
	iid="$1"
	IsAllowedItemFound $@
	OWNER=`owner_get`

	content="index"
	shift

	case "$1" in
		"") ;;
		add) shift; _TITLE= Add sub-add $@ ; exit 0;;
		delete) shift; _TITLE= Delete delete $@ ; exit 0;;
		*)
			if test -f ./$1; then
				content=$1
				_TITLE="`_ $1`"
				Immediate $content $@
				exit 0
			else
				SUB_ITEM_PATH="$ITEM_PATH/items/$1"
				content=sub-index
			fi
			;;
	esac

	if test -z "$_TITLE"; then
		_TITLE="`cat items/$iid/title`"
	fi

	if im $OWNER; then
	cat > $DOCUMENT_ROOT/tmp/fun <<!
`RB 📝 ./edit/`
`RB "🗑" ./delete/`
!
	fi

	Immediate $content $@
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

		export FILES="<label>`_ Files`<input required type='file' name='file[]' multiple></input></label>"
		export FILE="<label>`_ File`<input required type='file' name='file'></input></label>"

		Immediate - <<!
<form action="." method="POST" class="v f fic" enctype="multipart/form-data">
	<label>
		`_ Title`
		<input required name="title"></input>
	</label>
	`. ./$template`
	<div>$_DESCRIPTION</div>
	<button>`_ Submit`</button>
</form>
!
		exit 0
	fi

	test "$REQUEST_METHOD" = "POST" || NotAllowed

	title="`fd title`"
	link="`echo "$title" | translate`"
	item_id="`qhash -p "$link 0 $title" items/index.db`"

	ITEM_PATH="`test -z "$ITEM_PATH" && pwd || echo "$ITEM_PATH"`/items/$item_id"

	mkdir -p items/$item_id
	ln -sf $item_id items/$link
	echo $REMOTE_USER > $ITEM_PATH/.owner
	echo "$title" > $ITEM_PATH/title

	. ./$template
	SeeOther ../$link/edit/ | Immediate - $@
}

Delete() {
	shift
	test ! -z "$REMOTE_USER" || Forbidden

	if test "$REQUEST_METHOD" = "GET"; then
		test ! -z "$_TITLE" || _TITLE="`_ "Delete item"`"
		test ! -z "$INDEX_ICON" || INDEX_ICON="🗂"

		Immediate - <<!
<form action="." method="POST" class="v f fic">
	<div class="f v fic">
		<div>Are you sure you wish to delete this item?</div>
		<div class="h tac">
			<button class='cf15 c9'>`_ Yes`</button>
			<a href="./.."><button type='button'>`_ No`</button></a>
		</div>
	</div>
</form>
!
		exit 0
	fi

	test "$REQUEST_METHOD" = "POST" || NotAllowed

	test ! -f delete || . ./delete

	nid="`readlink items/$iid`"
	if test "$nid" = "-1"; then
		nid="$iid"
		iid="`qhash -rg "$nid" items/index.db | cut -d' ' -f2-`"
	fi
	qhash -rd "$nid" items/index.db >/dev/null || true
	rm -rf items/$iid items/$nid

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

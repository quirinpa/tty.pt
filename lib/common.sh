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
				grep -q "^$REMOTE_USER$" $DOCUMENT_ROOT/.uploaders || Forbidden "`_ "You don't have upload permissions"`"
				boundary="`echo $CONTENT_TYPE | sed 's/.*=//'`"
				rm $DOCUMENT_ROOT/tmp/mpfd/* 2>/dev/null || true
				mpfd "$boundary" 2>&1
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


# export $lang

#. gettext.sh

#alias _=eval_gettext

counter_inc() {
	current="`zcat $1`"
	if test ! -z "$current"; then
		next="`math $current + 1`"
		echo $next | tee $1
	else
		touch $1
		echo 1 | tee $1
	fi
}

counter_dec() {
	if test -f $1; then
		current="`cat $1`"
		next="`math $current - $2`"
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

no_html() {
	sed -e 's/</\&lt\;/g' -e 's/>/\&gt\;/g' 
}

format_df() {
	#printf "%-40.40s %s\n" "$1" "$2"
	echo "$1 $2"
}

df_dir() {
	du_user="`du -c $DOCUMENT_ROOT/$1 | tail -1 | awk '{print $1}'`"
	format_df "$1" "`calcround "$du_user * 1024"`"
}

dir_df() {
	ls $DOCUMENT_ROOT/$1/items | \
		while read line; do
			path="$DOCUMENT_ROOT/$1/items/$line"

			local OWNER="`owner_get`"
			test "$OWNER" != "$DF_USER" || df_dir "$1/items/$line"
		done
}

df() {
	df_dir users/$DF_USER
	# df_dir htdocs/img/$DF_USER
	ls $DOCUMENT_ROOT/items/ | while read item; do
		test ! -d $DOCUMENT_ROOT/items/$item/items \
			|| dir_df items/$item
	done
	# rm $DOCUMENT_ROOT/tmp/post || true
}

df_total_exp() {
	df | awk '{ print $2 }' | sum_lines_exp
}

df_total() {
	# echo DF_TOTAL_EXP="`df_total_exp`" >&2
	math "`df_total_exp`"
}

calcround() {
	exp="`echo "$@" | tr -d '\'`"
	#echo "CALCROUND=$exp" >&2
	math "$exp" | xargs printf "%.0f"
}

free_space() {
	N_USERS="`cat $DOCUMENT_ROOT/etc/passwd | wc -l | sed 's/ //g'`"
	FREE_SPACE_EXP="(20000000000 / $N_USERS)"
	calcround "$FREE_SPACE_EXP"
}

FREE_SPACE="`free_space`"

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

DF_USER=$REMOTE_USER
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

urlencode () {
	echo -n "$1" | od -t d1 | awk '{
	for (i = 2; i <= NF; i++) {
		printf(($i>=48 && $i<=57) || ($i>=65 && $i<=90) || ($i>=97 && $i<=122) || $i==45 || $i==46 || $i==95 || $i==126 ?  "%c" : "%%%02x", $i)
	}
}'
}

Buttons2() {
	local cla="$1"
	local path="$2"
	local where="$3"
	local extra="$4"
	local sub
	local id
	ls $path | while read sub; do
		test ! -f "$path/$sub/.hidden" || continue
		id="`zcat $path/$sub/title || echo $sub | tr '_' ' '`"
		_TITLE="`_ "$id"`"
		echo $sub $_TITLE
	done | sort -V | while read sub title; do
		urlid="`urlencode "$sub"`"
		icon="`test ! -f "$path/$sub/icon" || cat "$path/$sub/icon"`"
		test -z "$icon" || icon="<span>$icon</span>"
		cat <<!
<div><a class="btn wsnw h $cla" href="$where$urlid/$extra">
	<span>$title</span>$icon
</a></div>
!
	done
}

Buttons3() {
	local cla="$1"
	local path="$2"
	local where="$3"
	local extra="$4"
	local sub
	local title
	qhash -q items/index.db -rl items/links.db | sort -Vk1 | while read sub link title; do
		test $sub != "-1" || continue;
		cat <<!
<div><a class="btn wsnw h $cla" href="$where$link/$extra">
	$title
</a></div>
!
	done
}

Buttons() {
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
	test -z "`cat $contents$1`"
}

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
	# local i_edit="✎"
	# echo $i_edit | surround a "href=\"$1/\"" "class=\"$RB\""
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
	iconv -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /_/g'
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
	item_id="`qhash -p "$title" items/index.db`"
	link="`echo "$title" | translate`"
	qhash -p"$link" items/links.db >/dev/null

	ITEM_PATH="`test -z "$ITEM_PATH" && pwd || echo "$ITEM_PATH"`/items/$item_id"

	mkdir -p items/$item_id
	echo ln -sf $item_id items/$link >&2
	ln -sf $item_id items/$link
	echo $REMOTE_USER > $ITEM_PATH/.owner
	echo "$title" > $ITEM_PATH/title

	. ./$template
	SeeOther ../$item_id/ | Immediate - $@
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

	nid="`qhash -rg "$iid" items/links.db | awk '{print $1}'`"
	if test "$nid" = "-1"; then
		nid="$iid"
		iid="`qhash -g "$nid" items/links.db | cut -d' ' -f2-`"
	fi
	qhash -d "$nid" items/links.db >/dev/null || true
	qhash -d "$nid" items/index.db >/dev/null || true
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

ls_shown() {
	ls $1 | while read line; do
		if test ! -f "$1/$line/.hidden"; then
			echo $line
		fi
	done
}

export GIT_HTTP_EXPORT_ALL=1
export REQUEST_METHOD

git_backend() {
	export GIT_PROJECT_ROOT="/"
	export PATH_INFO="`echo $DOCUMENT_URI | sed 's|^/~|/home/|'`"
	$DOCUMENT_ROOT/usr/local/libexec/git/git-http-backend 2>&1
	exit
}

#!/bin/sh

. $DOCUMENT_ROOT/lib/very-common.sh

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

url2vars() {
	# lowercase keys
	exp="`echo $1 | tr '&' '\n' | awk 'BEGIN{FS="="; OFS="="} NF>1 {$1=tolower($1)}1'`"
	#exp="`echo $1 | tr '[A-Z]' '[a-z]'| tr '&' '\n'`"
	eval "$exp"
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
			local OWNER="`zcat "$path/.owner" || echo www`"
			test "$OWNER" != "$DF_USER" || df_dir "$1/items/$line"
		done
}

df() {
	df_dir users/$DF_USER
	df_dir htdocs/img/$DF_USER
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
	N_USERS="`cat $DOCUMENT_ROOT/.htpasswd | wc -l | sed 's/ //g'`"
	FREE_SPACE_EXP="(20000000000 / $N_USERS)"
	calcround "$FREE_SPACE_EXP"
}

FREE_SPACE="`free_space`"

__fbytes() {
	test -z "$DF_USER" && Fatal 400 Checking bytes of unknown user
	OCCUPIED_SPACE="`df_total`"
	CAN_EXP="($FREE_SPACE - $OCCUPIED_SPACE) >= $1"
	CAN="`math "$CAN_EXP"`"
	test $CAN -eq 0
}

_fbytes() {
	if __fbytes $1; then
		Fatal 400 No available space
	fi
}

if test "`uname`" = "Linux"; then
	fsize() {
		stat --format %s $1
	}

else
	fsize() {
		stat -f%z $1
	}
fi

fbytes() {
	STAT="`fsize $1`"
	_fbytes $STAT
}

fmkdir() {
	if test ! -d "$1"; then
		fbytes $DOCUMENT_ROOT/empty
		mkdir -p "$1"
		# chown $REMOTE_USER:www "$1" 2>&1
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
		urlid="`urlencode "$sub"`"
		icon="`test ! -f "$path/$sub/icon" || cat "$path/$sub/icon"`"
		test -z "$icon" || icon="<span>$icon</span>"
		cat <<!
<div><a class="btn wsnw h $cla" href="$urlid/$extra">
	<span>$_TITLE</span>$icon
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
	done > $DOCUMENT_ROOT/tmp/fun
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
		FUNCTIONS="`fun || test -z "$REMOTE_USER" || test ! -f add || AddBtn`"
	test ! -z "$CONTENT" || \
		CONTENT="`zcat template/index.html || Buttons2 'tsxl cap' items`"

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
	test -f $ITEM_PATH/.owner && cat $ITEM_PATH/.owner || echo quirinpa
	return 0
	if test -f $1; then
		ls -al $1 | awk '{print $3}'
	else
		cat $1/.owner
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
		_TITLE="`zcat $ITEM_PATH/title || echo $iid | tr '_' ' '`"
	fi

	Immediate $content $@
}

InvalidItem() {
	rm -rf "$ITEM_PATH"
	Fatal 400 Invalid item
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
		`_ ID`
		<input required name="item_id"></input>
	</label>
	`Cat $template`
	<div>$_DESCRIPTION</div>
	<button>`_ Submit`</button>
</form>
!
		exit 0
	fi

	test "$REQUEST_METHOD" = "POST" || NotAllowed

	item_id="`fd item_id`"

	if invalid_id $item_id; then
		Fatal 400 Not a valid ID
	fi

	ITEM_PATH="`test -z "$ITEM_PATH" && pwd || echo "$ITEM_PATH"`/items/$item_id"

	fmkdir $ITEM_PATH
	echo $REMOTE_USER | fwrite $ITEM_PATH/.owner

	. ./$template 2>&1

	_see_other ./$item_id/
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

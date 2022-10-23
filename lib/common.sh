#!/bin/ksh

. $ROOT/lib/very-common.sh

Forbidden() {
	NormalHead 403
	export _TITLE="`_ Forbidden`"
	echo
	Head
	export MENU="`Menu`"
	Cat fatal
	exit
}

bc() {
	read exp
	#echo "BC='$exp'" >&2
	echo "$exp" | $ROOT/usr/bin/bc "$@"
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
				boundary="`echo $CONTENT_TYPE | sed 's/.*=//'`"
				$ROOT/usr/bin/mpfd "$boundary" 2>&1
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

see_other() {
	echo 'Status: 303 See Other'
	echo "Location: /e/$1$2"
	echo
}

no_html() {
	sed -e 's/</\&lt\;/g' -e 's/>/\&gt\;/g' 
}

format_df() {
	#printf "%-40.40s %s\n" "$1" "$2"
	echo "$1 $2"
}

df_dir() {
	if [[ ! -d $ROOT/$1 ]]; then
		return
	fi
	du_user="`du -c $ROOT/$1 | tail -1 | awk '{print $1}'`"
	format_df $1 `calcround "$du_user * 1024"`
}

dir_df() {
	ls $ROOT/$1 | \
		while read line; do
			path=$ROOT/$1/$line
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
	N_USERS="`cat $ROOT/.htpasswd | wc -l | sed 's/ //g'`"
	FREE_SPACE_EXP="(20000000000 / $N_USERS)"
	calcround "$FREE_SPACE_EXP"
}

FREE_SPACE="`free_space`"

_fbytes() {
	[[ -z "$DF_USER" ]] && Fatal 400 Checking bytes of unknown user
	# echo exp="`df_total_exp`" >&2
	OCCUPIED_SPACE="`df_total`"
	CAN_EXP="($FREE_SPACE - $OCCUPIED_SPACE) >= $1"
	# echo CAN_EXP="$CAN_EXP" >&2
	CAN="`echo $CAN_EXP | bc -l`"
	if [[ "$CAN" == "0" ]]; then
		Fatal 400 No available space
	fi
}

fbytes() {
	STAT="`stat -f%z $1`"
	_fbytes $STAT
}

fmkdir() {
	if [[ ! -d "$1" ]]; then
		fbytes $ROOT/empty
		mkdir -p "$1"
	fi
}

fwrite() {
	TARGET=$1
	shift
	count="`$@ | wc | awk '{print $3}'`"
	_fbytes $count
	$@ > $TARGET
}

fappend() {
	TARGET=$1
	shift
	count="`$@ | wc | awk '{print $3}'`"
	_fbytes $count
	$@ >> $TARGET
}

rand_str_1() {
	# TODO maybe remove lowercase conversion
	xxd -l32 -ps $ROOT/dev/urandom | xxd -r -ps | openssl base64 \
		    | tr -d = | tr + - | tr / _ | tr '[A-Z]' '[a-z]'
}

## COMPONENTS

Whisper() {
	WHISPER_PATH=$ROOT/users/$REMOTE_USER/.whisper
	WHISPER="`zcat $WHISPER_PATH | no_html`"
	if [[ -z "$WHISPER" ]]; then
		return
	fi

	echo "<pre>$WHISPER</pre>"
	rm $WHISPER_PATH
}

Normal() {
	NormalHead "$1"
	echo "Link: <http://$HTTP_HOST/e/$2$3>; rel=\"alternate\"; hreflang=\"x-default\""
	echo
	Head

	Whisper
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
	export _HEAD_TITLE="tty.pt - $SC - $_TITLE"
	Normal $SC
	Cat fatal
	exit 1
}

DF_USER=$REMOTE_USER
SCRIPT="`basename $SCRIPT_NAME | cut -f1 -d'.'`"

fw() {
	csurround div "class=\"_$1 v$1 f fw fcc fic\""
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
	! grep -q "$lang" $ROOT/locale/langs
}

Buttons() {
	while read id; do
		_TITLE="`_ $id`"
		where="$2"
		extra="$3"
		cat <<!
<a class="btn $1" href="/e/$where?${where}_id=$id$extra">
	$_TITLE
</a>
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
	while [[ $# -ge 1 ]]; do
		if [[ "$REMOTE_USER" == "$1" ]]; then
			ret="1"
			break;
		fi
		shift
	done

	[[ "$ret" == "1" ]]
}

contents=$ROOT/tmp/contents

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
	local i_edit="✎"
	echo $i_edit | surround a "href=\"$1\"" "class=\"$RB\""
}

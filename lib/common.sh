#!/bin/ksh

. $ROOT/lib/very-common.sh

Forbidden() {
	NormalHead 403
	_TITLE="`_ Forbidden`"
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

urldecode() {
	echo $@ | sed 's@+@ @g;s@%@\\x@g' | xargs -0 printf "%b"
}

url2vars() {
	# lowercase keys
	exp="`echo $1 | tr '&' '\n' | awk 'BEGIN{FS="="; OFS="="} NF>1 {$1=tolower($1)}1'`"
	#exp="`echo $1 | tr '[A-Z]' '[a-z]'| tr '&' '\n'`"
	eval "$exp"
}

zcat() {
	[[ -f "$@" ]] && cat $@ || true
}

case "$REQUEST_METHOD" in
	POST)
		case "$CONTENT_TYPE" in
			multipart/form-data*)
				boundary="`echo $CONTENT_TYPE | sed 's/.*=//'`"

				mpfd "$boundary"
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
	echo -n '('
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

shops_df() {
	ls $ROOT/shops | \
		while read line; do
			SHOP_PATH=$ROOT/shops/$line
			OWNER="`cat $SHOP_PATH/.owner`"
			[[ "$OWNER" == "$DF_USER" ]] && df_dir shops/$line
		done
}

df() {
	df_dir users/$DF_USER
	df_dir htdocs/img/$DF_USER
	shops_df
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
		fbytes /empty
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
Wrap() {
	if [[ ! -z "$@" ]]; then
		echo "<div class=\"_ v f fw fcc fic\">$@</div>"
	fi
}

not_valid_id() {
	valid="`echo $@ | tr -cd '[a-zA-Z0-9]_'`"
	[[ "$valid" != "$@" ]]
}

not_valid_password() {
	count="`echo $@ | wc -c`"
	[[ "$count" -le 8 ]]
}

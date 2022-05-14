#!/bin/ksh

umask 002

. $ROOT/lib/more-common.sh

urldecode() {
	echo $@ | sed 's@+@ @g;s@%@\\x@g' | xargs -0 printf "%b"
}

url2vars() {
	# always lowercase to prevent overwriting REMOTE_USER
	eval "`echo $1 | tr '[A-Z]' '[a-z]'| tr '&' '\n'`"
}

case "$REQUEST_METHOD" in
	POST)
		case "$CONTENT_TYPE" in
			multipart/form-data*)
				boundary="`echo $CONTENT_TYPE | sed 's/.*=//'`"

				mpfd "$boundary"
				lang="`cat $ROOT/tmp/mpfd/lang`"
				;;
			*)
				read line1
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

export lang
export TEXTDOMAIN=site
export TEXTDOMAINDIR=$ROOT/usr/share/locale
export LANG=$lang
if [[ -z "$LANG" ]]; then
	LANG=pt_PT
fi
ILANG=$LANG
#LANG=$LANG.UTF-8

# export $lang

#. gettext.sh

#alias _=eval_gettext

_() {
	IFS='$'
	value="`cat $ROOT/locale/$TEXTDOMAIN-$LANG.txt | sed -n "s/^$1\|//p"`"
	[[ -z "$value" ]] && echo $1 || echo $value
}

counter_inc() {
	current="`[[ -f $1 ]] && cat $1 || echo 0`"
	next="`echo $current + 1 | bc`"
	echo $next | tee $1
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
	echo "Location: /cgi-bin/$1.cgi?lang=${lang}$2"
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
	du_user="`du -c $ROOT/$1 | tail -1 | awk '{print $1}'`"
	format_df $1 `calcround "$du_user \* 1024"`
}

shops_df() {
	ls $ROOT/shops | \
		while read line; do
			SHOP_PATH=$ROOT/shops/$line
			OWNER="`cat $SHOP_PATH/.owner`"
			[[ "$OWNER" == "$USER" ]] && df_dir $SHOP_PATH
		done
}

comments_df() {
	COMMENTS_PATH=/public/comments-$1.txt
	COMMENTS_SIZE="`sed -n "/^$USER:/p" $COMMENTS_PATH | wc | awk '{ print $3 }'`"
	format_df $COMMENTS_PATH $COMMENTS_SIZE
}

df() {
	df_dir users/$USER
	df_dir htdocs/img/$USER
	comments_df pt_PT
	comments_df en_US
	comments_df fa_IR
	comments_df fr_FR
	shops_df
}

df_total_exp() {
	df | awk '{ print $2 }' | sum_lines_exp
}

df_total() {
	echo "`df_total_exp`" | bc
}

calcround() {
	echo $@ | bc -l | xargs printf "%.0f"
}

free_space() {
	N_USERS="`cat $ROOT/.htpasswd | wc -l | sed 's/ //g'`"
	FREE_SPACE_EXP="(20000000000 / $N_USERS)"
	calcround $FREE_SPACE_EXP
}

FREE_SPACE="`free_space`"

_fbytes() {
	OCCUPIED_SPACE="`df_total`"
	CAN_EXP="($FREE_SPACE - $OCCUPIED_SPACE) >= $1"
	CAN="`echo $CAN_EXP | bc -l`"
	if [[ "$CAN" == "0" ]]; then
		Fatal 400
	fi
}

fbytes() {
	STAT="`stat -f%z $1`"
	_fbytes $USER $STAT
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
	_fail_bytes $USER $count
	$@ > $TARGET
}

fappend() {
	TARGET=$1
	shift
	count="`$@ | wc | awk '{print $3}'`"
	_fail_bytes $USER $count
	$@ >> $TARGET
}

LoginLogout() {
	_LOGINLOGOUT="`_ "Login / Logout"`"
	cat <<!
<div class="tac txl">
	<a href="/cgi-bin/login.cgi?lang=$lang" class="txl">$_LOGINLOGOUT 🔑</a>
</div>
!
}

## COMPONENTS
Menu() {
	if [[ ! -z "$REMOTE_USER" ]]; then
		USER_NAME="<span class=\"t\">$REMOTE_USER</span>"
		USER_ICON="<a class=\"txl f _ fic\" href=\"/cgi-bin/user.cgi?lang=$lang\"><span>🔑 </span><span> $USER_NAME</span></a>"
	fi
	export USER_ICON
	export _FLAG_ICON="`_ flag`"
	export THIS_URL="$1"
	cat $ROOT/components/menu.html | envsubst
}

Head() {
	cat<<!
<html>
	<head>
		<meta content="text/html; charset=utf-8" http-equiv="Content-Type">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="/neverdark/vim.css" />
		<title>$_TITLE</title>
	</head>
!
}

Whisper() {
	WHISPER_PATH=$ROOT/users/$REMOTE_USER/.whisper
	echo "<pre>"
	[[ -f $WHISPER_PATH ]] && cat $WHISPER_PATH | no_html && rm $WHISPER_PATH
	echo "</pre>"
}

Normal() {
	case "$1" in
		200) STATUS_TEXT="OK";;
		400) STATUS_TEXT="Bad Request";;
		401) STATUS_TEXT="Unauthorized";;
	esac
	export STATUS_TEXT
	echo "Status: $1 $STATUS_TEXT"
	echo 'Content-Type: text/html; charset=utf-8'
	echo
	Head

	Whisper
	export MENU="`Menu ./$2.cgi?$3`"
}

Cat() {
	if [[ $# -lt 1 ]]; then
		envsubst
	else
		cat $ROOT/templates/$1.html | envsubst
	fi
	echo "</html>"
}

Fatal() {
	Normal $1
	Cat fatal
	exit 1
}

#!/bin/ksh

umask 002

. $ROOT/lib/more-common.sh

urldecode() {
	echo $@ | sed 's@+@ @g;s@%@\\x@g' | xargs -0 printf "%b"
}

url2vars() {
	eval "`echo $1 | tr '&' '\n'`"
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

LoginLogout() {
	_LOGINLOGOUT="`_ "Login / Logout"`"
	cat <<!
<div class="tac txl">
	<a href="/cgi-bin/login.cgi" class="txl">$_LOGINLOGOUT 🔑</a>
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

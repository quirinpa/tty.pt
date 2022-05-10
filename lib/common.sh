#!/bin/ksh

urldecode() {
	echo $@ | sed 's@+@ @g;s@%@\\x@g' | xargs -0 printf "%b"
}

url2vars() {
	eval "`echo $1 | tr '&' '\n'`"
}

case "$REQUEST_METHOD" in
	POST)
		read line1
		url2vars $line1
		;;
	GET)
		url2vars $QUERY_STRING
		;;
	*)
		;;
esac

url2vars $QUERY_STRING
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

# urlencode() {
# 	while IFS= read -r c; do
# 		case $c in [a-zA-Z0-9.~_-]) printf "$c"; continue ;; esac
# 		printf "$c" | od -An -tx1 | tr ' ' % | tr -d '\n'
# 	done <<EOF
# $(fold -w1)
# EOF
# 	echo
# }

counter_inc() {
	typeset -LZ COUNTER
	if [[ -f $1 ]]; then
		COUNTER="`cat $1`"
	else
		COUNTER=0
	fi

	((COUNTER = COUNTER + 1))
	echo $COUNTER
}

## COMPONENTS
Menu() {
	export _FLAG_ICON="`_ flag`"
	export THIS_URL="$1"
	cat $ROOT/components/menu.html | envsubst
}

export lang

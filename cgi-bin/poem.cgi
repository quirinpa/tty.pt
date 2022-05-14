#!/bin/ksh

. $ROOT/lib/common.sh

noslash() {
	sed -e 's:/:\\/:g' $1
}

COMMENTS_PATH="$ROOT/public/comments-$ILANG.txt"

case "$REQUEST_METHOD" in
	POST)
		fappend $COMMENTS_PATH echo $REMOTE_USER: "`urldecode "$comment"`" 
		see_other poem
		;;
	GET)
		POEM_PATH="$ROOT/htdocs/1.txt"
		if [[ ! -z "$lang" ]]; then
			POEM_PATH="$ROOT/htdocs/1-$lang.txt"
		fi

		export _POEM="`cat $POEM_PATH`"
		export _COMMENTS="`cat $COMMENTS_PATH | revlines | no_html`"

		COUNTER_PATH=$ROOT/public/counter-$lang.txt
		export COUNTER="`counter_inc $COUNTER_PATH`"

		export _TITLE="`_ "Programmer's poem"`"
		export _FLAG_ICON="`_ flag`"

		Normal 200 poem
		Cat poem
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


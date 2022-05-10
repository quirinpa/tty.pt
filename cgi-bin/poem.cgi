#!/bin/ksh

. $ROOT/lib/common.sh

noslash() {
	sed -e 's:/:\\/:g' $1
}

COMMENTS_PATH="$ROOT/public/comments-$ILANG.txt"

case "$REQUEST_METHOD" in
	POST)
		echo $REMOTE_USER: "`urldecode "$comment"`" >> $COMMENTS_PATH
		echo 'Status: 303 See Other'
		echo "Location: /cgi-bin/poem.cgi?lang=${lang}"
		echo
		;;
	GET)
		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		POEM_PATH="$ROOT/htdocs/1.txt"
		if [[ ! -z "$lang" ]]; then
			POEM_PATH="$ROOT/htdocs/1-$lang.txt"
		fi

		export _POEM="`cat $POEM_PATH`"
		export _COMMENTS="`noslash $COMMENTS_PATH | revlines`"

		COUNTER_PATH=$ROOT/public/counter-$lang.txt
		export COUNTER="`counter_inc $COUNTER_PATH`"
		echo $COUNTER > $COUNTER_PATH

		export _TITLE="`_ "Programmer's poem"`"
		export _FLAG_ICON="`_ flag`"

		export MENU="`Menu ./poem.cgi?`"
		cat $ROOT/templates/poem.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


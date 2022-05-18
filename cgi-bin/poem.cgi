#!/bin/ksh

. $ROOT/lib/common.sh

noslash() {
	sed -e 's:/:\\/:g' $1
}

POEM_PATH=$ROOT/poems/$poem_id
COMMENTS_PATH="$POEM_PATH/comments.txt"

case "$REQUEST_METHOD" in
	POST)
		fappend $COMMENTS_PATH echo $REMOTE_USER: "`urldecode "$comment"`" 
		see_other poem ?poem_id=$poem_id
		;;
	GET)
		if [[ -z "$poem_id" ]]; then
			Fatal 404 Poem not found
		fi

		POEM_HTML_PATH="$POEM_PATH/pt_PT.html"

		if [[ ! -f "$POEM_HTML_PATH" ]] || [[ ! -d "$POEM_PATH" ]]; then
			Fatal 404 Poem not found
		fi

		NEW_POEM_HTML_PATH="$POEM_PATH/$lang.html"
		if [[ -f $NEW_POEM_HTML_PATH ]]; then
			POEM_HTML_PATH=$NEW_POEM_HTML_PATH
		fi

		export poem_id

		export _POEM="`cat $POEM_HTML_PATH`"
		export _COMMENTS="`cat $COMMENTS_PATH | revlines | no_html`"

		COUNTER_PATH=$POEM_PATH/counter.txt
		export COUNTER="`counter_inc $COUNTER_PATH`"

		POEM_TITLE="`cat $POEM_PATH/title.txt`"
		export _TITLE="`_ "$POEM_TITLE"`"

		NormalCat
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac


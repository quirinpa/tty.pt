. $DOCUMENT_ROOT/lib/common.sh

if test "$REQUEST_METHOD" != "GET"; then
	echo "Status: 405 Method Not Allowed"
	echo
	exit
fi

Command() {
	local args="$@"
	if test -z "$args"; then
		args=$SCRIPT
	fi

	if test "$HTTP_ACCEPT" == "text/plain"; then
		NormalHead 200
		echo
	else
		Normal 200
		echo
		export _TITLE="`_ Command` - $args"
		export MENU="`Menu`"
		export OUTPUT="`literal`"
		Cat command
	fi
}

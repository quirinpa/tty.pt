. $ROOT/lib/common.sh

if [[ "$REQUEST_METHOD" != "GET" ]]; then
	echo "Status: 405 Method Not Allowed"
	echo
	exit
fi

Command() {
	if [[ "$HTTP_ACCEPT" == "text/plain" ]]; then
		NormalHead 200
		echo
	else
		Normal 200
		echo
		export _TITLE="`_ Command` - $SCRIPT"
		export MENU="`Menu`"
		export OUTPUT="`literal`"
		Cat command
	fi
}

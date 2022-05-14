#!/bin/ksh

. $ROOT/lib/common.sh

ibeg() {
	cat - $1 > $ROOT/tmp/ibeg && mv $ROOT/tmp/ibeg $1
	#fwrite $ROOT/tmp/ibeg "cat - $1" && mv $ROOT/tmp/ibeg $1
}

USER_DIR="$ROOT/users/$REMOTE_USER"
USER=$REMOTE_USER
fmkdir $USER_DIR
OUTPUT_PATH="$USER_DIR/.tty"

case "$REQUEST_METHOD" in
	POST)
		CMD="`urldecode $cmd`"
		[[ -f $OUTPUT_PATH ]] || touch $OUTPUT_PATH
		echo "$REMOTE_USER$ $CMD" | ibeg $OUTPUT_PATH

		case "$CMD" in
			help) 
				echo Welcome to the terminal
				echo Beware - the values might not be correct
				echo commands: df quota clear whisper
				;;
			df)
				df
				;;
			quota)
				echo "`df_total`/`free_space`"
				;;
			clear)
				echo -n "" > $OUTPUT_PATH
				;;
			whisper*)
				set -- $CMD
				shift
				username=$1
				shift
				message=$@

				[[ -d $ROOT/users/$username ]] || fatal 400

				USER=$username
				fappend $ROOT/users/$username/.whisper \
					echo "$REMOTE_USER": "$message"
				echo "Sent whisper."
				;;
			*)
				;;
		esac | ibeg $OUTPUT_PATH

		;;
	GET)
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		exit
		;;
esac

export OUTPUT="`cat $OUTPUT_PATH | no_html`"
export _TITLE="`_ "Terminal"`"

Normal 200 tty
Cat tty

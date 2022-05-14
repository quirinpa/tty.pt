#!/bin/ksh

. $ROOT/lib/common.sh

ibeg() {
	cat - $1 > $ROOT/tmp/ibeg && mv $ROOT/tmp/ibeg $1
}

calcround() {
	echo $@ | bc -l | xargs printf "%.0f"
}

USER_DIR="$ROOT/users/$REMOTE_USER"
[[ -d "$USER_DIR" ]] || mkdir -m 770 -p $USER_DIR
OUTPUT_PATH="$USER_DIR/.tty"

case "$REQUEST_METHOD" in
	POST)
		CMD="`urldecode $cmd`"
		[[ -f $OUTPUT_PATH ]] || touch $OUTPUT_PATH
		echo "$ $CMD" | ibeg $OUTPUT_PATH

		case "$CMD" in
			help) 
				echo Welcome to the terminal
				echo Beware - the values might not be correct
				echo commands: df quota clear whisper
				;;
			df)
				mydf | ibeg $OUTPUT_PATH
				;;
			quota)
				N_USERS="`cat /.htpasswd | wc -l | sed 's/ //g'`"
				FREE_SPACE_EXP="(20000000000 / $N_USERS)"
				echo -n "`df_total`"/
				echo "`calcround $FREE_SPACE_EXP`"
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
				printf "%s: %s\n" "$REMOTE_USER" "$message" >> $ROOT/users/$username/.whisper
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

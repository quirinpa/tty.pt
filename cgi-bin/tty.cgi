#!/bin/ksh

. $ROOT/lib/common.sh

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
			[[ "$OWNER" == "$REMOTE_USER" ]] && df_dir $SHOP_PATH
		done
}

comments_df() {
	COMMENTS_PATH=/public/comments-$1.txt
	COMMENTS_SIZE="`sed -n "/^$REMOTE_USER:/p" $COMMENTS_PATH | wc | awk '{ print $3 }'`"
	format_df $COMMENTS_PATH $COMMENTS_SIZE
}

mydf() {
	df_dir users/$REMOTE_USER
	df_dir htdocs/img/$REMOTE_USER
	comments_df pt_PT
	comments_df en_US
	comments_df fa_IR
	comments_df fr_FR
	shops_df
}

df_total_exp() {
	mydf | awk '{ print $2 }' | sum_lines_exp
}

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
				USED_EXP="`df_total_exp`"
				echo -n "`calcround $USED_EXP`"/
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

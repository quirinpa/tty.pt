SemMenuOption() {
	if [[ $e_mode == 1 ]]; then
		echo "<div><a href=\"/e/sem-$1?sem_id=$sem_id\">`_ "$1"`</a></div>"
	else
		echo "<div><a href=\"/sem/$sem_id/$1\">`_ "$1"`</a></div>"
	fi
}

js() {
	cat <<!
`cat $DOCUMENT_ROOT/js/menu.js`
menu(document.getElementById("sem_menu_cont"));
!
}

access() {
	$SEM -p < $SEM_FILE
}

export JS="`js`"

SemMenu() {
	current="$1"
	options=""
	present="`echo $PRESENT | awk '{ print $1 }'`"

	if im $SEM_OWNER; then
		if [[ "$current" != "start" ]]; then
			options="$options`SemMenuOption start`"
		fi

		if [[ "$current" != "pause" ]] && $SEM -p < $SEM_FILE | grep -q '^P '; then
			options="$options`SemMenuOption pause`"
		fi

		if [[ "$current" != "resume" ]] && $SEM -p < $SEM_FILE | grep -q '^A '; then
			options="$options`SemMenuOption resume`"
		fi
	else
		case "$present" in
			P)
				if [[ "$current" != "pause" ]]; then
					options="$options`SemMenuOption pause`"
				fi

				if [[ "$current" != "stop" ]]; then
					options="$options`SemMenuOption stop`"
				fi

				;;
			A)
				if [[ "$current" != "resume" ]]; then
					options="$options`SemMenuOption resume`"
				fi

				if [[ "$current" != "stop" ]]; then
					options="$options`SemMenuOption stop`"
				fi

				;;
		esac
	fi

	if [[ "$current" != "pay" ]]; then
		options="$options`SemMenuOption pay`"
	fi

	if [[ "$current" != "transfer" ]]; then
		options="$options`SemMenuOption transfer`"
	fi

	if [[ "$current" != "buy" ]]; then
		options="$options`SemMenuOption buy`"
	fi

	cat <<!
<label id="sem_menu_cont" class="$RB rel c15 cf0 menu">
	+
	<input type="checkbox" />
	<div class="abs v0 f ah ak p c0 ts btn ttc">
		$options
	</div>
</label>
!
}

IdOptions() {
	while read value sel; do
		if test "$sel" == "y"; then
			echo "<option selected value=\"$value\">$value</option>"
		else
			echo "<option value=\"$value\">$value</option>"
		fi
	done
}

SourceIdOptions() {
	if im $SEM_OWNER; then
		cat $SEM_PATH/.owner $SEM_PATH/.members
	else
		echo $REMOTE_USER
	fi | IdOptions
}

sem_op() {
	$DOCUMENT_ROOT/usr/bin/sem-echo "`echo $@`" < $SEM_FILE > $DOCUMENT_ROOT/tmp/data.txt

	if $SEM -q 2>&1 < $DOCUMENT_ROOT/tmp/data.txt; then
		DF_USER=$SEM_OWNER
		cat $DOCUMENT_ROOT/tmp/data.txt | fwrite $SEM_FILE
		rm $DOCUMENT_ROOT/tmp/data.txt
		if [[ $e_mode == 1 ]]; then
			_see_other e/sem?sem_id=$sem_id
		else
			_see_other .
		fi
	else
		rm $DOCUMENT_ROOT/tmp/data.txt
		Fatal 409 We can not have that
	fi
}

sem_source() {
	if [[ $e_mode == 1 ]]; then
		SEM_PATH="$DOCUMENT_ROOT/sems/$sem_id"
	else
		SEM_PATH="$DOCUMENT_ROOT/sem/$sem_id"
	fi
	if [[ -z "$sem_id" ]]; then
		sem_id="`echo $SCRIPT_NAME | awk -F'/' '{print $3}'`"
		SEM_PATH="$DOCUMENT_ROOT/sem/$sem_id"
		sem_script=1
	fi
	SEM_FILE="$SEM_PATH/data.txt"

	if [[ -z "$sem_id" ]] ; then
		Fatal 404 Sem not found
	fi

	SEM_OWNER="`cat $SEM_PATH/.owner`"
	SEM="$DOCUMENT_ROOT/usr/bin/sem"

	if [[ ! -d "$SEM_PATH" ]]; then
		Fatal 404 Sem not found
	fi

	PRESENT="`access | grep $REMOTE_USER`"
	if [[ -z "$PRESENT" ]]; then
		Unauthorized
	fi

	export sem_id
}

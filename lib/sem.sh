SEM_PATH="$ROOT/sems/$sem_id"
SEM_FILE="$SEM_PATH/data.txt"
SEM_OWNER="`cat $SEM_PATH/.owner`"
SEM="$ROOT/usr/bin/sem"

if [[ -z "$sem_id" ]] || [[ ! -d "$SEM_PATH" ]]; then
	Fatal 404 Sem not found
fi

SemMenuOption() {
	echo "<div><a href=\"/e/sem-$1?sem_id=$sem_id\">`_ "$1"`</a></div>"
}

js() {
	cat <<!
`cat $ROOT/js/menu.js`
menu(document.getElementById("sem_menu_cont"));
!
}

access() {
	$SEM -p < $SEM_FILE
	echo S Gerson
}

export JS="`js`"
PRESENT="`access | grep $REMOTE_USER`"
if [[ -z "$PRESENT" ]]; then
	Unauthorized
fi

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
	<div class="abs vn f ah ak p c0 ts btn ttc">
		$options
	</div>
</label>
!
}

IdOptions() {
	while read value; do
		echo "<option value=\"$value\">$value</option>"
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
	$ROOT/usr/bin/sem-echo "`echo $@`" < $SEM_FILE > $ROOT/tmp/data.txt

	if $SEM -q 2>&1 < $ROOT/tmp/data.txt; then
		DF_USER=$SEM_OWNER
		cat $ROOT/tmp/data.txt | fwrite $SEM_FILE
		rm $ROOT/tmp/data.txt
		see_other sem ?sem_id=$sem_id
	else
		rm $ROOT/tmp/data.txt
		Fatal 409 We can not have that
	fi
}

export sem_id

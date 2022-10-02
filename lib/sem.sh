SEM_PATH="$ROOT/sems/$sem_id"
SEM_FILE="$SEM_PATH/data.txt"
SEM_OWNER="`cat $SEM_PATH/.owner`"
SEM="$ROOT/usr/bin/sem"

if [[ -z "$sem_id" ]] || [[ ! -d "$SEM_PATH" ]]; then
	Fatal 404 Sem not found
fi

SemMenuOption() {
	echo "<div><a href=\"/e/sem-$1?sem_id=$sem_id\">$2</a></div>"
}

SemScript() {
	cat <<!
<script>
let sem_menu = document.getElementById("sem_menu");
let sem_menu_container = document.getElementById("sem_menu_container");
sem_menu_container.classList.add("js");
sem_menu_container.removeChild(sem_menu_container.querySelector("input"));
sem_menu.classList.add("dn");
let sem_menu_visible = false;
sem_menu_container.onclick = function (ev) {
	sem_menu_visible = !sem_menu_visible;
	if (sem_menu_visible)
		sem_menu.classList.remove("dn");
	else
		sem_menu.classList.add("dn");
};
</script>
!
}

export SEM_SCRIPT="`SemScript`"
PRESENT="`$SEM -p < $SEM_FILE | grep $REMOTE_USER`"
if [[ -z "$PRESENT" ]]; then
	Unauthorized
fi

SemMenu() {
	current="$1"
	options=""
	present="`echo $PRESENT | awk '{ print $1 }'`"

	if [[ "$current" != "start" ]] && [[ "$REMOTE_USER" == "$SEM_OWNER" ]]; then
		options="$options`SemMenuOption start START`"
	fi

	if [[ "$REMOTE_USER" == "$SEM_OWNER" ]]; then
		if [[ "$current" != "pause" ]] && $SEM -p < $SEM_FILE | grep -q '^P '; then
			options="$options`SemMenuOption pause PAUSE`"
		fi

		if [[ "$current" != "resume" ]] && $SEM -p < $SEM_FILE | grep -q '^A '; then
			options="$options`SemMenuOption resume RESUME`"
		fi
	else
		case "$present" in
			P)
				if [[ "$current" != "pause" ]]; then
					options="$options`SemMenuOption pause PAUSE`"
				fi

				;;
			A)
				if [[ "$current" != "resume" ]]; then
					options="$options`SemMenuOption resume RESUME`"
				fi

				;;
		esac
	fi

	if [[ "$current" != "pay" ]]; then
		options="$options`SemMenuOption pay PAY`"
	fi

	if [[ "$current" != "transfer" ]]; then
		options="$options`SemMenuOption transfer TRANSFER`"
	fi

	if [[ "$current" != "buy" ]]; then
		options="$options`SemMenuOption buy BUY`"
	fi

	if [[ "$current" != "stop" ]]; then
		options="$options`SemMenuOption stop STOP`"
	fi

	cat <<!
<label id="sem_menu_container" class="$RB rel c15 cf0 menu">
	+
	<input type="checkbox" />
	<div id="sem_menu" class="abs vn f ah ak p c0 ts btn">
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
	if [[ "$REMOTE_USER" == "$SEM_OWNER" ]]; then
		cat $SEM_PATH/.owner $SEM_PATH/.members
	else
		echo $REMOTE_USER
	fi | IdOptions
}

sem_op() {
	cat $SEM_FILE > $ROOT/tmp/data.txt
	echo $@ >> $ROOT/tmp/data.txt

	if $SEM -q < $ROOT/tmp/data.txt; then
		rm $ROOT/tmp/data.txt
		DF_USER=$SEM_OWNER
		fappend $SEM_FILE echo $@
		see_other sem ?sem_id=$sem_id
	else
		rm $ROOT/tmp/data.txt
		Fatal 409 We can not have that
	fi
}

export sem_id
export SEM_SCRIPT

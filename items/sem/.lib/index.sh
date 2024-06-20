#!/bin/sh

SemMenuOption() {
	echo "<div><a href=\"/sem/$iid/$1/\">`_ "$1"`</a></div>"
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
	local current="$1"
	local options=""
	local present="`echo $PRESENT | awk '{ print $1 }'`"

	if im $OWNER; then
		if test "$current" != "start"; then
			options="$options`SemMenuOption start`"
		fi

		if test "$current" != "pause" && $SEM -p < $SEM_FILE | grep -q '^P '; then
			options="$options`SemMenuOption pause`"
		fi

		if test "$current" != "resume" && $SEM -p < $SEM_FILE | grep -q '^A '; then
			options="$options`SemMenuOption resume`"
		fi
	else
		case "$present" in
			P)
				if test "$current" != "pause"; then
					options="$options`SemMenuOption pause`"
				fi

				if test "$current" != "stop"; then
					options="$options`SemMenuOption stop`"
				fi

				;;
			A)
				if test "$current" != "resume"; then
					options="$options`SemMenuOption resume`"
				fi

				if test "$current" != "stop"; then
					options="$options`SemMenuOption stop`"
				fi

				;;
		esac
	fi

	if test "$current" != "pay"; then
		options="$options`SemMenuOption pay`"
	fi

	if test "$current" != "transfer"; then
		options="$options`SemMenuOption transfer`"
	fi

	if test "$current" != "buy"; then
		options="$options`SemMenuOption buy`"
	fi

	cat <<!
<label id="sem_menu_cont" class="$RB rel c15 cf0 menu">
	+
	<input type="checkbox" />
	<div class="abs v l p c0 ts btn ttc">
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
		cat $ITEM_PATH/.owner $ITEM_PATH/.members
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
		git -C $DOCUMENT_ROOT/sem/$iid add data.txt
		git -C $DOCUMENT_ROOT/sem/$iid commit -m "$@"
		if test $e_mode == 1; then
			_see_other e/sem?iid=$iid
		else
			_see_other .
		fi
	else
		rm $DOCUMENT_ROOT/tmp/data.txt
		Fatal 409 We can not have that
	fi
}

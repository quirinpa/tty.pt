SCHOOL_PATH="$ROOT/schools/$school_id"

if [[ -z "$school_id" ]] || [[ ! -d "$SCHOOL_PATH" ]]; then
	Fatal 404 School not found
fi

SCHOOL_OWNER="`cat $SCHOOL_PATH/.owner`"
SCHOOL_BTN="<a class=\"$RB\" href=\"/e/school?school_id=$school_id\">🏫</a>"

export school_id
export SCHOOL_BTN

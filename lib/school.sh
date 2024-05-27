SCHOOL_PATH="$DOCUMENT_ROOT/schools/$school_id"

if test -z "$school_id" || test ! -d "$SCHOOL_PATH"; then
	Fatal 404 School not found
fi

SCHOOL_OWNER="`cat $SCHOOL_PATH/.owner`"
SCHOOL_BTN="<a class=\"$RB\" href=\"/e/school?school_id=$school_id\">🏫</a>"
DF_USER="$SCHOOL_OWNER"

export school_id
export SCHOOL_BTN

LabeledIDEdit() {
	label=$1
	typ=$2
	typ_id=$3
	assoc=$4
	assoc_id=$5
	extra=$6
	cat <<!
<div class="c0 ps rs _s">
	<a class="tdn _s" href="/e/$typ?${typ}_id=$typ_id$extra">
		<small>$label</small>
		<span>$typ_id</span>
	</a>
	<a class="$RBXS cf0 c15" href="/e/$assoc-${typ}-associate?${assoc}_id=$assoc_id$extra">🖉</a>
</div>
!
}

invalid_s() {
	invalid_id $2 || test ! -d "$SCHOOL_PATH/$1/$2"
}

translate() {
	iconv -f utf-8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /_/g'
}

rm index.db
ls | sort -V | while read line; do
	id="`basename $line`"
	if test -h $id; then
		continue
	fi
	test -f $id/title || continue
	title="`cat $id/title`"
	link="`echo "$title" | translate`"
	ln -sf $id $link >/dev/null
	echo "-p'$id:$link 0 $title'"
done | xargs -I {} qhash {} index.db

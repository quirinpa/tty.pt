translate() {
	iconv -f utf-8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /_/g'
}

rm index.db || true
ls | sort -V | while read line; do
	test ! -h "$line" || continue
	line="`pwd`/$line"
	id="`basename "$line"`"
	test -f $id/title || continue
	title="`cat $id/title`"
	link="`echo "$title" | translate`"
	ln -sf $id $link >/dev/null
	echo "-p'$id:$link 0 $title'"
done | xargs -I {} qhash {} index.db

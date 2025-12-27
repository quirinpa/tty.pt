translate() {
	iconv -f utf-8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /_/g'
}

rm index.db || true
ls | sort -V | while read line; do
	id="$line"
	line="`pwd`/$line"
	test -f $id/title && \
		title="`cat $id/title`" || \
		title="$id"
	link="`echo "$title" | translate`"
	ln -sf $id $link >/dev/null
	qmap -p"$link:1 $title" index.db
done

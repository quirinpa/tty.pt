qdb=qdb
# qdb=/var/www/node_modules/@tty-pt/qdb/bin/qdb

translate() {
	iconv -f utf-8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /_/g'
}

tmpfile="`mktemp`"

rm index.db || true
ls | sort -V | while read line; do
	id="$line"
	line="`pwd`/$line"
	test -f $id/title && \
		title="`cat $id/title`" || \
		title="$id"
	link="`echo "$title" | translate`"
	ln -sf $id $link >/dev/null
	echo "-p'$link:1 $title'" >> $tmpfile
done

cat $tmpfile | xargs -I {} $qdb {} index.db:s
rm -f "$tmpfile"

translate() {
	iconv -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /_/g'
}

rm links.db >&2 || true
qhash -l index.db | while read id title; do
	target="`echo "$title" | translate`"
	ln -sf $id $target >/dev/null
	echo -p"$id:$target"
done | xargs -I {} qhash {} links.db >/dev/null

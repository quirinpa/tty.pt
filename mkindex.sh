index=index

rm index.db >&2 || true
ls | sort -V | while read line; do
	fname="`basename $line`"
	if test -h $fname; then
		rm $fname
		continue
	fi
	test -f $fname/title || continue
	echo -p"$fname:`cat $fname/title`"
done | xargs -I {} qhash {} index.db >&2
/var/www/mklinks.sh

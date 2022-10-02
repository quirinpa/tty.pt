for f in `ldd $1 | grep '/usr/' |
	grep -v ':' | awk '{print $7}'`;
do
	d="`dirname $f | sed 's#^/##'`"
	mkdir -p $d
	cp $f $d
done

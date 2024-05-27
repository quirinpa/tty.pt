#!/bin/sh
DOCUMENT_ROOT=/var/www

find $DOCUMENT_ROOT/htdocs/img -type f | while read line; do
	dname="`dirname $line`"
	bname="`basename $line`"
	cd $dname
	convert -resize x128 $bname small-$bname
	cd -
done

# find $DOCUMENT_ROOT/shops/loja_dos_sonhos/ -type f -name "images" | while read line; do
# 	echo $line:
# 	cat $line
# 	cat $line | while read line2; do
# 		echo `basename $line2` `dirname $line2`
# 	done

# done

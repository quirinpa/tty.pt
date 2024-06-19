#!/bin/sh

test ! -z "$DOCUMENT_ROOT" || DOCUMENT_ROOT="$PWD/"

install_extra_old() {
	echo install_extra $@
	line=$1
	target_path="`echo $line | grep -q "^/" && dirname $line || echo /usr/bin`"
	test -d "$DOCUMENT_ROOT$target_path" || mkdir -p $DOCUMENT_ROOT$target_path
	if test ! -f "$DOCUMENT_ROOT$line"; then
		# cp $line $DOCUMENT_ROOT$line
		echo cp $line $DOCUMENT_ROOT$line
	fi
}

install_extra() {
	# echo install_extra $@
        local line=$1
	local target_path="`echo $line | grep -q "^\/" && dirname $line || echo /usr/bin`"
	local target_file="$target_path/`basename $line`"
        test -d "$DOCUMENT_ROOT$target_path" || mkdir -p $DOCUMENT_ROOT$target_path
	local link="`readlink "$line" || true`"
	if echo "$link" | grep -q "^\/"; then
		install_extra "$link"
		ln -srf $DOCUMENT_ROOT$link $DOCUMENT_ROOT$target_file
		echo ln -srf $DOCUMENT_ROOT$link $DOCUMENT_ROOT$target_file
	elif test -z "$link"; then
		if diff $DOCUMENT_ROOT$target_file $line; then
			return
		fi
		if test -d "$line"; then
			ls $line | while read file; do
				install_extra "$line/$file"
			done
		else
			cp -r $line $DOCUMENT_ROOT/$target_file
			echo cp -r $line $DOCUMENT_ROOT$target_file
		fi
	else
		install_extra "$target_path/$link"
		ln -srf $DOCUMENT_ROOT$target_path/$link $DOCUMENT_ROOT$line
		echo ln -srf $DOCUMENT_ROOT$target_path/$link $DOCUMENT_ROOT$line 
	fi
}

ecp() {
	local target_path="`echo $2 | grep -q "^\/" && dirname $2 || echo /usr/bin`"
	mkdir -p $target_path 2>/dev/null || true
	echo cp $1 $2
	cp $1 $2
}

install_bin_old() {
	path=$1
	tmp=/tmp/$path
	ecp $path /tmp/$path
	ldd /tmp/$path | awk '{ print $7 }' | tail -n +4 | while read line; do
		install_extra "$line"
	done
	install_extra $path
	rm /tmp/$path
}

install_bin() {
        local path=$1
	local target_path="`echo $path | grep -q "^/" && dirname $path || echo /usr/bin`"
	target_file="$target_path/`basename $path`"
	# echo install_bin $@
	diff $path $DOCUMENT_ROOT$target_file && return 0 || true
        ldd $path | tail -n +1 | while read filename arrow ipath rest; do
		if test -z "$ipath"; then
			echo "$filename" | grep -q "^\/" \
				&& install_bin "$filename" \
				|| true
		       	continue
		fi
                install_bin "$ipath"
        done
	install_extra $path
}

if test $# -lt 1; then
	cat .install_bin | while read line; do install_bin "`which $line`"; done
	cat .install_extra | while read line; do install_extra "$line"; done
	exit
fi

install_bin "`which $1`"
echo $1 >> .install_bin

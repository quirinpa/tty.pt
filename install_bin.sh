#!/bin/sh

test ! -z "$DOCUMENT_ROOT" || DOCUMENT_ROOT="$PWD"

options=`getopt -o dfv: --long help -- "$@"`

dry=false
noforce=true
debug=0
target=

eval set -- "$options"

while true; do
	case "$1" in
		# actions
		-d) dry=true ;;
		-f) noforce=false ;;
		-v) debug=$2; shift ;;
		--help)
			cat <<!
usage: install_bin [OPTIONS...] [FILE]

DESCRIPTION:
    This is for installing things into tty.pt chroot.

OPTIONS:
  -d 				dry run
  -f				force
  -v LEVEL			set verbosity (0, 1 or 2)
!
			;;
		--) break ;;

		*) target=$1 ;;
	esac
	shift
done

shift $OPTIND
test $# -lt 1 || target="$1"

install_extra() {
	test $debug -lt 2 || echo install_extra $@
        local line=$1
	local target_psuffix="`echo $line | grep -q "^\/" && dirname $line || echo /usr/bin`"
	local target_path="$DOCUMENT_ROOT$target_psuffix"
	test ! -z "$line" || return 0
	local target_file="$target_path/`basename $line`"
        test -d "$target_path" || mkdir -p $target_path
	local link="`readlink "$line" || true`"
	if echo "$link" | grep -q "^\/"; then
		install_extra "$link"
		$dry || ln -srf $DOCUMENT_ROOT$link $target_file
		test $debug -lt 1 || echo ln -srf $DOCUMENT_ROOT$link $target_file
	elif test -z "$link"; then
		if $noforce && diff $target_file $line 2>/dev/null; then
			return
		fi
		if test -d "$line"; then
			ls $line | while read file; do
				install_extra "$line/$file"
			done
		else
			$dry || cp -r $line $target_file
			test $debug -lt 1 || echo cp -r $line $target_file
		fi
	else
		install_extra "$target_psuffix/$link"
		$dry || ln -srf $target_path/$link $DOCUMENT_ROOT$line
		test $debug -lt 1 || echo ln -srf $target_path/$link $DOCUMENT_ROOT$line
	fi
}

install_bin() {
        local path=$1
	local target_path="$DOCUMENT_ROOT`echo $path | grep -q "^\/" && dirname $path || echo /usr/bin`"
	test $debug -lt 2 || echo install_bin $path
	test ! -z "$1" || return 0
	target_file="$target_path/`basename $path`"
        ldd $path 2>/dev/null | tail -n +1 | while read filename arrow ipath rest; do
		if test -z "$ipath"; then
			echo "$filename" | grep -q "^\/" \
				&& install_bin "$filename" \
				|| true
		       	continue
		fi
                install_bin "$ipath"
        done
	$noforce && diff $path $target_file 2>/dev/null && return 0 || true
	install_extra $path
}

if test ! -z "$target"; then
	install_bin "`test -f "$target" && echo "$target" || which "$target"`"
	echo "$target" >> .install_bin
	exit
fi

cat .install_bin | while read line; do install_bin "`which $line`"; done
cat .install_extra | while read line; do install_extra "$line"; done

cmount() {
	local type=$1
	shift
	if ! mount | grep -q "on $DOCUMENT_ROOT/$type type"; then
		mkdir -p $DOCUMENT_ROOT/$type 2>/dev/null || true
		mount $@ $DOCUMENT_ROOT/$type
	fi
}

cmknod() {
	local mode=$1
	local type=$2
	local major=$3
	local minor=$4
	local path=$5
	test -$2 $DOCUMENT_ROOT/$path && return 0 || true
	mknod $DOCUMENT_ROOT/$path $type $major $minor $path
	chmod $mode $DOCUMENT_ROOT/$path
}

cmount dev --bind /dev
cmount sys --bind /sys
cmount proc --bind /proc
cmknod 666 c 5 2 dev/ptmx
cmount dev/pts -t devpts devpts

src_path="$DOCUMENT_ROOT/src"
if test -d $src_path; then
	cd $src_path
	ls | while read bin_proj; do
		cd $bin_proj || continue
		make
		make list | while read prog; do
			install_bin $prog
		done
		cd - >/dev/null
	done
fi

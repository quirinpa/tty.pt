#!/bin/sh

test ! -z "$DESTDIR" || DESTDIR="$PWD"
cd $DESTDIR

options=`getopt -o v: --long help -- "$@"`

debug=0
target=

uname="`uname`-`uname -v | awk '{print $1}'`"
depend=$DESTDIR/.depend-$uname

tmp=$DESTDIR/tmp
test -d $tmp || mkdir -p $tmp

eval set -- "$options"

rm -rf $tmp/umake-cp-tty-pt $tmp/umake-ln-tty-pt \
	$tmp/umake-mkdir-tty-pt 2>/dev/null || true

while true; do
	case "$1" in
		-v) debug=$2; shift ;;
		--help)
			cat <<!
usage: $0 [OPTIONS...] [FILE]

DESCRIPTION:
    This is for installing things into tty.pt chroot.

OPTIONS:
  -v LEVEL			set verbosity (0, 1 or 2)
  --help			this information
!
			exit
			;;
		--) break ;;

		*) target=$1 ;;
	esac
	shift
done

shift $OPTIND
test $# -lt 1 || target="$1"
touch $depend

link() {
	origin=$1
	target=$2
	grep -q "^$target:" $depend || echo $target: $origin >> $tmp/umake-ln-tty-pt
}

install_extra() {
	test $debug -lt 2 || echo install_extra $@
	test -e "$1" || return 0
        local line="`echo $1 | grep -q "^\/" && echo $1 | sed s/.// || echo $1`"
	local target_prefix="`dirname $line`"
	local target_path="$DESTDIR/$target_prefix"
	test ! -z "$line" || return 0
	local bname="`basename $line`"
	local target_file="$target_path/$bname"
	grep -q "^chroot_mkdir .* $target_prefix" $depend || echo $target_prefix >> $tmp/umake-mkdir-tty-pt
	local link="`readlink "$1" || true`"
	if echo "$link" | grep -q "^\/"; then
		install_extra "$link"
		link `echo $link | sed s/.//` $target_prefix/$bname
	elif test -z "$link"; then
		if test -d "$1"; then
			ls $1 | while read file; do
				install_extra "$1/$file"
			done
		else
			grep -q "^$target_prefix/$bname:" $depend \
				|| test "$1" = "$target_prefix/$bname" || \
				echo $target_prefix/$bname: $1 >> $tmp/umake-cp-tty-pt
		fi
	else
		install_extra "/$target_prefix/$link"
		link $target_prefix/$link $line
	fi
}

install_bin() {
        local path=$1
	local target_path="$DESTDIR`echo $path | grep -q "^\/" && dirname $path || echo /usr/bin`"
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
	install_extra $path
}

if test ! -z "$target"; then
	install_bin "`test -f "$target" && echo "$target" || which "$target"`"
	echo "$target" >> $DESTDIR/.install_bin
else
	cat $DESTDIR/.install_bin | while read line; do install_bin "`which $line`"; done
	cat $DESTDIR/.install_extra | while read line; do install_extra "$line"; done
fi

_how_to_make() {
	tr ':' ' ' | awk '{print $1}' | tr '\n' ' '
}

may_depend() {
	test "$1" = "y" && tee -a $depend || cat -
}

how_to_make() {
	local var_name=$1
	local dep=$2
	shift 2
	test -f $tmp/umake-$1-tty-pt || return 0
	local chroot_deps="`sort -u $tmp/umake-$1-tty-pt | may_depend $dep | _how_to_make $@`"
	rm $tmp/umake-$1-tty-pt
	test -z "$chroot_deps" || echo $var_name += $chroot_deps >> $depend
}

how_to_make chroot_cp y cp
how_to_make chroot_ln y ln
how_to_make chroot_mkdir n mkdir

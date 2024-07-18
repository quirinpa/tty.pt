#!/bin/sh

test ! -z "$DESTDIR" || DESTDIR="/var/www"
cd $DESTDIR

options=`getopt hv:C: $@`

debug=0
target=

uname="`uname`-`uname -v | awk '{print $1}'`"
depend=$DESTDIR/.depend-$uname
install_dir=$DESTDIR

tmp=$DESTDIR/tmp
test -d $tmp || mkdir -p $tmp

eval set -- "$options"

rm -rf $tmp/umake-cp-tty-pt $tmp/umake-ln-tty-pt \
	$tmp/umake-mkdir-tty-pt 2>/dev/null || true

while true; do
	case "$1" in
		-C) install_dir=$2; shift ;;
		-v) debug=$2; shift ;;
		-h)
			cat <<!
usage: $0 [OPTIONS...] [FILE]

DESCRIPTION:
    This is for installing things into tty.pt chroot.

OPTIONS:
  --help			this information
  -v LEVEL			set verbosity (0, 1 or 2)
  -C INSTALL_DIR		set INSTALL_DIR for where to find install and .depend
				files (useful for modules)
!
			exit
			;;
		--) break ;;

		*) target=$1 ;;
	esac
	shift
done

ilist=$install_dir/install

shift $OPTIND
test $# -lt 1 || target="$1"
touch $depend

link() {
	origin=$1
	target=$2
	grep -q "^$target:" $depend || echo $target: $origin >> $tmp/umake-ln-tty-pt
}

if test "`uname`" = "Linux"; then
	pldd() {
		ldd $1 2>/dev/null | tail -n +2 | while read filename arrow ipath rest; do
			if test -z "$ipath"; then
				echo "$filename" | grep -q "^\/" \
					&& echo "$filename" \
					|| true
				continue
			fi
			echo "$ipath"
		done
	}
else
	pldd() {
		ldd $1 2>/dev/null | tail -n +4 | awk '{print $7}'
	}
fi


rinstall() {
	test $debug -lt 2 || echo rinstall $@
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
		rinstall "$link"
		link `echo $link | sed s/.//` $target_prefix/$bname
	elif test -z "$link"; then
		if test -d "$1"; then
			test $debug -lt 2 || \
				echo install_dir $1
			ls $1 | while read file; do
				rinstall "$1/$file"
			done
		else
			if test -x "$1"; then
				test $debug -lt 2 || \
					echo install_bin $1
				pldd $1 | while read filename; do
					rinstall "$filename"
				done
			fi

			grep -q "^$target_prefix/$bname:" $depend \
				|| test "$1" = "$target_prefix/$bname" || \
				echo $target_prefix/$bname: $1 >> $tmp/umake-cp-tty-pt
		fi
	else
		rinstall "/$target_prefix/$link"
		link $target_prefix/$link $line
	fi
}

if test ! -z "$target"; then
	if ! grep -q "^$target\$" $ilist; then
		rinstall "`test -f "$target" && echo "$target" || which "$target" 2>/dev/null || echo "$target"`"
		echo "$target" >> $ilist
	fi
elif test -f $ilist; then
	cat $ilist | while read line; do
		rinstall "`test -f "$line" && echo "$line" || which "$line" 2>/dev/null || echo "$line"`"
	done
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

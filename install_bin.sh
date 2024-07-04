#!/bin/sh

test ! -z "$DOCUMENT_ROOT" || DOCUMENT_ROOT="$PWD"

options=`getopt -o mdfv: --long help -- "$@"`

dry=false
noforce=true
debug=0
target=
make=false

uname="`uname`-`uname -v | awk '{print $1}'`"
depend=$DOCUMENT_ROOT/.depend-$uname

tmp=$DOCUMENT_ROOT/tmp
test -d $tmp || mkdir -p $tmp

eval set -- "$options"

rm -rf $tmp/umake-cp-tty-pt $tmp/umake-ln-tty-pt \
	$tmp/umake-mkdir-tty-pt 2>/dev/null || true

while true; do
	case "$1" in
		# actions
		-d) dry=true ;;
		-f) noforce=false ;;
		-m) noforce=false; make=true ;;
		-v) debug=$2; shift ;;
		--help)
			cat <<!
usage: install_bin [OPTIONS...] [FILE]

DESCRIPTION:
    This is for installing things into tty.pt chroot.

OPTIONS:
  -d 				dry run
  -f				force
  -m				generate Makefile dependencies
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

test ! -z "$target" || rm -rf $depend 2>/dev/null || true

link() {
	origin=$1
	target=$2
	$make || $dry || ln -srf $DOCUMENT_ROOT/$origin $DOCUMENT_ROOT/$target
	if $make; then
		grep -q "^$target:" $depend || echo $target: $origin >> $tmp/umake-ln-tty-pt
	else
		test $debug -lt 1 || echo ln -srf $DOCUMENT_ROOT/$origin $DOCUMENT_ROOT/$target
	fi
}

install_extra() {
	test $debug -lt 2 || echo install_extra $@
	test -e "$1" || return 0
        local line="`echo $1 | grep -q "^\/" && echo $1 | sed s/.// || echo $1`"
	local target_prefix="`dirname $line`"
	local target_path="$DOCUMENT_ROOT/$target_prefix"
	test ! -z "$line" || return 0
	local bname="`basename $line`"
	local target_file="$target_path/$bname"
	if $make; then
		grep -q "^$target_prefix" $depend || echo $target_prefix >> $tmp/umake-mkdir-tty-pt
	else
		test -d "$target_path" || mkdir -p $target_path
	fi
	local link="`readlink "$1" || true`"
	if echo "$link" | grep -q "^\/"; then
		install_extra "$link"
		link `echo $link | sed s/.//` $target_prefix/$bname
	elif test -z "$link"; then
		if $noforce && diff $target_file $1 2>/dev/null; then
			return 0
		fi
		if test -d "$1"; then
			ls $1 | while read file; do
				install_extra "$1/$file"
			done
		else
			$make || $dry || cp -r $1 $target_file
			if $make; then
				grep -q "^$target_prefix/$bname:" $depend \
					|| test "$1" = "$target_prefix/$bname" || \
					echo $target_prefix/$bname: $1 >> $tmp/umake-cp-tty-pt
			else
				test $debug -lt 1 || echo cp -r $1 $target_file
			fi
		fi
	else
		install_extra "/$target_prefix/$link"
		link $target_prefix/$link $line
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
	echo "$target" >> $DOCUMENT_ROOT/.install_bin
else
	cat $DOCUMENT_ROOT/.install_bin | while read line; do install_bin "`which $line`"; done
	cat $DOCUMENT_ROOT/.install_extra | while read line; do install_extra "$line"; done
fi

src_path="$DOCUMENT_ROOT/src"
if test -d $src_path; then
	cd $src_path
	ls | while read bin_proj; do
		cd $bin_proj || continue
		make install
		make list | while read prog; do
			install_bin $prog
		done
		cd - >/dev/null
	done
fi

cd $DOCUMENT_ROOT
if $make; then
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
		local chroot_deps="`sort -u $tmp/umake-$1-tty-pt | may_depend $dep | _how_to_make $@`"
		rm $tmp/umake-$1-tty-pt
		test -z "$chroot_deps" || echo $var_name += $chroot_deps >> $depend
	}

	how_to_make chroot_cp y cp
	how_to_make chroot_ln y ln
	how_to_make chroot_mkdir n mkdir
fi

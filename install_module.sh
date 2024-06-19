#!/bin/sh

git_dir() {
	echo $1 | sed 's/.*\/\([^/.]*\).*$/\1/'
}

mkdir items 2>/dev/null || true
export DOCUMENT_ROOT="$PWD/"
cd items
git clone --recursive $1
src_path="`git_dir $1`/src"
if test -d $src_path; then
	cd $src_path
	ls | while read bin_proj; do
		cd $bin_proj
		make
		make list | while read prog; do
			$DOCUMENT_ROOT/install_bin.sh $prog
		done
		cd - >/dev/null
	done
fi
echo $1 >> $DOCUMENT_ROOT/.modules

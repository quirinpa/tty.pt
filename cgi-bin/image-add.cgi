#!/bin/ksh

. $ROOT/lib/common.sh

case "$REQUEST_METHOD" in
	POST)
		grep "^$REMOTE_USER$" $ROOT/.uploaders \
			|| Fatal 401 "You can not do that"

		USER_IMAGES_PATH=$ROOT/htdocs/img/$REMOTE_USER

		fmkdir $USER_IMAGES_PATH
		fbytes $ROOT/tmp/mpfd/file

		IMAGE_ID="`counter_inc $ROOT/public/img-counter`"
		ext="`file -i $ROOT/tmp/mpfd/file | awk '{print $2}' | tr '/' ' ' | awk '{print $2}'`"
		mv $ROOT/tmp/mpfd/file $USER_IMAGES_PATH/$IMAGE_ID.$ext
		see_other images

		;;
	GET)
		export _TITLE="`_ "Upload image"`"
		export _FILE="`_ File`"
		export _SUBMIT="`_ Submit`"

		Normal 200 image-add
		Cat image-add
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

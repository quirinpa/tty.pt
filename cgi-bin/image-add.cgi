#!/bin/ksh

. $ROOT/lib/common.sh

case "$REQUEST_METHOD" in
	POST)
		if grep "^$REMOTE_USER$" $ROOT/.uploaders; then
			USER_IMAGES_PATH=$ROOT/htdocs/img/$REMOTE_USER
			[[ -d "$USER_IMAGES_PATH" ]] || mkdir $USER_IMAGES_PATH
			IMAGE_ID="`counter_inc $ROOT/public/img-counter`"
			mv $ROOT/tmp/mpfd/file $USER_IMAGES_PATH/$IMAGE_ID.png

			see_other images
		else
			fatal 401
		fi

		;;
	GET)
		export _TITLE="`_ "Upload image"`"
		export _SUBMIT="`_ Submit`"

		page 200 image-add
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

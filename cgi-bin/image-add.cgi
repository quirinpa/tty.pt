#!/bin/ksh

. $ROOT/lib/common.sh

case "$REQUEST_METHOD" in
	POST)
		if grep "^$REMOTE_USER$" $ROOT/.uploaders; then
			USER_IMAGES_PATH=$ROOT/htdocs/img/$REMOTE_USER
			[[ -d "$USER_IMAGES_PATH" ]] || mkdir $USER_IMAGES_PATH
			IMAGE_ID="`counter_inc $ROOT/public/img-counter`"
			mv $ROOT/tmp/mpfd/file $USER_IMAGES_PATH/$IMAGE_ID.png

			echo 'Status: 303 See Other'
			echo "Location: /cgi-bin/images.cgi?lang=$lang"
			echo
		else
			echo 'Status: 401 Unauthorized'
			echo
		fi

		;;
	GET)
		echo 'Status: 200 OK'
		echo 'Content-Type: text/html; charset=utf-8'
		echo

		export _TITLE="`_ "Upload image"`"
		export _SUBMIT="`_ Submit`"

		export MENU="`Menu ./image-add.cgi?`"
		cat $ROOT/templates/image-add.html | envsubst
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
		;;
esac

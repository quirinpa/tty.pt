#!/bin/ksh

case "$REQUEST_METHOD" in
	POST)
		echo 'Status: 200 OK'
		echo 'Content-Type: text/plain; charset=utf-8'
		echo
		(
			read && read && read && read &&
			read line1 &&
			read line2 &&
			while read nextline ; do
				echo "$line1"
				line1="$line2"
				line2="$nextline"
			done
		) | sem
		;;
	*)
		echo "Status: 405 Method Not Allowed"
		echo
esac

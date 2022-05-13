urlencode() {
	while IFS= read -r c; do
		case $c in [a-zA-Z0-9.~_-]) printf "$c"; continue ;; esac
		printf "$c" | od -An -tx1 | tr ' ' % | tr -d '\n'
	done <<EOF
$(fold -w1)
EOF
	echo
}



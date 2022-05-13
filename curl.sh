. $ROOT/lib/more-common.sh

echo -n Enter username:\  1>&2
read username
echo -n Enter password:\  1>&2
stty -echo
read password
stty echo
echo

#auth="`echo "$username" | urlencode`:`echo "$password" | urlencode`"
auth="$username:$password"

curl "https://tty.pt/cgi-bin/cart.cgi" \
	-u $auth \
	-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
	-H 'Accept-Language: en-US,en;q=0.9,pt;q=0.8,es;q=0.7' \
	-H 'Cache-Control: no-cache' \
	-H 'Connection: keep-alive' \
	-H 'Content-Type: application/x-www-form-urlencoded' \
	-H 'Origin: https://tty.pt' \
	-H 'Pragma: no-cache' \
	-H 'Referer: https://tty.pt/cgi-bin/shop.cgi?lang=&shop_id=loja_dos_sonhos' \
	-H 'Sec-Fetch-Dest: document' \
	-H 'Sec-Fetch-Mode: navigate' \
	-H 'Sec-Fetch-Site: same-origin' \
	-H 'Sec-Fetch-User: ?1' \
	-H 'Upgrade-Insecure-Requests: 1' \
	-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.75 Safari/537.36' \
	-H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="100", "Google Chrome";v="100"' \
	-H 'sec-ch-ua-mobile: ?0' \
	-H 'sec-ch-ua-platform: "macOS"' \
	--data-raw 'product_id=3&lang=&shop_id=loja_dos_sonhos&quantity=-3&return=shop' \
	--compressed


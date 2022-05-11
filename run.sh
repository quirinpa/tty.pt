#!/bin/sh

REMOTE_USER=isabel
shop_id=loja_dos_sonhos
order_id=9

post() {
	echo "$1" | REQUEST_METHOD=POST ROOT=$ROOT REMOTE_USER=$REMOTE_USER $2
}

get() {
	QUERY_STRING=$1 REQUEST_METHOD=GET ROOT=$ROOT REMOTE_USER=$REMOTE_USER $2
}

query_string=lang=$lang\&shop_id=$shop_id\&order_id=$order_id

case "$1" in
	post-cart)
		query_string=$query_string\&product_id=produto0\&quantity=5
		post $query_string $ROOT/cgi-bin/cart.cgi
		;;
	post-checkout)
		query_string=$query_string\&action=checkout
		post $query_string $ROOT/cgi-bin/cart.cgi
		;;
	get-cart) get $query_string $ROOT/cgi-bin/cart.cgi ;;
	get-shop) get $query_string $ROOT/cgi-bin/shop.cgi ;;
	get-index) get $query_string $ROOT/cgi-bin/index.cgi ;;
	get-tty) get $query_string $ROOT/cgi-bin/tty.cgi ;;
	post-tty)
		query_string=$query_string\&cmd=quota
		post $query_string $ROOT/cgi-bin/tty.cgi
		;;
	post-order)
		post $query_string $ROOT/cgi-bin/order.cgi
		;;
	get-order) get $query_string $ROOT/cgi-bin/order.cgi ;;
esac

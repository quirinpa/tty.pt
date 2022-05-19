#!/bin/sh

export HTTP_ACCEPT_LANGUAGE="pt,en-US;q=0.9,en;q=0.8,es;q=0.7"
export CONTENT_TYPE=application/x-www-form-urlencoded
REMOTE_USER=quirinpa
shop_id=loja_dos_sonhos
order_id=9

post() {
	export SCRIPT_NAME=$2
	echo "$1" | REQUEST_METHOD=POST ROOT=$ROOT REMOTE_USER=$REMOTE_USER $ROOT/$2
}

get() {
	export SCRIPT_NAME=$2
	QUERY_STRING=$1 REQUEST_METHOD=GET ROOT=$ROOT REMOTE_USER=$REMOTE_USER $ROOT/$2
}

query_string=shop_id=$shop_id
#\&order_id=$order_id

case "$1" in
	post-login)
		username="quirinpa"
		post "" cgi-bin/login.cgi
		;;
	get-user)
		get "" cgi-bin/user.cgi
		;;
	get-register)
		get "" cgi-bin/register.cgi
		;;
	post-register)
		username=quirinpa6
		password=testy123
		email=quirinpa%40gmail.com
		post username=$username\&password=$password\&password2=$password\&email=$email cgi-bin/register.cgi
		;;
	get-poem)
		poem_id=1
		get "poem_id=$poem_id" cgi-bin/poem.cgi
		;;
	post-poem)
		poem_id=1
		comment="teste run.sh"
		post "poem_id=$poem_id&comment=$comment" cgi-bin/poem.cgi
		;;
	post-cart)
		query_string=$query_string\&product_id=produto0\&quantity=5
		post $query_string cgi-bin/cart.cgi
		;;
	post-checkout)
		query_string=$query_string\&action=checkout
		post $query_string cgi-bin/cart.cgi
		;;
	get-cart) get $query_string cgi-bin/cart.cgi ;;
	get-shop) get $query_string cgi-bin/shop.cgi ;;
	get-index) get $query_string cgi-bin/index.cgi ;;
	get-tty) get $query_string cgi-bin/tty.cgi ;;
	post-tty)
		query_string=$query_string\&cmd=whisper%20quirinpa%20teste
		post $query_string cgi-bin/tty.cgi
		;;
	post-order)
		post $query_string cgi-bin/order.cgi
		;;
	get-order) get $query_string cgi-bin/order.cgi ;;
	get-orders) get $query_string cgi-bin/orders.cgi ;;
	get-image-add) get $query_string cgi-bin/image-add.cgi ;;
	post-image-add)
		content="`cat $ROOT/image-add-content.txt`"
		export CONTENT_TYPE="multipart/form-data; boundary=----WebKitFormBoundaryHWi9UJlsyPtomSAF"
		post "$content" cgi-bin/image-add.cgi
		;;
	get-registration-confirm)
		username="quirinpa3"
		rcode="rbWOMF3G4K3Nr_8LDFg_3-eCBVI5GhJQbSK5a5m_yek"
		get username=$username\&rcode=$rcode cgi-bin/registration-confirm.cgi
		;;
esac
